import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/expert_mode.dart';
import 'package:modern_butlers_book/helpers/forbidden_guidance.dart';
import 'package:modern_butlers_book/helpers/guidance_display.dart';
import 'package:modern_butlers_book/helpers/inspect_steps.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/knowledge_factory/dishwasher_mvp_v01.dart';
import 'package:modern_butlers_book/knowledge_factory/washer_mvp_v01.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

/// P1-05: no supported dryer / washer / DW path emits forbidden how-to.
void main() {
  setUp(() {
    clearImportedClosePaths();
  });

  late KnowledgePackageRepository repo;

  setUp(() {
    repo = KnowledgePackageRepository();
  });

  void expectSafeHow(String text, {required String origin}) {
    expect(
      isAlwaysForbiddenInstruction(text),
      isFalse,
      reason: 'Forbidden how-to in $origin: $text',
    );
  }

  test('beginner and expert visible steps stay inside the safety filter', () {
    final dryer = repo.loadById('dryer-core')!;
    final washer = repo.loadById('washer-core') ?? buildWasherMvpPackage();
    final dw =
        repo.loadById('dishwasher-core') ?? buildDishwasherMvpPackage();

    for (final package in [dryer, washer, dw]) {
      for (final mode in package.failureModes) {
        final path = closePathForFailureMode(mode.id);
        expect(path, isNotNull, reason: 'missing close path ${mode.id}');
        for (final expertMode in [false, true]) {
          final shown = visibleSafeGuidanceSteps(
            path!,
            expertMode: expertMode,
          );
          for (final step in shown) {
            expectSafeHow(
              step,
              origin: '${package.id} ${mode.id} expert=$expertMode',
            );
            if (!expertMode) {
              expect(
                isBeginnerBlockedElectricalService(step),
                isFalse,
                reason:
                    'Beginner heater-panel/fuse how-to in ${mode.id}: $step',
              );
            }
            final displayed = guidanceForSafeStep(step);
            expectSafeHow(
              displayed.how,
              origin: '${mode.id} display how expert=$expertMode',
            );
          }
        }
      }
    }
  });

  test('observation HOW copy is not a live-meter or bypass procedure', () {
    final dryer = repo.loadById('dryer-core')!;
    final washer = repo.loadById('washer-core') ?? buildWasherMvpPackage();
    final dw =
        repo.loadById('dishwasher-core') ?? buildDishwasherMvpPackage();
    for (final package in [dryer, washer, dw]) {
      for (final template in package.evidenceTemplates) {
        final block = observationGuidanceForTemplate(template.id);
        if (block == null) {
          continue;
        }
        expectSafeHow(block.how, origin: 'observation ${template.id}');
        expectSafeHow(block.whenToStop, origin: 'stop ${template.id}');
      }
    }
  });

  test('inspect LOOK FOR is not a bypass or live-electrical how-to', () {
    for (final id in [
      'thermal-fuse-open',
      'heating-element-failed',
      'door-switch-failure',
      'gas-dryer-no-ignition-professional-only',
      'clogged-washer-drain-filter',
      'washer-door-not-latched',
      'clogged-dishwasher-filter',
      'dishwasher-door-not-latched',
    ]) {
      final path = closePathForFailureMode(id);
      if (path == null) {
        continue;
      }
      for (final step in inspectStepsForClosePath(closePath: path)) {
        expectSafeHow(step.lookFor, origin: 'inspect ${step.id}');
        expectSafeHow(step.safetyPreamble, origin: 'inspect preamble ${step.id}');
      }
    }
  });

  test('thermal-fuse beginner path escalates; panel is Expert Mode only', () {
    final path = closePathForFailureMode('thermal-fuse-open')!;
    final beginner = visibleSafeGuidanceSteps(path, expertMode: false);
    final expert = visibleSafeGuidanceSteps(path, expertMode: true);
    expect(
      beginner.join(' ').toLowerCase(),
      contains('technician'),
    );
    expect(
      beginner.join(' ').toLowerCase(),
      isNot(contains('heater service panel')),
    );
    expect(
      beginner.join(' ').toLowerCase(),
      contains('do not measure live'),
    );
    expect(expert.join(' ').toLowerCase(), contains('heater service panel'));
  });

  test('gas ignition path never teaches burner or valve repair', () {
    final path = closePathForFailureMode(
      'gas-dryer-no-ignition-professional-only',
    )!;
    for (final expertMode in [false, true]) {
      final shown = visibleSafeGuidanceSteps(path, expertMode: expertMode);
      expect(shown.join(' ').toLowerCase(), contains('gas technician'));
      for (final step in shown) {
        expect(isAlwaysForbiddenInstruction(step), isFalse);
      }
    }
  });

  test('gas-like odor evidence hard-stops', () {
    final stop = evaluateSafetyStop(
      evidence: [
        Evidence(
          id: 'e1',
          sessionId: 's1',
          applianceId: 'a1',
          type: EvidenceType.structuredAnswer,
          observation: 'What kind of smell?',
          answer: 'Gas-like odor',
          templateId: 'odor-type',
          collectedAt: DateTime.utc(2026, 8, 20),
          collectedInState: RepairSessionState.evidenceCollection,
          source: EvidenceSource.user,
          schemaVersion: '1.0',
        ),
      ],
    );
    expect(stop?.reason, 'Possible gas hazard');
  });
}
