import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets('developer UI completes the observation happy path', (
    tester,
  ) async {
    final fixedTime = DateTime.utc(2026, 7, 22, 12);
    final dependencies = AppDependencies(clock: () => fixedTime);

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: dependencies));

    expect(find.text(UserFacingCopy.createHouseholdAction), findsOneWidget);
    await tester.tap(find.byKey(const Key('create-household-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('household-name-field')),
      'Developer Household',
    );
    await tester.tap(find.byKey(const Key('confirm-household-button')));
    await tester.pumpAndSettle();

    expect(find.text('Developer Household'), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-dryer-button')));
    await tester.pumpAndSettle();
    await confirmAddAppliance(tester);

    expect(find.text('Laundry Room Dryer'), findsOneWidget);
    await tester.tap(find.text('Laundry Room Dryer'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appliance-detail-name')), findsOneWidget);
    await startRepairFromDetail(tester);
    await dismissProblemStarterIfPresent(tester);

    expect(find.text('Now: Answering questions'), findsOneWidget);
    expect(find.byKey(const Key('package-summary-tile')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('package-summary-tile')));
    expect(find.byKey(const Key('package-summary')), findsOneWidget);
    expect(find.text('Name: Dryer Knowledge Package'), findsOneWidget);
    expect(find.text('Version: 1.4.2'), findsOneWidget);
    expect(find.text('Category: dryer'), findsOneWidget);
    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    expect(find.text('Failure modes: ${package.failureModes.length}'), findsOneWidget);
    expect(find.text('Observation prompts: ${package.evidenceTemplates.length}'), findsOneWidget);
    expect(find.byKey(const Key('failure-modes-tile')), findsOneWidget);
    expect(find.text('Browse failure modes'), findsOneWidget);
    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    expect(find.text('Current question'), findsOneWidget);
    expect(find.text('No clues yet'), findsWidgets);
    expect(find.text('1 clue'), findsNothing);

    await selectObservation(tester, 'heat-observed');
    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    expect(find.text('No warmth'), findsOneWidget);
    expect(find.text('Yes'), findsNothing);
    await tapVisible(tester, find.byKey(const Key('answer-choice-no-warmth')));

    await expandEvidenceHistory(tester);
    expect(
      find.text('Is there any warmth after the dryer has run briefly?'),
      findsWidgets,
    );
    expect(find.textContaining('Answer: No warmth'), findsOneWidget);
    expect(find.text('1 clue'), findsWidgets);

    await selectObservation(tester, 'cycle-heat-setting');
    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-yes-heat-cycle')),
    );
    await selectObservation(tester, 'recent-overheat');
    await tapVisible(tester, find.byKey(const Key('answer-choice-no')));
    await selectObservation(tester, 'exterior-airflow');
    await tapInspectOrAnswerChoice(tester, 'normal');
    expect(find.text('4 clues'), findsWidgets);

    await selectFailureMode(tester, 'clogged-lint-pathway');
    await reachClosePathVerificationIfPresent(tester);

    expect(find.byKey(const Key('verification-card')), findsOneWidget);
    expect(find.byKey(const Key('verification-title')), findsOneWidget);
    expect(find.byKey(const Key('close-answer-choice-panel')), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));

    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await saveSessionOutcome(tester);

    expect(find.byKey(const Key('recent-activity-title')), findsOneWidget);
    expect(find.text('Fixed'), findsWidgets);

    final closedSessionId =
        dependencies.repairSessionRepository.listAllOutcomes().single.sessionId;
    await tapVisible(
      tester,
      find.byKey(Key('recent-outcome-$closedSessionId')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session-outcome-summary')), findsOneWidget);
    expect(find.text('Status: Fixed'), findsOneWidget);
    expect(find.textContaining('What failed:'), findsOneWidget);
    expect(
      find.textContaining(RegExp('lint', caseSensitive: false)),
      findsWidgets,
    );
    expect(find.byKey(const Key('outcome-evidence-count')), findsOneWidget);
    expect(find.text('Evidence recorded: 5'), findsOneWidget);
  });
}
