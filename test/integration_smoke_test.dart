import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    'smoke: no-heat → evidence → guidance → Fixed writes a memory row',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23, 10));
      await openDryerSession(
        tester,
        deps,
        'Smoke No Heat',
        skipProblemStarter: false,
      );
      await confirmNoHeatStarter(tester);

      expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);

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
      await chooseCallAProFromDecision(tester);
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
      expect(find.byKey(const Key('recent-activity-list')), findsOneWidget);
      expect(
        find.byKey(Key('recent-outcome-${history.single.outcome.sessionId}')),
        findsOneWidget,
      );
    },
  );

  testWidgets('smoke: open-session snapshot restores after persist', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final clock = DateTime.utc(2026, 8, 16, 23, 20);
    final first = AppDependencies(clock: () => clock, store: store);

    await openDryerSession(
      tester,
      first,
      'Smoke Resume',
      skipProblemStarter: false,
    );
    await confirmNoHeatStarter(tester);
    await answerObservation(tester, 'cycle-heat-setting', 'yes-heat-cycle');

    final dryer = first.appliancesForCurrentHousehold().single;
    final before = first.activeSessionSnapshotFor(dryer);
    expect(before, isNotNull);
    expect(before!.currentState, RepairSessionState.evidenceCollection);
    expect(before.evidence, isNotEmpty);
    final sessionId = before.sessionId;
    expect(first.hasInProgressSession(dryer), isTrue);
    expect(first.recentSessionOutcomes(), isEmpty);

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
    expect(after?.applianceId, restoredDryer.id);
    expect(after?.currentState, RepairSessionState.evidenceCollection);
    expect(after?.evidence.length, before.evidence.length);
    expect(second.hasInProgressSession(restoredDryer), isTrue);
    expect(second.recentSessionOutcomes(), isEmpty);
    expect(find.text('Continue repair'), findsOneWidget);

    await tester.tap(find.byKey(Key('continue-repair-${restoredDryer.id}')));
    await tester.pumpAndSettle();
    await dismissProblemStarterIfPresent(tester);
    expect(second.startOrResumeSession(restoredDryer), sessionId);
    expect(find.byType(SessionChromeBar), findsOneWidget);
  });

  testWidgets('smoke: too-hot then dry-but-hot chip path does not crash', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23, 30));
    await openDryerSession(
      tester,
      deps,
      'Smoke Excess Heat',
      skipProblemStarter: false,
    );

    await tester.tap(find.byKey(const Key('starter-chip-dryer-very-hot')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('problem-starter-confirm')));
    await tester.pumpAndSettle();

    expect(find.byType(SessionChromeBar), findsOneWidget);
    expect(find.byKey(const Key('problem-starter-panel')), findsNothing);
    expect(
      find.byKey(const Key('observation-prompt-heat-observed')),
      findsNothing,
    );

    await answerObservation(tester, 'exterior-airflow', 'weak');
    await answerObservation(
      tester,
      'clothes-feel-after-cycle',
      'dry-but-unusually-hot',
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SessionChromeBar), findsOneWidget);
    expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
    final dryer = deps.appliancesForCurrentHousehold().single;
    final snapshot = deps.activeSessionSnapshotFor(dryer);
    expect(snapshot, isNotNull);
    expect(
      snapshot!.evidence.any(
        (item) => item.answer == 'Dry but unusually hot',
      ),
      isTrue,
    );
  });
}
