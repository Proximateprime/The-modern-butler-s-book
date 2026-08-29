import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/easy_check_already_checked.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/suggest_next_observation.dart';
import 'package:modern_butlers_book/helpers/washer_easy_checks.dart';
import 'package:modern_butlers_book/knowledge_factory/washer_mvp_v01.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';

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
    collectedAt: DateTime.utc(2026, 8, 18),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1.0',
  );
}

void main() {
  final package = buildWasherMvpPackage();

  test('fill complaint asks taps, then inlet-screen look', () {
    final recorded = [
      evidence(templateId: washerComplaintTemplateId, answer: "Won't fill"),
    ];
    expect(
      suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
      )?.id,
      'washer-taps-open',
    );
    expect(
      suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: [
          ...recorded,
          evidence(templateId: 'washer-taps-open', answer: 'Yes'),
        ],
      )?.id,
      'washer-inlet-screens-look',
    );
    expect(
      washerEasyCheckOrderForEvidence([
        ...recorded,
        evidence(templateId: 'washer-taps-open', answer: 'No'),
      ]),
      ['washer-taps-open'],
    );
  });

  test('spin complaint asks water in drum before bunched load', () {
    expect(
      washerEasyCheckOrderForEvidence([
        evidence(templateId: washerComplaintTemplateId, answer: "Won't spin"),
      ]),
      ['washer-water-in-drum', 'washer-load-bunched'],
    );
  });

  test('drain complaint asks door click, then drain-filter look', () {
    var recorded = [
      evidence(templateId: washerComplaintTemplateId, answer: "Won't drain"),
    ];
    expect(
      suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
      )?.id,
      'washer-door-click',
    );

    recorded = [
      ...recorded,
      evidence(templateId: 'washer-door-click', answer: 'Yes'),
    ];
    expect(
      suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
      )?.id,
      'washer-drain-filter-access',
    );
  });

  test('drain close path puts door and filter look before opening the filter', () {
    final path = closePathForFailureMode(washerCloggedDrainFilterId)!;
    expect(closePathNeedsWasherEasyChecksFirst(path), isTrue);
    final ordered = orderWasherEasyChecksFirst(path.safeGuidanceSteps);
    expect(ordered.first.toLowerCase(), contains('click'));
    final unplugIndex = ordered.indexWhere(
      (step) => step.toLowerCase().contains('unplug the washer'),
    );
    final lookIndex = ordered.indexWhere(
      (step) => step.toLowerCase().contains('accessible drain filter'),
    );
    expect(lookIndex, lessThan(unplugIndex));
    expect(lookIndex, greaterThanOrEqualTo(0));

    final gated = guidanceStepsForWasherEasyGate(
      steps: ordered,
      easyChecksSatisfied: false,
    );
    expect(
      gated.join(' ').toLowerCase(),
      isNot(contains('unplug the washer')),
    );
    expect(
      gated.join(' ').toLowerCase(),
      isNot(contains('user-accessible filter')),
    );
    expect(gated.first.toLowerCase(), contains('click'));
  });

  test('door close path stays observation-only until latch checks are done', () {
    final path = closePathForFailureMode(washerDoorNotLatchedId)!;
    expect(closePathNeedsWasherEasyChecksFirst(path), isTrue);
    for (final step in path.safeGuidanceSteps) {
      expect(isInvasiveGuidanceStep(step), isFalse);
      expect(step.toLowerCase(), isNot(contains('multimeter')));
      expect(step.toLowerCase(), isNot(contains('live voltage')));
      expect(step.toLowerCase(), isNot(contains('gas')));
    }
  });

  test('Already checked on door and filter look unlocks the washer gate', () {
    expect(
      washerEasyChecksSatisfied(
        recordedEvidence: [
          evidence(
            templateId: 'washer-door-click',
            answer: alreadyCheckedEasyCheckAnswer,
          ),
          evidence(
            templateId: 'washer-drain-filter-access',
            answer: alreadyCheckedEasyCheckAnswer,
          ),
        ],
        steps: canonicalWasherEasyGuidanceSteps,
        completedIds: const [],
      ),
      isTrue,
    );
    final path = closePathForFailureMode(washerCloggedDrainFilterId)!;
    final ordered = orderWasherEasyChecksFirst(path.safeGuidanceSteps);
    expect(
      guidanceStepsForWasherEasyGate(
        steps: ordered,
        easyChecksSatisfied: false,
      ).join(' ').toLowerCase(),
      isNot(contains('unplug the washer')),
    );
    for (final id in washerEasyCheckTemplateIds) {
      final template =
          package.evidenceTemplates.firstWhere((item) => item.id == id);
      final choices = answerChoicesFor(template);
      expect(choices, contains(alreadyCheckedEasyCheckAnswer));
      expect(choices, contains('Not sure'));
    }
    expect(
      answerChoicesFor(
        package.evidenceTemplates.firstWhere(
          (item) => item.id == washerComplaintTemplateId,
        ),
      ),
      isNot(contains(alreadyCheckedEasyCheckAnswer)),
    );
  });

  test('fill and leak paths gate teardown after their own easy looks', () {
    expect(
      closePathNeedsWasherEasyChecksFirst(
        closePathForFailureMode(washerClosedTapsId)!,
      ),
      isTrue,
    );
    expect(
      closePathNeedsWasherEasyChecksFirst(
        closePathForFailureMode(washerLooseInletHoseId)!,
      ),
      isTrue,
    );
    final fill = orderWasherEasyChecksFirst(
      closePathForFailureMode(washerClosedTapsId)!.safeGuidanceSteps,
      failureModeId: washerClosedTapsId,
    );
    expect(fill.first.toLowerCase(), contains('tap'));
    expect(
      fill.first.toLowerCase(),
      isNot(contains('accessible drain filter')),
    );
    final gated = guidanceStepsForWasherEasyGate(
      steps: fill,
      easyChecksSatisfied: false,
    );
    expect(gated.join(' ').toLowerCase(), isNot(contains('unplug')));
  });
}
