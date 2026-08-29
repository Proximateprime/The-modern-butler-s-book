import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/maintenance_reminder_copy.dart';
import 'package:modern_butlers_book/helpers/opportunistic_maintenance.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('lint-housing guidance is access-open and offers vent-hood extra', () {
    final path = closePathForFailureMode('clogged-lint-pathway')!;
    expect(
      guidanceAccessAlreadyOpen(
        safeGuidanceSteps: path.safeGuidanceSteps,
        visualGuides: path.visualGuides,
      ),
      isTrue,
    );
    final items = opportunisticMaintenanceItems(
      safeGuidanceSteps: path.safeGuidanceSteps,
      visualGuides: path.visualGuides,
      failureModeId: path.failureModeId,
    );
    expect(items, isNotEmpty);
    expect(
      items.any((item) => item.label.toLowerCase().contains('vent hood')),
      isTrue,
    );
  });

  test('heating-element next steps still start with airflow checks', () {
    final path = closePathForFailureMode('heating-element-failed')!;
    expect(
      path.safeGuidanceSteps.first.toLowerCase(),
      contains('lint filter'),
    );
    expect(
      guidanceAccessAlreadyOpen(safeGuidanceSteps: path.safeGuidanceSteps),
      isTrue,
    );
  });

  testWidgets('user can skip all opportunistic extras', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 15));
    await openDryerSession(tester, deps, 'Skip Extras House');
    await answerObservation(tester, 'lint-filter-condition', 'heavily-clogged');
    await answerObservation(tester, 'exterior-airflow', 'weak');
    await answerObservation(tester, 'vent-hose-condition', 'yes-restricted');
    await selectFailureMode(tester, 'clogged-lint-pathway');
    await completeRepairReadinessIfPresent(tester);
    await completeGuidanceStepsIfPresent(tester);
    await tapConfirmedVerificationIfPresent(tester);
    final afterVerifyContinue = find.byKey(const Key('close-path-continue'));
    if (afterVerifyContinue.evaluate().isNotEmpty) {
      await tester.ensureVisible(afterVerifyContinue);
      await tester.pumpAndSettle();
      await tester.tap(afterVerifyContinue);
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const Key('opportunistic-maintenance-card')), findsOneWidget);
    expect(find.text(UserFacingCopy.opportunisticMaintenanceBody), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('opportunistic-skip-all')));
    expect(find.byKey(const Key('opportunistic-maintenance-card')), findsNothing);

    final dryer = deps.appliancesForCurrentHousehold().single;
    expect(deps.maintenanceRemindersForAppliance(dryer.id), isEmpty);
  });

  testWidgets('accepted extras log to maintenance and memory on Fixed', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 15, 10));
    await openDryerSession(tester, deps, 'Accept Extras House');
    await answerObservation(tester, 'lint-filter-condition', 'heavily-clogged');
    await answerObservation(tester, 'exterior-airflow', 'weak');
    await answerObservation(tester, 'vent-hose-condition', 'yes-restricted');
    await selectFailureMode(tester, 'clogged-lint-pathway');
    await completeRepairReadinessIfPresent(tester);
    await completeGuidanceStepsIfPresent(tester);
    await tapConfirmedVerificationIfPresent(tester);
    final afterVerifyContinue = find.byKey(const Key('close-path-continue'));
    if (afterVerifyContinue.evaluate().isNotEmpty) {
      await tester.ensureVisible(afterVerifyContinue);
      await tester.pumpAndSettle();
      await tester.tap(afterVerifyContinue);
      await tester.pumpAndSettle();
    }

    final itemFinder = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('opportunistic-item-');
    });
    expect(itemFinder, findsWidgets);
    final firstKey = tester.widget(itemFinder.first).key! as ValueKey<String>;
    await tapVisible(tester, find.byKey(firstKey));

    final dryer = deps.appliancesForCurrentHousehold().single;
    final reminders = deps.maintenanceRemindersForAppliance(dryer.id);
    expect(reminders, hasLength(1));
    expect(reminders.single.done, isTrue);
    expect(reminders.single.sessionId, isNotNull);
    if (reminders.single.intervalDays != null) {
      expect(reminders.single.intervalDays, typicalCalendarMaintenanceDays);
      expect(
        reminders.single.remindOn,
        DateTime.utc(2026, 8, 17).add(
          const Duration(days: typicalCalendarMaintenanceDays),
        ),
      );
    }

    await tapVisible(tester, find.byKey(const Key('close-path-continue')));
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await saveSessionOutcome(tester);

    final outcome = deps.repairHistoryForAppliance(dryer.id).single.outcome;
    expect(outcome.closeKind, SessionCloseKind.fixed);
    expect(outcome.preventiveActions, contains(reminders.single.note));
  });
}
