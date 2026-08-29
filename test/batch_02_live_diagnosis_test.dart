import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/guidance_display.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/knowledge_factory/failure_mode_authoring_registry.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

void main() {
  final repo = KnowledgePackageRepository();
  final package = repo.loadById('dryer-core')!;
  final index = repo.authoringIndexFor('dryer-core')!;

  Evidence evidence({
    required String templateId,
    required String answer,
  }) {
    return Evidence(
      id: 'e-$templateId',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.structuredAnswer,
      observation: templateId,
      answer: answer,
      templateId: templateId,
      collectedAt: DateTime.utc(2026, 7, 25),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  group('Batch 02 live diagnosis', () {
    test('package ships 41 modes including Batch 02 slugs', () {
      expect(package.version, '1.4.2');
      expect(package.failureModes, hasLength(41));
      expect(
        package.failureModes.map((m) => m.id),
        containsAll([
          'gas-dryer-no-ignition-professional-only',
          'start-capacitor-or-start-assist-weak',
          'missing-leg-240v-supply',
          'outdoor-vent-pest-nest',
        ]),
      );
    });

    test('support-hit: gas dryer no ignition gains support from matching answers', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(templateId: 'gas-dryer-type', answer: 'Yes, gas dryer'),
          evidence(
            templateId: 'gas-ignition-observed',
            answer: 'No flame / no ignition',
          ),
          evidence(templateId: 'heat-observed', answer: 'No warmth'),
        ],
      );

      expect(standings['gas-dryer-no-ignition-professional-only']!.isSupported, isTrue);
      expect(standings['heating-element-failed']!.net, lessThan(3));
    });

    test('exclude-hit: electric dryer answer excludes gas ignition mode', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(templateId: 'gas-dryer-type', answer: 'Electric dryer'),
        ],
      );

      expect(
        standings['gas-dryer-no-ignition-professional-only']!.excludeCount,
        greaterThan(0),
      );
      expect(
        standings['gas-dryer-no-ignition-professional-only']!.isSupported,
        isFalse,
      );
    });

    test('support-hit: start capacitor weak from hum/struggle pattern', () {
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: [
          evidence(templateId: 'motor-audible', answer: 'Hum / struggle only'),
          evidence(templateId: 'dryer-response', answer: 'Hums but does not start'),
        ],
      );

      expect(standings['start-capacitor-or-start-assist-weak']!.isSupported, isTrue);
    });

    test('authoring index includes Batch 02 support templates', () {
      expect(
        index.supportTemplatesFor('missing-leg-240v-supply'),
        contains('breaker-tripped-check'),
      );
      expect(
        index.observationFamiliesFor('outdoor-vent-pest-nest'),
        isNotEmpty,
      );
    });

    test('gas mode close path blocks DIY gas repair guidance', () {
      final path = closePathForFailureMode('gas-dryer-no-ignition-professional-only');
      expect(path, isNotNull);
      expect(path!.allowResolvedWhenConfirmed, isFalse);
      expect(path.preferProfessionalWhenNotConfirmed, isTrue);
      final joined = path.safeGuidanceSteps.join(' ').toLowerCase();
      expect(joined, contains('do not attempt gas ignition repair'));
      expect(joined, isNot(contains('replace igniter')));
      expect(joined, isNot(contains('replace gas valve')));
    });

    test('gas and electrical modes stay within safe external-check boundaries', () {
      for (final modeId in [
        'gas-dryer-no-ignition-professional-only',
        'missing-leg-240v-supply',
        'loose-power-cord-connection-electric',
        'start-capacitor-or-start-assist-weak',
      ]) {
        final path = closePathForFailureMode(modeId);
        expect(path, isNotNull, reason: modeId);
        final joined = path!.safeGuidanceSteps.join(' ').toLowerCase();
        expect(
          joined.contains('do not measure live') ||
              joined.contains('no live') ||
              joined.contains('external') ||
              joined.contains('do not open') ||
              joined.contains('professional') ||
              joined.contains('gas technician') ||
              joined.contains('never open live'),
          isTrue,
          reason: modeId,
        );
      }
    });

    test('root cause registry resolves Batch 02 mode', () {
      final summary = FailureModeAuthoringRegistry.lookup(
        'outdoor-vent-pest-nest',
      );
      expect(summary, isNotNull);
      expect(summary!.rootCause, isNotEmpty);
      expect(summary.preventionActions, isNotEmpty);
    });

    test('observation guidance includes HOW for Batch 02 templates', () {
      expect(observationGuidanceForTemplate('gas-ignition-observed')?.how, isNotEmpty);
      expect(observationGuidanceForTemplate('breaker-tripped-check')?.how, isNotEmpty);
    });

    test('premature recommend still blocked before thresholds', () {
      expect(
        recommendPrimaryFailureModeId(
          standings: evaluateFailureModeStandings(
            package: package,
            evidence: [
              evidence(templateId: 'gas-dryer-type', answer: 'Yes, gas dryer'),
            ],
          ),
          evidence: [
            evidence(templateId: 'gas-dryer-type', answer: 'Yes, gas dryer'),
          ],
          templates: package.evidenceTemplates,
        ),
        isNull,
      );
    });

    test('hazard hard-stop still immediate', () {
      final stop = evaluateSafetyStop(
        evidence: [
          evidence(templateId: 'hazard-observation', answer: 'Yes'),
        ],
      );
      expect(stop?.reason, 'Possible fire or smoke hazard');
    });
  });
}
