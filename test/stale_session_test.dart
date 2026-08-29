import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/stale_session.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('sessionIsStale uses the 48-hour constant', () {
    expect(staleOpenSessionHours, 48);
    expect(staleOpenSessionAfter, const Duration(hours: 48));

    final started = DateTime.utc(2026, 8, 15, 8);
    final session = RepairSession(
      id: 'session-1',
      applianceId: 'a-1',
      householdId: 'h-1',
      currentState: RepairSessionState.evidenceCollection,
      startedAt: started,
      lastActivityAt: started,
      createdByUserId: 'user-1',
      packageId: 'dryer-core',
      packageVersion: '1.3.0',
      schemaVersion: '1.0',
      stateHistory: const [],
    );

    expect(
      sessionIsStale(session, started.add(const Duration(hours: 47, minutes: 59))),
      isFalse,
    );
    expect(
      sessionIsStale(session, started.add(const Duration(hours: 48))),
      isTrue,
    );
  });

  testWidgets('stale resume can continue the same session', (tester) async {
    var now = DateTime.utc(2026, 8, 15, 8);
    final deps = AppDependencies(clock: () => now);
    deps.createHousehold('Stale Continue');
    final dryer = deps.addDryer();
    final sessionId = deps.startOrResumeSession(dryer);
    now = now.add(const Duration(hours: 48, minutes: 1));

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(Key('continue-repair-${dryer.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stale-session-dialog')), findsOneWidget);
    expect(find.text(UserFacingCopy.staleSessionBody), findsOneWidget);
    await tester.tap(find.byKey(const Key('stale-session-continue')));
    await tester.pumpAndSettle();
    await dismissProblemStarterIfPresent(tester);

    expect(deps.startOrResumeSession(dryer), sessionId);
    expect(deps.recentSessionOutcomes(), isEmpty);
  });

  testWidgets('stale resume can start fresh without a memory row', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 8, 15, 8);
    final deps = AppDependencies(clock: () => now);
    deps.createHousehold('Stale Fresh');
    final dryer = deps.addDryer();
    final oldId = deps.startOrResumeSession(dryer);
    now = now.add(const Duration(hours: 49));

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(Key('continue-repair-${dryer.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stale-session-start-fresh')));
    await tester.pumpAndSettle();
    await dismissProblemStarterIfPresent(tester);

    final newId = deps.startOrResumeSession(dryer);
    expect(newId, isNot(oldId));
    expect(
      deps.repairSessionRepository.getSession(oldId)!.currentState,
      RepairSessionState.abandoned,
    );
    expect(deps.recentSessionOutcomes(), isEmpty);
    expect(find.byKey(const Key('outcome-resolved')), findsNothing);
  });
}
