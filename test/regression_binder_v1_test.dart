/// Regression binder v1 — run before release:
/// `flutter test test/regression_binder_v1_test.dart`
///
/// Critical paths: dryer no-heat Fixed+memory, resume, washer drain,
/// dishwasher standing water, hazard hard-stop.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/knowledge_factory/dishwasher_mvp_v01.dart';
import 'package:modern_butlers_book/knowledge_factory/washer_mvp_v01.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/product_chrome.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets(
    'binder: dryer no-heat Fixed writes memory',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 13));
      await openDryerSession(
        tester,
        deps,
        'Binder No Heat',
        skipProblemStarter: false,
      );
      await confirmNoHeatStarter(tester);

      await answerObservation(tester, 'cycle-heat-setting', 'yes-heat-cycle');
      await answerObservation(tester, 'drum-turns', 'turns-normally');
      await answerObservation(
        tester,
        'wall-plug-seated',
        'fully-seated-looks-normal',
      );
      await answerObservation(
        tester,
        'clothes-feel-after-cycle',
        'cold-and-still-damp',
      );
      await selectFailureMode(tester, 'heating-element-failed');
      await completeRepairReadinessIfPresent(tester);

      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      await completeGuidanceStepsIfPresent(tester);
      expect(find.byKey(const Key('pro-recommended-card')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('pro-handoff-understand')));
      await saveSessionOutcome(
        tester,
        choiceKey: const Key('outcome-needs-professional'),
      );

      final dryer = deps.appliancesForCurrentHousehold().single;
      final history = deps.repairHistoryForAppliance(dryer.id);
      expect(history, hasLength(1));
      expect(
        history.single.outcome.closeKind,
        SessionCloseKind.calledProfessional,
      );
      expect(deps.hasInProgressSession(dryer), isFalse);
    },
  );

  testWidgets('binder: open session resumes after persist', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final clock = DateTime.utc(2026, 8, 17, 13, 10);
    final first = AppDependencies(clock: () => clock, store: store);

    await openDryerSession(
      tester,
      first,
      'Binder Resume',
      skipProblemStarter: false,
    );
    await confirmNoHeatStarter(tester);
    await answerObservation(tester, 'cycle-heat-setting', 'yes-heat-cycle');

    final dryer = first.appliancesForCurrentHousehold().single;
    final before = first.activeSessionSnapshotFor(dryer);
    expect(before, isNotNull);
    expect(before!.currentState, RepairSessionState.evidenceCollection);
    final sessionId = before.sessionId;

    await tester.pageBack();
    await tester.pumpAndSettle();
    await first.flushPersist();

    final second = AppDependencies(clock: () => clock, store: store);
    await second.restore();
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: second));
    await tester.pumpAndSettle();

    final restoredDryer = second.appliancesForCurrentHousehold().single;
    final after = second.activeSessionSnapshotFor(restoredDryer);
    expect(after?.sessionId, sessionId);
    expect(after?.currentState, RepairSessionState.evidenceCollection);
    expect(after?.evidence.length, before.evidence.length);
    expect(find.text('Continue repair'), findsOneWidget);

    await tester.tap(find.byKey(Key('continue-repair-${restoredDryer.id}')));
    await tester.pumpAndSettle();
    await dismissProblemStarterIfPresent(tester);
    expect(second.startOrResumeSession(restoredDryer), sessionId);
    expect(find.byType(SessionChromeBar), findsOneWidget);
  });

  testWidgets('binder: washer drain verifies then Fixed writes memory', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 13, 20));
    await openWasherSession(tester, deps, 'Binder Washer Drain');
    await tapVisible(tester, find.byKey(const Key('answer-choice-won-t-drain')));
    await selectFailureMode(tester, washerCloggedDrainFilterId);
    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    await completeGuidanceStepsIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await saveSessionOutcome(tester);

    final washer = deps.appliancesForCurrentHousehold().single;
    final history = deps.repairHistoryForAppliance(washer.id);
    expect(history, hasLength(1));
    expect(history.single.outcome.closeKind, SessionCloseKind.fixed);
  });

  testWidgets(
    'binder: dishwasher standing water verifies then Fixed writes memory',
    (tester) async {
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 17, 13, 30),
      );
      await openDishwasherSession(tester, deps, 'Binder Dishwasher Water');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-standing-water')),
      );
    await selectFailureMode(tester, dishwasherCloggedFilterId);
    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    await completeGuidanceStepsIfPresent(tester);
    await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
      await tapVisible(tester, find.byKey(const Key('end-session-button')));
      await tester.pumpAndSettle();
      await saveSessionOutcome(tester);

      final dishwasher = deps.appliancesForCurrentHousehold().single;
      final history = deps.repairHistoryForAppliance(dishwasher.id);
      expect(history, hasLength(1));
      expect(history.single.outcome.closeKind, SessionCloseKind.fixed);
    },
  );

  testWidgets('binder: hazard observation hard-stops without Fixed', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 13, 40));
    await openDryerSession(tester, deps, 'Binder Hazard');

    await selectObservation(tester, 'hazard-observation');
    await tapVisible(tester, find.byKey(const Key('answer-choice-yes')));

    expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
    expect(find.text('Stop — Call a professional'), findsOneWidget);
    expect(find.byKey(const Key('answer-choice-panel')), findsNothing);
    expect(find.text('Needs a professional'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('outcome-needs-professional')), findsOneWidget);
    expect(find.byKey(const Key('outcome-resolved')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('outcome-save-button')));
    await tester.tap(find.byKey(const Key('outcome-save-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pro-handoff-screen')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('completion-save-home')));
    await tester.tap(find.byKey(const Key('completion-save-home')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('session-outcome-summary')), findsNothing);
    final dryer = deps.appliancesForCurrentHousehold().single;
    expect(deps.hasInProgressSession(dryer), isFalse);
    final history = deps.repairHistoryForAppliance(dryer.id);
    expect(history, hasLength(1));
    expect(history.single.outcome.closeKind, isNot(SessionCloseKind.fixed));
  });
}
