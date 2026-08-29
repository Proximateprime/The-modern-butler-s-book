import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/easy_airflow_checks.dart';
import 'package:modern_butlers_book/helpers/easy_check_already_checked.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/guidance_display.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/suggest_next_observation.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';

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
  late final package = KnowledgePackageRepository().loadById('dryer-core')!;

  test('no-heat plus drum turns asks lint filter, then outside vent, then hose', () {
    var recorded = [
      evidence(templateId: 'heat-observed', answer: 'No warmth'),
      evidence(templateId: 'drum-turns', answer: 'Turns normally'),
    ];
    expect(
      suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
        energySource: ApplianceEnergySource.electric,
      )?.id,
      'lint-filter-condition',
    );

    recorded = [
      ...recorded,
      evidence(templateId: 'lint-filter-condition', answer: 'Not sure'),
    ];
    expect(
      suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
        energySource: ApplianceEnergySource.electric,
      )?.id,
      'exterior-airflow',
    );

    recorded = [
      ...recorded,
      evidence(templateId: 'exterior-airflow', answer: 'Not sure'),
    ];
    expect(
      suggestNextObservation(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
        energySource: ApplianceEnergySource.electric,
      )?.id,
      'vent-hose-condition',
    );
  });

  test('easy-check prompts say check airflow before opening the cabinet', () {
    final lint = package.evidenceTemplates.firstWhere(
      (item) => item.id == 'lint-filter-condition',
    );
    expect(
      lint.promptText,
      contains('Check airflow before opening the cabinet.'),
    );
    expect(lint.answerChoices, contains('Not sure'));

    final hood = package.evidenceTemplates.firstWhere(
      (item) => item.id == 'exterior-airflow',
    );
    expect(
      hood.promptText,
      contains('Check airflow before opening the cabinet.'),
    );
    expect(hood.promptText.toLowerCase(), contains('outside vent'));
  });

  test('invasive panel steps stay gated until easy checks are done or skipped', () {
    final path = closePathForFailureMode('thermal-fuse-open')!;
    final ordered = orderEasyAirflowGuidanceFirst(path.safeGuidanceSteps);
    expect(ordered.first.toLowerCase(), contains('lint filter'));
    expect(ordered[1].toLowerCase(), contains('vent hood'));
    expect(ordered[2].toLowerCase(), contains('vent hose'));
    expect(
      ordered.take(3).every((step) => !isInvasiveGuidanceStep(step)),
      isTrue,
    );

    final gated = guidanceStepsForEasyAirflowGate(
      steps: ordered,
      easyChecksSatisfied: false,
    );
    expect(gated.any(isInvasiveGuidanceStep), isFalse);
    expect(gated, hasLength(3));
    expect(
      gated.any((step) => step.toLowerCase().contains('service panel')),
      isFalse,
    );
    expect(
      gated.any((step) => step.toLowerCase().contains('unplug')),
      isFalse,
    );

    final skipped = [
      for (var i = 0; i < ordered.length; i++)
        if (isEasyAirflowCheckStep(ordered[i]))
          guidanceStepId(i, ordered[i]),
    ];
    expect(
      easyAirflowChecksSatisfied(
        recordedEvidence: const [],
        steps: ordered,
        completedIds: skipped,
      ),
      isTrue,
    );
    final unlocked = guidanceStepsForEasyAirflowGate(
      steps: ordered,
      easyChecksSatisfied: true,
    );
    expect(
      unlocked.any((step) => step.toLowerCase().contains('technician')),
      isTrue,
    );
    expect(
      unlocked.any((step) => step.toLowerCase().contains('service panel')),
      isFalse,
    );
    expect(
      path.expertOkSteps.join(' ').toLowerCase(),
      contains('heater service panel'),
    );
  });

  test('answering the three easy questions also unlocks invasive steps', () {
    final recorded = [
      evidence(templateId: 'lint-filter-condition', answer: 'Not sure'),
      evidence(templateId: 'exterior-airflow', answer: 'Not sure'),
      evidence(templateId: 'vent-hose-condition', answer: 'Not sure'),
    ];
    expect(
      easyAirflowChecksSatisfied(
        recordedEvidence: recorded,
        steps: canonicalEasyAirflowGuidanceSteps,
        completedIds: const [],
      ),
      isTrue,
    );
    expect(
      inferHeatPathPolarity(recordedEvidence: [
        evidence(templateId: 'heat-observed', answer: 'No warmth'),
      ]),
      HeatPathPolarity.noHeat,
    );
  });

  test('no-heat path still verifies vent first when conclusion names a part', () {
    const rankedPart = FailureModeClosePath(
      failureModeId: 'air-fluff-cycle-selected',
      verificationAsk: 'Is air-only selected?',
      verificationWhy: 'Settings check.',
      safeGuidanceSteps: [
        'Open the heater service panel.',
        'Replace the part.',
      ],
      allowResolvedWhenConfirmed: true,
      preferProfessionalWhenNotConfirmed: true,
    );
    expect(closePathNeedsEasyAirflowFirst(rankedPart), isFalse);
    expect(
      closePathNeedsEasyAirflowFirst(
        rankedPart,
        recordedEvidence: [
          evidence(templateId: 'heat-observed', answer: 'No warmth'),
        ],
      ),
      isTrue,
    );

    final ordered = orderEasyAirflowGuidanceFirst(
      rankedPart.safeGuidanceSteps,
    );
    expect(ordered.first.toLowerCase(), contains('lint filter'));
    expect(ordered[1].toLowerCase(), contains('vent hood'));
    expect(ordered[2].toLowerCase(), contains('vent hose'));
    final gated = guidanceStepsForEasyAirflowGate(
      steps: ordered,
      easyChecksSatisfied: false,
    );
    expect(gated.any(isInvasiveGuidanceStep), isFalse);
    expect(
      gated.any((step) => step.toLowerCase().contains('service panel')),
      isFalse,
    );
  });

  test('long-dry and overheat starters also prioritize easy airflow checks', () {
    expect(
      shouldPrioritizeEasyAirflowChecks(
        recordedEvidence: const [],
        starterMatchedSymptomIds: {'long-dry-time'},
      ),
      isTrue,
    );
    expect(
      shouldPrioritizeEasyAirflowChecks(
        recordedEvidence: const [],
        starterMatchedSymptomIds: {'dryer-very-hot'},
      ),
      isTrue,
    );
    expect(
      starterInterviewTemplate(
        templates: package.evidenceTemplates,
        recordedEvidence: const [],
        firstTemplateId: 'clothes-feel-after-cycle',
        starterMatchedSymptomIds: {'long-dry-time'},
      )?.id,
      'lint-filter-condition',
    );
  });

  test('won\'t-start door path is not easy-airflow-first', () {
    final path = closePathForFailureMode('door-switch-failure')!;
    expect(closePathNeedsEasyAirflowFirst(path), isFalse);
    expect(
      closePathNeedsEasyAirflowFirst(
        path,
        recordedEvidence: [
          evidence(templateId: 'dryer-response', answer: 'Nothing happens'),
        ],
      ),
      isFalse,
    );
    expect(
      shouldPrioritizeEasyAirflowChecks(
        recordedEvidence: [
          evidence(templateId: 'dryer-response', answer: 'Nothing happens'),
        ],
        starterMatchedSymptomIds: {'will-not-start'},
      ),
      isFalse,
    );
  });

  test('Already checked answers unlock the easy-airflow gate without ranking', () {
    final recorded = [
      evidence(
        templateId: 'lint-filter-condition',
        answer: alreadyCheckedEasyCheckAnswer,
      ),
      evidence(
        templateId: 'exterior-airflow',
        answer: alreadyCheckedEasyCheckAnswer,
      ),
      evidence(
        templateId: 'vent-hose-condition',
        answer: alreadyCheckedEasyCheckAnswer,
      ),
    ];
    expect(
      easyAirflowChecksSatisfied(
        recordedEvidence: recorded,
        steps: canonicalEasyAirflowGuidanceSteps,
        completedIds: const [],
      ),
      isTrue,
    );
    expect(
      guidanceStepsForEasyAirflowGate(
        steps: [
          ...canonicalEasyAirflowGuidanceSteps,
          'Open the heater service panel.',
        ],
        easyChecksSatisfied: easyAirflowChecksSatisfied(
          recordedEvidence: const [],
          steps: canonicalEasyAirflowGuidanceSteps,
          completedIds: const [],
        ),
      ).any((step) => step.contains('service panel')),
      isFalse,
    );

    final standings = evaluateFailureModeStandings(
      package: package,
      evidence: [
        evidence(
          templateId: 'lint-filter-condition',
          answer: alreadyCheckedEasyCheckAnswer,
        ),
      ],
    );
    expect(standings['clogged-lint-pathway']!.isSupported, isFalse);

    for (final id in easyAirflowCheckTemplateIds) {
      final template =
          package.evidenceTemplates.firstWhere((item) => item.id == id);
      final choices = answerChoicesFor(template);
      expect(choices, contains(alreadyCheckedEasyCheckAnswer));
      expect(choices, contains('Not sure'));
      expect(
        choices.indexOf(alreadyCheckedEasyCheckAnswer),
        lessThan(choices.indexOf('Not sure')),
      );
    }
    expect(
      answerChoicesFor(
        package.evidenceTemplates.firstWhere(
          (item) => item.id == 'dryer-response',
        ),
      ),
      isNot(contains(alreadyCheckedEasyCheckAnswer)),
    );
  });

  test('fuse and element easy-check titles are not teardown', () {
    KnowledgePackageRepository().loadById('dryer-core');
    for (final id in [
      'thermal-fuse-open',
      'heating-element-failed',
      'high-limit-thermostat-open',
    ]) {
      final path = closePathForFailureMode(id)!;
      expect(
        path.safeGuidanceSteps.first,
        contains('Check airflow before opening the cabinet.'),
      );
      expect(
        path.safeGuidanceSteps.take(3).join(' ').toLowerCase(),
        isNot(contains('service panel')),
      );
      final title = guidanceForSafeStep(path.safeGuidanceSteps.first);
      expect(title.what.toLowerCase(), contains('lint filter'));
      expect(title.what.toLowerCase(), isNot(contains('replace')));
      expect(title.what.toLowerCase(), isNot(contains('heater service')));
    }
  });
}
