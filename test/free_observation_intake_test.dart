import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/free_observation_intake.dart';
import 'package:modern_butlers_book/helpers/session_timeline.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

Evidence _row({
  required String id,
  required String templateId,
  required String observation,
  required String answer,
  EvidenceType type = EvidenceType.structuredAnswer,
}) {
  return Evidence(
    id: id,
    sessionId: 'session-1',
    applianceId: 'appliance-1',
    type: type,
    observation: observation,
    answer: answer,
    templateId: templateId,
    collectedAt: DateTime.utc(2026, 8, 17, 14),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1.0',
  );
}

void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;

  test('squeal keyword offers running-noise mark without diagnosing', () {
    final suggestions = suggestFreeObservationMarks(
      note: 'Heard a squeal while tumbling',
      templates: package.evidenceTemplates,
      recordedEvidence: const [],
      polarity: HeatPathPolarity.unknown,
    );
    expect(
      suggestions.any(
        (item) =>
            item.templateId == 'running-noise' &&
            item.suggestedAnswer == 'Squeal',
      ),
      isTrue,
    );
  });

  test('too-hot note does not offer excess-heat mark after no-heat polarity', () {
    final starter = _row(
      id: 'e0',
      templateId: problemStarterComplaintTemplateId,
      observation: 'What you noticed',
      answer: 'No heat',
    );
    final polarity = inferHeatPathPolarity(recordedEvidence: [starter]);
    expect(polarity, HeatPathPolarity.noHeat);

    final suggestions = suggestFreeObservationMarks(
      note: 'also too hot at the back',
      templates: package.evidenceTemplates,
      recordedEvidence: [starter],
      polarity: polarity,
    );
    expect(
      suggestions.any(
        (item) =>
            item.templateId == 'heat-observed' &&
            item.suggestedAnswer == 'Very hot',
      ),
      isFalse,
    );
  });

  test('free observation note does not change ranking standings', () {
    final starter = _row(
      id: 'e0',
      templateId: problemStarterComplaintTemplateId,
      observation: 'What you noticed',
      answer: 'No heat',
    );
    final note = _row(
      id: 'e1',
      templateId: freeObservationNoteTemplateId,
      observation: UserFacingCopy.freeObservationTitle,
      answer: 'also too hot at the back',
      type: EvidenceType.textObservation,
    );
    expect(isInterviewObservationEvidence(note), isFalse);
    expect(inferHeatPathPolarity(recordedEvidence: [starter, note]),
        HeatPathPolarity.noHeat);

    final before = evaluateFailureModeStandings(
      package: package,
      evidence: [starter],
    );
    final after = evaluateFailureModeStandings(
      package: package,
      evidence: [starter, note],
    );
    for (final id in before.keys) {
      expect(after[id]!.supportCount, before[id]!.supportCount);
      expect(after[id]!.excludeCount, before[id]!.excludeCount);
    }
  });

  test('timeline includes free notes', () {
    final items = sessionTimelineObservations([
      _row(
        id: 'e0',
        templateId: problemStarterComplaintTemplateId,
        observation: 'starter',
        answer: 'No heat',
      ),
      _row(
        id: 'e1',
        templateId: freeObservationNoteTemplateId,
        observation: UserFacingCopy.freeObservationTitle,
        answer: 'Lint piled at the vent',
        type: EvidenceType.textObservation,
      ),
    ]);
    expect(items, hasLength(2));
    expect(items[1].prompt, UserFacingCopy.freeObservationTitle);
    expect(items[1].answer, 'Lint piled at the vent');
  });

  testWidgets('question UI always shows free observation intake', (tester) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 15),
    );
    await openDryerSession(tester, dependencies, 'Free Note Household');

    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    expect(find.byKey(const Key('free-observation-intake')), findsOneWidget);
    expect(find.text(UserFacingCopy.freeObservationTitle), findsOneWidget);
  });

  testWidgets('saving a note does not answer the current question', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 15, 1),
    );
    await openDryerSession(
      tester,
      dependencies,
      'Free Note Keep Question',
      skipProblemStarter: false,
    );
    await confirmNoHeatStarter(tester);

    final currentPrompt = find.descendant(
      of: find.byKey(const Key('answer-choice-panel')),
      matching: find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('observation-prompt-');
      }),
    );
    expect(currentPrompt, findsOneWidget);
    final promptKey = tester.widget(currentPrompt).key! as ValueKey<String>;

    await tapVisible(tester, find.byKey(const Key('free-observation-field')));
    await tester.enterText(
      find.byKey(const Key('free-observation-field')),
      'also too hot at the back',
    );
    await tapVisible(tester, find.byKey(const Key('free-observation-save')));

    expect(find.byKey(Key(promptKey.value)), findsOneWidget);
    final sessionId =
        dependencies.repairSessionRepository.listAllSessions().single.id;
    final evidence = dependencies.buildDecisionContext(sessionId).evidence;
    expect(
      evidence.where(isFreeObservationNote).map((item) => item.answer),
      contains('also too hot at the back'),
    );
    expect(
      evidence.where((item) => item.templateId == promptKey.value.replaceFirst(
            'observation-prompt-',
            '',
          )),
      isEmpty,
    );
    expect(
      inferHeatPathPolarity(recordedEvidence: evidence),
      HeatPathPolarity.noHeat,
    );
    expect(
      find.byKey(const Key('free-observation-suggest-heat-observed_very-hot')),
      findsNothing,
    );
  });

  testWidgets('keyword chip records structured observation and keeps question', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 15, 2),
    );
    await openDryerSession(tester, dependencies, 'Free Note Squeal');

    final currentPrompt = find.descendant(
      of: find.byKey(const Key('answer-choice-panel')),
      matching: find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('observation-prompt-');
      }),
    );
    expect(currentPrompt, findsOneWidget);
    final promptKey = tester.widget(currentPrompt).key! as ValueKey<String>;
    expect(promptKey.value, isNot('observation-prompt-running-noise'));

    await tapVisible(tester, find.byKey(const Key('free-observation-field')));
    await tester.enterText(
      find.byKey(const Key('free-observation-field')),
      'Heard a squeal',
    );
    await tapVisible(tester, find.byKey(const Key('free-observation-save')));

    final chip = find.byKey(
      const Key('free-observation-suggest-running-noise_squeal'),
    );
    expect(chip, findsOneWidget);
    await tapVisible(tester, chip);

    expect(find.byKey(Key(promptKey.value)), findsOneWidget);
    final sessionId =
        dependencies.repairSessionRepository.listAllSessions().single.id;
    final evidence = dependencies.buildDecisionContext(sessionId).evidence;
    expect(
      evidence.any(
        (item) =>
            item.templateId == 'running-noise' && item.answer == 'Squeal',
      ),
      isTrue,
    );
    expect(evidence.where(isFreeObservationNote), hasLength(1));
  });
}
