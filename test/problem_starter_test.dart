import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  group('resolveDryerStarter', () {
    test('unions two chip symptoms', () {
      final result = resolveDryerStarter(
        selectedSymptomIds: {'no-heat', 'long-dry-time'},
      );
      expect(result.matchedSymptomIds, containsAll(['no-heat', 'long-dry-time']));
      expect(result.labels, containsAll(['No heat', 'Long dry time']));
    });

    test('maps no-heat free text to no-heat symptom and discriminator first question', () {
      final result = resolveDryerStarter(
        selectedSymptomIds: const {},
        freeText: 'Dryer has no heat',
      );
      expect(result.matchedSymptomIds, ['no-heat']);
      expect(result.firstTemplateId, 'cycle-heat-setting');
      expect(result.labels, ['No heat']);
    });

    test('maps too-hot chip to dryer-very-hot, not no-heat', () {
      final result = resolveDryerStarter(
        selectedSymptomIds: {'dryer-very-hot'},
      );
      expect(result.matchedSymptomIds, ['dryer-very-hot']);
      expect(result.firstTemplateId, 'lint-filter-condition');
      expect(result.labels, isNot(contains('No heat')));
    });

    test('Noise or smell chip maps to unusual-noise family, not hazard', () {
      final result = resolveDryerStarter(
        selectedSymptomIds: {dryerStarterNoiseOrSmellId},
      );
      expect(result.matchedSymptomIds, ['squealing-or-thumping']);
      expect(result.isHazard, isFalse);
      expect(result.firstTemplateId, 'running-noise');
    });

    test('primary picker is the eight plain-language choices', () {
      expect(dryerStarterEntryChoiceIds, [
        'no-heat',
        'long-dry-time',
        'will-not-start',
        'motor-runs-drum-still',
        'dryer-very-hot',
        dryerStarterNoiseOrSmellId,
        'hazard-signs',
        dryerStarterOtherDescribeId,
      ]);
      expect(dryerStarterEntryChipLabel('no-heat'), 'No heat');
      expect(dryerStarterEntryChipLabel('long-dry-time'), 'Takes too long to dry');
      expect(dryerStarterEntryChipLabel('will-not-start'), "Won't start");
      expect(
        dryerStarterEntryChipLabel('motor-runs-drum-still'),
        "Drum doesn't turn",
      );
      expect(dryerStarterEntryChipLabel('dryer-very-hot'), 'Too hot or overheating');
      expect(dryerStarterEntryChipLabel(dryerStarterNoiseOrSmellId), 'Unusual noise');
      expect(dryerStarterEntryChipLabel('hazard-signs'), 'Burning smell / smoke');
      expect(dryerStarterEntryChipLabel(dryerStarterOtherDescribeId), 'Other');
    });

    test('maps won’t-start chip and synonyms', () {
      final fromChip = resolveDryerStarter(
        selectedSymptomIds: {'will-not-start'},
      );
      expect(fromChip.firstTemplateId, 'dryer-response');

      final fromText = resolveDryerStarter(
        selectedSymptomIds: const {},
        freeText: "won't start at all",
      );
      expect(fromText.matchedSymptomIds, ['will-not-start']);
      expect(fromText.firstTemplateId, 'dryer-response');
    });

    test('hazard keywords outrank other matches', () {
      final result = resolveDryerStarter(
        selectedSymptomIds: {'no-heat'},
        freeText: 'also smell smoke',
      );
      expect(result.matchedSymptomIds.first, 'hazard-signs');
      expect(result.isHazard, isTrue);
    });

    test('unmatched free text alone does not invent a path', () {
      final result = resolveDryerStarter(
        selectedSymptomIds: const {},
        freeText: 'something weird xyz',
      );
      expect(result.hasMatch, isFalse);
      expect(result.unmatchedFreeText, isTrue);
    });

    test('hazard complaint answer always includes a hard-stop keyword', () {
      final resolution = resolveDryerStarter(
        selectedSymptomIds: {'hazard-signs'},
      );
      final answer = buildStarterComplaintAnswer(resolution: resolution);
      expect(answer.toLowerCase(), contains('smoke'));
    });

    test('No heat vs Too hot starter answers still diverge polarity', () {
      Evidence complaint(String answer) {
        return Evidence(
          id: 'e-starter',
          sessionId: 'session-1',
          applianceId: 'appliance-1',
          type: EvidenceType.textObservation,
          observation: "What's going on with the dryer?",
          answer: answer,
          templateId: problemStarterComplaintTemplateId,
          collectedAt: DateTime.utc(2026, 8, 16),
          collectedInState: RepairSessionState.evidenceCollection,
          source: EvidenceSource.user,
          schemaVersion: '1.0',
        );
      }

      final noHeat = resolveDryerStarter(selectedSymptomIds: {'no-heat'});
      expect(
        inferHeatPathPolarity(
          recordedEvidence: [
            complaint(buildStarterComplaintAnswer(resolution: noHeat)),
          ],
          starterMatchedSymptomIds: noHeat.matchedSymptomIds.toSet(),
        ),
        HeatPathPolarity.noHeat,
      );

      final tooHot = resolveDryerStarter(
        selectedSymptomIds: {'dryer-very-hot'},
      );
      expect(
        inferHeatPathPolarity(
          recordedEvidence: [
            complaint(buildStarterComplaintAnswer(resolution: tooHot)),
          ],
          starterMatchedSymptomIds: tooHot.matchedSymptomIds.toSet(),
        ),
        HeatPathPolarity.excessHeat,
      );
    });
  });

  testWidgets('no-heat chip seeds evidence and opens discriminator, not warmth re-ask', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 7, 24, 17),
    );
    await openDryerSessionWithoutStarterSkip(
      tester,
      dependencies,
      'Starter No Heat',
    );

    expect(find.byKey(const Key('problem-starter-title')), findsOneWidget);
    expect(find.text("What's going on?"), findsOneWidget);
    expect(
      find.byKey(const Key('problem-starter-helper')),
      findsOneWidget,
    );
    expect(
      find.text('Describe what you notice — not what you think is broken'),
      findsWidgets,
    );
    expect(find.text('No heat'), findsWidgets);
    expect(find.text('Takes too long to dry'), findsOneWidget);
    expect(find.text("Won't start"), findsOneWidget);
    expect(find.text("Drum doesn't turn"), findsOneWidget);
    expect(find.text('Too hot or overheating'), findsOneWidget);
    expect(find.text('Unusual noise'), findsOneWidget);
    expect(find.text('Burning smell / smoke'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.byKey(const Key('starter-chip-hazard-signs')), findsOneWidget);
    expect(find.byKey(const Key('starter-chip-long-dry-time')), findsOneWidget);
    await tester.tap(find.byKey(const Key('starter-chip-no-heat')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('problem-starter-interpretation')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('problem-starter-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('problem-starter-panel')), findsNothing);
    expect(find.text('Evidence count: 1'), findsOneWidget);
    expect(
      find.byKey(const Key('observation-prompt-heat-observed')),
      findsNothing,
    );
    final discriminators = [
      'gas-dryer-type',
      'exterior-airflow',
      'dry-time-change',
      'recent-overheat',
      'cycle-heat-setting',
      'clothes-feel-after-cycle',
      'drum-turns',
    ];
  var foundDiscriminator = false;
  for (final id in discriminators) {
    if (tester
        .widgetList(
          find.descendant(
            of: find.byKey(const Key('answer-choice-panel')),
            matching: find.byKey(Key('observation-prompt-$id')),
          ),
        )
        .isNotEmpty) {
      foundDiscriminator = true;
      break;
    }
  }
  expect(foundDiscriminator, isTrue);
  });

  testWidgets('Other/describe maps won’t-start and opens dryer-response', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 7, 24, 17, 10),
    );
    await openDryerSessionWithoutStarterSkip(
      tester,
      dependencies,
      'Starter Other Describe',
    );

    await tester.tap(find.byKey(const Key('starter-chip-other-describe')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('problem-starter-freetext')),
      "won't start",
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Will not start'), findsOneWidget);

    await tester.tap(find.byKey(const Key('problem-starter-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Evidence count: 1'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('answer-choice-panel')),
        matching: find.byKey(const Key('observation-prompt-dryer-response')),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'won\'t-start after dryer-response offers door click and Already checked',
    (tester) async {
      final dependencies = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 20, 18),
      );
      await openDryerSessionWithoutStarterSkip(
        tester,
        dependencies,
        'Starter Wont Start Easy',
      );

      await tester.tap(find.byKey(const Key('starter-chip-will-not-start')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem-starter-confirm')));
      await tester.pumpAndSettle();

      await answerObservation(tester, 'dryer-response', 'nothing-happens');

      expect(
        find.descendant(
          of: find.byKey(const Key('answer-choice-panel')),
          matching: find.byKey(const Key('observation-prompt-door-closed-firmly')),
        ),
        findsOneWidget,
      );
      expect(find.text('Already checked'), findsOneWidget);
      expect(
        find.byKey(const Key('answer-choice-already-checked')),
        findsOneWidget,
      );
    },
  );

  testWidgets('unmatched Other/describe continues with limited guidance', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 7, 24, 17, 20),
    );
    await openDryerSessionWithoutStarterSkip(
      tester,
      dependencies,
      'Starter Clarify',
    );

    await tester.tap(find.byKey(const Key('starter-chip-other-describe')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('problem-starter-freetext')),
      'something weird xyz',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('problem-starter-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('problem-starter-panel')), findsNothing);
    expect(find.byKey(const Key('starter-limited-guidance')), findsOneWidget);
    expect(
      find.text(UserFacingCopy.unmatchedStarterGuidance),
      findsOneWidget,
    );

    final session = dependencies.repairSessionRepository.listAllSessions().single;
    final evidence =
        dependencies.repairSessionRepository.evidenceForSession(session.id);
    expect(
      evidence.any(
        (item) =>
            item.templateId == problemStarterComplaintTemplateId &&
            (item.answer ?? '').contains('something weird xyz'),
      ),
      isTrue,
    );
  });

  testWidgets('burning/smoke via Other still hard-stops immediately', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 7, 24, 17, 30),
    );
    await openDryerSessionWithoutStarterSkip(
      tester,
      dependencies,
      'Starter Hazard',
    );

    await tester.tap(find.byKey(const Key('starter-chip-other-describe')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('problem-starter-freetext')),
      'burning smell and smoke',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('problem-starter-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
    expect(find.byKey(const Key('answer-choice-panel')), findsNothing);
    expect(find.byKey(const Key('end-session-button')), findsOneWidget);
  });

  testWidgets('Too hot chip opens excess-heat discriminator, not warmth re-ask', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 7, 24, 17, 40),
    );
    await openDryerSessionWithoutStarterSkip(
      tester,
      dependencies,
      'Starter Too Hot',
    );

    await tester.tap(find.byKey(const Key('starter-chip-dryer-very-hot')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('problem-starter-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('problem-starter-panel')), findsNothing);
    expect(
      find.byKey(const Key('observation-prompt-heat-observed')),
      findsNothing,
    );
    final lintInterview = find.descendant(
      of: find.byKey(const Key('answer-choice-panel')),
      matching: find.byKey(const Key('observation-prompt-lint-filter-condition')),
    );
    final lintInspect = find.byKey(
      const Key('inspect-step-card-inspect-lint-filter'),
    );
    expect(
      lintInterview.evaluate().isNotEmpty || lintInspect.evaluate().isNotEmpty,
      isTrue,
      reason: 'Too hot should open lint-filter look (interview or inspect card)',
    );
  });
}

Future<void> openDryerSessionWithoutStarterSkip(
  WidgetTester tester,
  AppDependencies dependencies,
  String householdName,
) async {
  await prepareTallSurface(tester);
  await tester.pumpWidget(ModernButlerApp(dependencies: dependencies));
  await tester.tap(find.byKey(const Key('create-household-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('household-name-field')),
    householdName,
  );
  await tester.tap(find.byKey(const Key('confirm-household-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('add-dryer-button')));
  await tester.pumpAndSettle();
  await confirmAddAppliance(tester);
  await tester.tap(find.text('Laundry Room Dryer'));
  await tester.pumpAndSettle();
  await startRepairFromDetail(tester);
}
