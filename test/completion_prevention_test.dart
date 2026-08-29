import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets('Fixed path reaches Done with prevention, then home history', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 19));
    await openDryerSession(tester, deps, 'Completion House');

    await selectObservation(tester, 'clothes-remain-damp');
    await tapVisible(tester, find.byKey(const Key('answer-choice-still-damp')));
    await selectObservation(tester, 'exterior-airflow');
    await tapInspectOrAnswerChoice(tester, 'weak');
    await selectFailureMode(tester, 'restricted-exhaust-airflow');
    await completeRepairReadinessIfPresent(tester);
    await completeGuidanceStepsIfPresent(tester);

    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('parts-cost-card')), findsNothing);
    expect(find.text('Lint filter'), findsNothing);
    expect(find.text('Flexible vent kit'), findsNothing);

    await tester.tap(find.byKey(const Key('outcome-resolved')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('outcome-what-fixed-field')),
      'Cleared the crushed vent hose',
    );
    await tester.tap(find.byKey(const Key('outcome-save-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('completion-done-screen')), findsOneWidget);
    expect(find.byKey(const Key('parts-cost-card')), findsNothing);
    expect(find.text('Flexible vent kit'), findsNothing);
    expect(find.byKey(const Key('completion-concluded')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('completion-what-you-did'))).data,
      'Cleared the crushed vent hose',
    );
    expect(find.byKey(const Key('completion-prevention')), findsOneWidget);
    expect(find.byKey(const Key('completion-maintenance-due')), findsOneWidget);
    expect(find.textContaining('Next due'), findsWidgets);
    expect(find.textContaining('lint filter'), findsWidgets);
    expect(find.text('Save & go home'), findsOneWidget);

    await tester.tap(find.byKey(const Key('completion-add-reminder')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reminder-note-field')),
      'Clean the lint filter next month',
    );
    await tester.tap(find.byKey(const Key('reminder-save-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('completion-reminder-saved')), findsOneWidget);

    final dryer = deps.appliancesForCurrentHousehold().single;
    expect(
      deps.maintenanceRemindersForAppliance(dryer.id),
      hasLength(1),
    );
    expect(
      deps.maintenanceRemindersForAppliance(dryer.id).single.note,
      'Clean the lint filter next month',
    );

    await tester.tap(find.byKey(const Key('completion-save-home')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recent-activity-title')), findsOneWidget);
    expect(find.textContaining('Fixed'), findsWidgets);
    expect(find.textContaining('Cleared the crushed vent hose'), findsWidgets);
    expect(deps.hasInProgressSession(dryer), isFalse);
    expect(deps.recentSessionOutcomes(), hasLength(1));
  });

  testWidgets(
    'washer drain Fixed wrap-up is path prevention and due, not dryer lint cost',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 18));
      await openWasherSession(tester, deps, 'Washer Done House');
      await tapVisible(tester, find.byKey(const Key('answer-choice-won-t-drain')));
      await selectFailureMode(tester, 'clogged-washer-drain-filter');
      await completeRepairReadinessIfPresent(tester);
      await completeGuidanceStepsIfPresent(tester);
      await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
      await tapVisible(tester, find.byKey(const Key('end-session-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('outcome-resolved')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('outcome-save-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('completion-done-screen')), findsOneWidget);
      expect(find.byKey(const Key('parts-cost-card')), findsNothing);
      expect(find.text('Lint filter'), findsNothing);
      expect(find.text('Flexible vent kit'), findsNothing);
      expect(find.byKey(const Key('completion-prevention')), findsOneWidget);
      expect(find.textContaining('drain filter'), findsWidgets);
      expect(find.textContaining('lint filter before every load'), findsNothing);
      expect(find.byKey(const Key('completion-maintenance-due')), findsOneWidget);
      expect(find.textContaining('about every 30 days'), findsWidgets);

      await tester.tap(find.byKey(const Key('completion-save-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recent-activity-title')), findsOneWidget);
      expect(find.textContaining('Fixed'), findsWidgets);
      final washer = deps.appliancesForCurrentHousehold().single;
      expect(deps.repairHistoryForAppliance(washer.id), hasLength(1));
      expect(
        deps.repairHistoryForAppliance(washer.id).single.outcome.closeKind,
        SessionCloseKind.fixed,
      );
    },
  );

  testWidgets(
    'heating-element path ends as pro recommended, not a DIY Fixed wrap-up',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 18, 10));
      await openDryerSession(tester, deps, 'Element Done House');
      await selectFailureMode(tester, 'heating-element-failed');
      await completeRepairReadinessIfPresent(tester);
      expect(find.byKey(const Key('pro-scope-warning-card')), findsNothing);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      await completeGuidanceStepsIfPresent(tester);
      expect(find.byKey(const Key('pro-recommended-card')), findsOneWidget);
      expect(find.byKey(const Key('verification-card')), findsNothing);
      await tapVisible(tester, find.byKey(const Key('pro-handoff-understand')));
      await saveSessionOutcome(
        tester,
        choiceKey: const Key('outcome-needs-professional'),
      );

      expect(find.textContaining('Needs a professional'), findsWidgets);
      final dryer = deps.appliancesForCurrentHousehold().single;
      expect(
        deps.repairHistoryForAppliance(dryer.id).single.outcome.closeKind,
        SessionCloseKind.calledProfessional,
      );
    },
  );
}
