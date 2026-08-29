import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/pattern_hint.dart';
import 'package:modern_butlers_book/models/maintenance_reminder.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SessionOutcome ventFix({required String sessionId}) {
    return SessionOutcome(
      sessionId: sessionId,
      resolutionStatus: SessionResolutionStatus.resolved,
      closeKind: SessionCloseKind.fixed,
      immediateCause: 'Cleared the exterior vent',
      contributingFactors: const [],
      preventiveActions: const ['Keep the exterior vent hood clear'],
      verified: true,
      schemaVersion: '1.0',
      rankingLeaderFailureModeId: 'restricted-exhaust-airflow',
      rankingLeaderLabel: 'Restricted exhaust',
    );
  }

  test('single verified vent fix is not a hint', () {
    expect(
      patternHintFromHistory(
        outcomes: [ventFix(sessionId: 'one')],
        reminders: const [],
      ),
      isNull,
    );
  });

  test('two verified vent fixes surface a household-history hint', () {
    final hint = patternHintFromHistory(
      outcomes: [
        ventFix(sessionId: 'one'),
        ventFix(sessionId: 'two'),
      ],
      reminders: const [],
    );
    expect(hint, isNotNull);
    expect(hint!.familyId, patternHintFamilyVent);
    expect(hint.occurrenceCount, 2);
    expect(hint.body, contains('Based on your household history'));
    expect(hint.body.toLowerCase(), isNot(contains('guess from the cloud')));
    expect(hint.body, contains('not a guess'));
  });

  test('not-fixed and unverified rows do not count', () {
    expect(
      patternHintFromHistory(
        outcomes: [
          SessionOutcome(
            sessionId: 'a',
            resolutionStatus: SessionResolutionStatus.unresolved,
            closeKind: SessionCloseKind.notFixed,
            immediateCause: 'Cleared the exterior vent',
            contributingFactors: const [],
            preventiveActions: const [],
            verified: false,
            schemaVersion: '1.0',
            rankingLeaderFailureModeId: 'restricted-exhaust-airflow',
          ),
          ventFix(sessionId: 'b'),
        ],
        reminders: const [],
      ),
      isNull,
    );
  });

  test('thermal-fuse mode is never a vent hint even with vent prevention', () {
    expect(
      patternHintFromHistory(
        outcomes: [
          SessionOutcome(
            sessionId: 'fuse-1',
            resolutionStatus: SessionResolutionStatus.resolved,
            closeKind: SessionCloseKind.fixed,
            immediateCause: 'Thermal fuse replaced',
            contributingFactors: const [],
            preventiveActions: const ['Keep the vent path clear'],
            verified: true,
            schemaVersion: '1.0',
            rankingLeaderFailureModeId: 'thermal-fuse-open',
          ),
          SessionOutcome(
            sessionId: 'fuse-2',
            resolutionStatus: SessionResolutionStatus.resolved,
            closeKind: SessionCloseKind.fixed,
            immediateCause: 'Thermal fuse replaced',
            contributingFactors: const [],
            preventiveActions: const ['Keep the vent path clear'],
            verified: true,
            schemaVersion: '1.0',
            rankingLeaderFailureModeId: 'thermal-fuse-open',
          ),
        ],
        reminders: const [],
      ),
      isNull,
    );
  });

  test('dismissed family is not shown', () {
    expect(
      patternHintFromHistory(
        outcomes: [
          ventFix(sessionId: 'one'),
          ventFix(sessionId: 'two'),
        ],
        reminders: const [],
        dismissedFamilyIds: {patternHintFamilyVent},
      ),
      isNull,
    );
  });

  test('one vent fix plus matching maintenance reaches the threshold', () {
    final hint = patternHintFromHistory(
      outcomes: [ventFix(sessionId: 'one')],
      reminders: [
        MaintenanceReminder(
          id: 'r1',
          householdId: 'h',
          applianceId: 'a',
          note: 'Clean lint system',
          remindOn: DateTime.utc(2026, 8, 22),
          createdAt: DateTime.utc(2026, 8, 22),
        ),
      ],
    );
    expect(hint?.familyId, patternHintFamilyVent);
  });

  test('endSession: two vent fixes show on detail; one does not', () async {
    final two = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 19));
    two.createHousehold('Vent Repeat House');
    final dryerTwo = two.addDryer(name: 'Repeat Dryer');
    for (var i = 0; i < 2; i++) {
      final sessionId = two.startOrResumeSession(dryerTwo);
      two.endSession(
        sessionId: sessionId,
        closeKind: SessionCloseKind.fixed,
        whatFixedIt: 'Cleared the exterior vent',
        rankingLeaderFailureModeId: 'restricted-exhaust-airflow',
      );
    }
    expect(two.patternHintForAppliance(dryerTwo.id), isNotNull);

    final one = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 19, 1));
    one.createHousehold('Vent Once House');
    final dryerOne = one.addDryer(name: 'Once Dryer');
    final sessionId = one.startOrResumeSession(dryerOne);
    one.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleared the exterior vent',
      rankingLeaderFailureModeId: 'restricted-exhaust-airflow',
    );
    expect(one.patternHintForAppliance(dryerOne.id), isNull);
  });

  test('sample home does not invent a pattern hint', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 19, 2));
    deps.loadSampleHome(includeOpenSession: false);
    final dryer = deps.appliancesForCurrentHousehold().firstWhere(
      (item) => item.category == 'dryer',
    );
    expect(deps.patternHintForAppliance(dryer.id), isNull);
  });

  testWidgets('appliance page shows then dismisses a vent pattern hint', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 22, 19, 3),
      store: store,
    );
    deps.createHousehold('Hint House');
    final dryer = deps.addDryer();
    for (var i = 0; i < 2; i++) {
      final sessionId = deps.startOrResumeSession(dryer);
      deps.endSession(
        sessionId: sessionId,
        closeKind: SessionCloseKind.fixed,
        whatFixedIt: 'Cleared the exterior vent',
        rankingLeaderFailureModeId: 'restricted-exhaust-airflow',
      );
    }

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pattern-hint-card')), findsOneWidget);
    expect(find.textContaining('Based on your household history'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pattern-hint-dismiss')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pattern-hint-card')), findsNothing);
    await deps.flushPersist();

    final restored = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 22, 19, 4),
      store: store,
    );
    await restored.restore();
    expect(restored.patternHintForAppliance(dryer.id), isNull);
  });
}
