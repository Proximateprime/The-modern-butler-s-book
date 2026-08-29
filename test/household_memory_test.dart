import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';

import 'support/session_test_helpers.dart';

void main() {
  group('Household memory v1', () {
    test('fixed outcome save creates a memory row with summary', () {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 14, 21));
      deps.createHousehold('Memory House');
      final dryer = deps.addDryer();
      final sessionId = deps.startOrResumeSession(dryer);

      final outcome = deps.endSession(
        sessionId: sessionId,
        closeKind: SessionCloseKind.fixed,
        whatFixedIt: 'Cleaned the lint filter',
        preventionNote: 'Clean the filter every load',
        userNote: 'Took about 10 minutes',
      );

      expect(outcome.closeKind, SessionCloseKind.fixed);
      expect(outcome.verified, isTrue);
      expect(outcome.immediateCause, 'Cleaned the lint filter');
      expect(outcome.preventiveActions, contains('Clean the filter every load'));
      expect(outcome.userNote, 'Took about 10 minutes');
      expect(outcome.summary, contains('Fixed'));
      expect(outcome.summary, contains('Cleaned the lint filter'));
      expect(outcome.recordedAt, isNotNull);
      expect(outcome.heatPathPolarity, isNotNull);

      final history = deps.repairHistoryForAppliance(dryer.id);
      expect(history, hasLength(1));
      expect(history.single.outcome.sessionId, sessionId);
      expect(history.single.outcome.summary, outcome.summary);
      expect(deps.hasInProgressSession(dryer), isFalse);
    });

    test('not-fixed, stopped, and pro outcomes save without crashing', () {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 14, 22));
      deps.createHousehold('Memory House');
      final dryer = deps.addDryer();

      final notFixedId = deps.startOrResumeSession(dryer);
      deps.endSession(
        sessionId: notFixedId,
        closeKind: SessionCloseKind.notFixed,
        userNote: 'Still cold',
      );

      final stoppedId = deps.startOrResumeSession(dryer);
      expect(stoppedId, isNot(notFixedId));
      deps.endSession(
        sessionId: stoppedId,
        closeKind: SessionCloseKind.stopped,
      );

      final proId = deps.startOrResumeSession(dryer);
      deps.endSession(
        sessionId: proId,
        closeKind: SessionCloseKind.calledProfessional,
      );

      final history = deps.repairHistoryForAppliance(dryer.id);
      expect(history, hasLength(3));
      expect(
        history.map((item) => item.outcome.closeKind).toSet(),
        {
          SessionCloseKind.calledProfessional,
          SessionCloseKind.stopped,
          SessionCloseKind.notFixed,
        },
      );
      expect(deps.hasInProgressSession(dryer), isFalse);
      expect(
        deps.repairSessionRepository.getSession(notFixedId)!.currentState,
        RepairSessionState.sessionClosed,
      );
    });

    test('second session starts clean after outcome close', () {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 14, 23));
      deps.createHousehold('Memory House');
      final dryer = deps.addDryer();
      final first = deps.startOrResumeSession(dryer);
      deps.endSession(
        sessionId: first,
        closeKind: SessionCloseKind.fixed,
      );

      expect(deps.hasInProgressSession(dryer), isFalse);
      expect(deps.uiResumeForSession(first), isNull);

      final second = deps.startOrResumeSession(dryer);
      expect(second, isNot(first));
      expect(deps.hasInProgressSession(dryer), isTrue);
      expect(
        deps.repairSessionRepository.getSession(second)!.currentState,
        RepairSessionState.evidenceCollection,
      );
      expect(deps.outcomeForSession(second), isNull);
    });
  });

  testWidgets('home and appliance detail can read saved repair history', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 14, 21));
    deps.createHousehold('Memory House');
    final dryer = deps.addDryer();
    final sessionId = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Replaced heating element',
    );

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();

    expect(find.text(UserFacingCopy.noRepairsYet), findsNothing);
    expect(find.byKey(Key('repair-history-$sessionId')), findsOneWidget);
    expect(
      find.textContaining('Replaced heating element'),
      findsOneWidget,
    );
    expect(find.byKey(Key('appliance-history-${dryer.id}')), findsOneWidget);
  });

  testWidgets('empty appliance history uses No repairs yet', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 14, 20));
    deps.createHousehold('Empty History');
    final dryer = deps.addDryer();

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();

    expect(find.text(UserFacingCopy.noRepairsYet), findsOneWidget);
    expect(
      find.byKey(Key('appliance-history-empty-${dryer.id}')),
      findsOneWidget,
    );
  });

  testWidgets('outcome screen save writes history visible on home', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 14, 19));
    await openDryerSession(tester, deps, 'Outcome Save House');

    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await tester.pumpAndSettle();
    await saveSessionOutcome(
      tester,
      choiceKey: const Key('outcome-unresolved'),
    );

    expect(find.text(UserFacingCopy.noRepairsYet), findsNothing);
    expect(find.textContaining('Not fixed'), findsWidgets);
    expect(
      deps.hasInProgressSession(deps.appliancesForCurrentHousehold().single),
      isFalse,
    );
  });
}
