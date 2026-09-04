import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/clue_copy.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/models/session_ui_resume_state.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/session_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('version is 0.1.4+27', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+27');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+27'));
  });

  test('resume pack does not introduce Transform', () {
    for (final path in [
      'lib/main.dart',
      'lib/ui/home_screen.dart',
      'lib/ui/session_screen.dart',
      'lib/ui/app_dependencies.dart',
      'lib/services/local_domain_store.dart',
    ]) {
      final source = _read(path);
      expect(source, isNot(contains('Transform(')));
      expect(source, isNot(contains('Transform.')));
    }
  });

  test('background flush keeps pending question after an in-flight save',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final clock = DateTime.utc(2026, 9, 4, 8);
    final first = AppDependencies(clock: () => clock, store: store);
    first.createHousehold('Flush Race');
    final dryer = first.addDryer();
    final sessionId = first.startOrResumeSession(dryer);
    first.saveSessionUiResume(
      sessionId,
      const SessionUiResumeState(
        pendingObservationTemplateId: 'heat-observed',
        starterConfirmed: true,
      ),
    );
    first.noteEnteredRepairSession(sessionId);
    first.setBeforeBackgroundFlush(() {
      first.saveSessionUiResume(
        sessionId,
        const SessionUiResumeState(
          pendingObservationTemplateId: 'cycle-heat-setting',
          starterConfirmed: true,
        ),
      );
    });
    await first.persistForBackground();

    final second = AppDependencies(clock: () => clock, store: store);
    await second.restore();
    final restoredDryer = second.appliancesForCurrentHousehold().single;
    final snapshot = second.activeSessionSnapshotFor(restoredDryer);
    expect(snapshot?.sessionId, sessionId);
    expect(
      snapshot?.uiResume?.pendingObservationTemplateId,
      'cycle-heat-setting',
    );
    expect(second.foregroundSessionId, sessionId);
  });

  test('empty store restore does not invent an in-progress session', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 9),
      store: store,
    );
    await deps.restore();
    expect(deps.appliancesForCurrentHousehold(), isEmpty);
    expect(deps.repairSessionRepository.listAllSessions(), isEmpty);
    expect(deps.foregroundSessionId, isNull);
  });

  testWidgets(
    'pause then resume keeps the open question and clues count',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = DateTime.utc(2026, 9, 4, 10);
      final deps = AppDependencies(clock: () => clock, store: store);

      await openDryerSession(tester, deps, 'Lock Resume');
      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );
      await selectObservation(tester, 'cycle-heat-setting');
      expect(find.text(householdClueSummary(1)), findsWidgets);
      expect(
        find.descendant(
          of: find.byKey(const Key('answer-choice-panel')),
          matching: find.byKey(
            const Key('observation-prompt-cycle-heat-setting'),
          ),
        ),
        findsOneWidget,
      );

      await simulateAppPausedThenResumed(tester, deps);

      expect(find.byType(SessionScreen), findsOneWidget);
      expect(find.text(householdClueSummary(1)), findsWidgets);
      expect(find.text('Evidence count: 1'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('answer-choice-panel')),
          matching: find.byKey(
            const Key('observation-prompt-cycle-heat-setting'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('answer-choice-yes-heat-cycle')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'cold start reopens the same question and the same clues',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = DateTime.utc(2026, 9, 4, 11);
      final first = AppDependencies(clock: () => clock, store: store);

      await openDryerSession(tester, first, 'Cold Start Resume');
      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );
      await selectObservation(tester, 'cycle-heat-setting');
      expect(find.text(householdClueSummary(1)), findsWidgets);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      await first.persistForBackground();

      final second = AppDependencies(clock: () => clock, store: store);
      await second.restore();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await prepareTallSurface(tester);
      await tester.pumpWidget(ModernButlerApp(dependencies: second));
      await tester.pumpAndSettle();

      expect(find.byType(SessionScreen), findsOneWidget);
      expect(find.text(householdClueSummary(1)), findsWidgets);
      expect(find.text('Evidence count: 1'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('answer-choice-panel')),
          matching: find.byKey(
            const Key('observation-prompt-cycle-heat-setting'),
          ),
        ),
        findsOneWidget,
      );
      final dryer = second.appliancesForCurrentHousehold().single;
      expect(second.hasInProgressSession(dryer), isTrue);
      expect(
        second.uiResumeForSession(
          second.repairSessionRepository.listAllSessions().single.id,
        )?.pendingObservationTemplateId,
        'cycle-heat-setting',
      );
      expect(second.repairSessionRepository.listAllSessions(), hasLength(1));
    },
  );

  testWidgets(
    'Exit then cold start stays on home Continue repair, not a new session',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = DateTime.utc(2026, 9, 4, 12);
      final first = AppDependencies(clock: () => clock, store: store);

      await openDryerSession(tester, first, 'Exit Then Cold');
      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await first.flushPersist();

      final second = AppDependencies(clock: () => clock, store: store);
      await second.restore();
      await prepareTallSurface(tester);
      await tester.pumpWidget(ModernButlerApp(dependencies: second));
      await tester.pumpAndSettle();

      expect(find.byType(SessionScreen), findsNothing);
      expect(find.text('Continue repair'), findsOneWidget);
      final dryer = second.appliancesForCurrentHousehold().single;
      expect(second.hasInProgressSession(dryer), isTrue);
      expect(second.foregroundSessionId, isNull);
      expect(second.repairSessionRepository.listAllSessions(), hasLength(1));
    },
  );

  testWidgets(
    'completed session does not resurrect as in-progress after restore',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = DateTime.utc(2026, 9, 4, 13);
      final first = AppDependencies(clock: () => clock, store: store);

      await openDryerSession(tester, first, 'Completed No Ghost');
      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );
      final dryer = first.appliancesForCurrentHousehold().single;
      final sessionId = first.repairSessionRepository.listAllSessions().single.id;
      first.endSession(
        sessionId: sessionId,
        closeKind: SessionCloseKind.fixed,
        whatFixedIt: 'Cleaned the lint trap',
      );
      expect(first.hasInProgressSession(dryer), isFalse);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await first.flushPersist();

      final second = AppDependencies(clock: () => clock, store: store);
      await second.restore();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await prepareTallSurface(tester);
      await tester.pumpWidget(ModernButlerApp(dependencies: second));
      await tester.pumpAndSettle();

      final restoredDryer = second.appliancesForCurrentHousehold().single;
      expect(second.hasInProgressSession(restoredDryer), isFalse);
      expect(second.activeSessionSnapshotFor(restoredDryer), isNull);
      expect(find.text('Continue repair'), findsNothing);
      expect(find.byType(SessionScreen), findsNothing);
      expect(second.recentSessionOutcomes(), hasLength(1));
    },
  );

  testWidgets('empty household has no Continue repair after persist', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final clock = DateTime.utc(2026, 9, 4, 14);
    final first = AppDependencies(clock: () => clock, store: store);
    first.createHousehold('No Session Yet');
    first.addDryer();
    await first.flushPersist();
    expect(
      first.hasInProgressSession(first.appliancesForCurrentHousehold().single),
      isFalse,
    );

    final second = AppDependencies(clock: () => clock, store: store);
    await second.restore();
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: second));
    await tester.pumpAndSettle();

    expect(find.text('Continue repair'), findsNothing);
    expect(find.byType(SessionScreen), findsNothing);
    expect(
      second.hasInProgressSession(second.appliancesForCurrentHousehold().single),
      isFalse,
    );
    expect(
      second.repairSessionRepository.listAllSessions().where(
        (session) =>
            session.currentState != RepairSessionState.sessionClosed &&
            session.currentState != RepairSessionState.abandoned &&
            session.currentState != RepairSessionState.escalated &&
            session.currentState != RepairSessionState.error,
      ),
      isEmpty,
    );
  });
}
