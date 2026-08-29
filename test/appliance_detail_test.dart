import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/repair_history_display.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/knowledge_factory/dishwasher_mvp_v01.dart';
import 'package:modern_butlers_book/knowledge_factory/washer_mvp_v01.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('open session is omitted from completed appliance history', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 13));
    deps.createHousehold('Open Vs Closed');
    final dryer = deps.addDryer();
    final closedId = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: closedId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Vent cleared',
    );
    deps.startOrResumeSession(dryer);

    final history = deps.repairHistoryForAppliance(dryer.id);
    expect(history, hasLength(1));
    expect(history.single.outcome.sessionId, closedId);
    expect(history.single.outcome.closeKind, SessionCloseKind.fixed);
    expect(deps.hasInProgressSession(dryer), isTrue);
  });
  testWidgets('home opens dryer detail with identity and empty history', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 14));
    deps.createHousehold('Detail House');
    final dryer = deps.addDryer();

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('appliance-detail-${dryer.id}')), findsOneWidget);
    expect(find.byKey(const Key('appliance-detail-name')), findsOneWidget);
    expect(find.text(dryer.name), findsWidgets);
    expect(find.byKey(const Key('appliance-detail-category')), findsOneWidget);
    expect(find.text('Category: dryer'), findsOneWidget);
    expect(find.byKey(const Key('appliance-detail-model')), findsOneWidget);
    expect(find.textContaining('Model: ${dryer.modelNumber}'), findsOneWidget);
    expect(find.byKey(const Key('appliance-detail-start-repair')), findsOneWidget);
    expect(find.text('Start repair'), findsOneWidget);
    expect(find.text(UserFacingCopy.noRepairsYet), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Detail House'), findsOneWidget);
    expect(find.byKey(Key('appliance-${dryer.id}')), findsOneWidget);
  });

  testWidgets('detail shows Fixed history and Start repair still opens a session', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 15));
    deps.createHousehold('Fixed History House');
    final dryer = deps.addDryer();
    final sessionId = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleaned the lint filter',
    );

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('repair-history-$sessionId')), findsOneWidget);
    expect(find.textContaining('Cleaned the lint filter'), findsOneWidget);
    expect(find.textContaining('Fixed'), findsWidgets);
    expect(find.text(UserFacingCopy.noRepairsYet), findsNothing);

    await tester.tap(find.byKey(const Key('appliance-detail-start-repair')));
    await tester.pumpAndSettle();
    expect(find.text('Now: Answering questions'), findsOneWidget);
  });

  testWidgets('in-progress session is not a completed history row', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 10));
    deps.createHousehold('Open Session History');
    final dryer = deps.addDryer();
    deps.startOrResumeSession(dryer);

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Continue repair'), findsOneWidget);
    expect(find.text(UserFacingCopy.noRepairsYet), findsOneWidget);
    expect(find.byKey(Key('appliance-history-${dryer.id}')), findsNothing);
  });

  testWidgets('newest completed repair is listed first', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 11));
    deps.createHousehold('Two Repairs');
    final dryer = deps.addDryer();
    final firstId = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: firstId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Vent cleared',
    );
    final secondId = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: secondId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Fuse replaced',
    );

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();

    final tiles = tester.widgetList<ListTile>(
      find.descendant(
        of: find.byKey(Key('appliance-history-${dryer.id}')),
        matching: find.byType(ListTile),
      ),
    );
    expect(tiles, hasLength(2));
    expect(tiles.first.key, Key('repair-history-$secondId'));
    expect(find.textContaining('Fuse replaced'), findsOneWidget);
    expect(find.textContaining('Vent cleared'), findsOneWidget);
  });

  test('washer Fixed/verified is on washer history, not dryer, newest first', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 14));
    deps.createHousehold('Washer History');
    final dryer = deps.addDryer();
    final washer = deps.addWasher();
    final dryerId = deps.startOrResumeSession(dryer);
    deps.endSession(
      sessionId: dryerId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Vent cleared',
    );
    final washerFirst = deps.startOrResumeSession(washer);
    deps.endSession(
      sessionId: washerFirst,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleaned the drain filter',
    );
    final washerSecond = deps.startOrResumeSession(washer);
    deps.endSession(
      sessionId: washerSecond,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Opened the taps',
    );
    deps.startOrResumeSession(washer);

    final washerHistory = deps.repairHistoryForAppliance(washer.id);
    expect(washerHistory, hasLength(2));
    expect(washerHistory.first.outcome.sessionId, washerSecond);
    expect(washerHistory.first.outcome.closeKind, SessionCloseKind.fixed);
    expect(washerHistory.first.outcome.verified, isTrue);
    expect(washerHistory.last.outcome.sessionId, washerFirst);
    expect(
      deps.repairHistoryForAppliance(dryer.id).single.outcome.sessionId,
      dryerId,
    );
    expect(deps.hasInProgressSession(washer), isTrue);
  });

  test('appliance history keeps an older Fixed after many other-appliance rows', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 15));
    deps.createHousehold('History Cap');
    final washer = deps.addWasher();
    final dryer = deps.addDryer();
    final washerId = deps.startOrResumeSession(washer);
    deps.endSession(
      sessionId: washerId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleaned the drain filter',
    );
    for (var i = 0; i < 101; i++) {
      final id = deps.startOrResumeSession(dryer);
      deps.endSession(
        sessionId: id,
        closeKind: SessionCloseKind.fixed,
        whatFixedIt: 'Dryer fix $i',
      );
    }
    final washerHistory = deps.repairHistoryForAppliance(washer.id);
    expect(washerHistory, hasLength(1));
    expect(washerHistory.single.outcome.sessionId, washerId);
    expect(washerHistory.single.outcome.verified, isTrue);
  });

  test('washer Fixed stores the starter complaint as the history symptom', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 17));
    deps.createHousehold('Washer Symptom History');
    final washer = deps.addWasher();
    final sessionId = deps.startOrResumeSession(washer);
    final session = deps.repairSessionRepository.getSession(sessionId)!;
    deps.sessionCoordinator.addEvidence(
      evidence: Evidence(
        id: deps.nextId('evidence'),
        sessionId: sessionId,
        applianceId: washer.id,
        type: EvidenceType.structuredAnswer,
        observation: 'What is going wrong?',
        answer: "Won't drain",
        templateId: washerComplaintTemplateId,
        collectedAt: deps.nextTimestamp(),
        collectedInState: session.currentState,
        source: EvidenceSource.user,
        schemaVersion: session.schemaVersion,
      ),
      evidenceLinkId: deps.nextId('evidence-link'),
    );
    deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleaned the drain filter',
    );
    final row = deps.repairHistoryForAppliance(washer.id).single;
    expect(row.outcome.startSymptom, "Won't drain");
    expect(row.outcome.verified, isTrue);
    expect(repairHistoryHeadline(row.outcome), "Won't drain — Cleaned the drain filter");
  });

  test('dishwasher Fixed stores the starter complaint as the history symptom', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 10));
    deps.createHousehold('Dishwasher Symptom History');
    final dishwasher = deps.addDishwasher();
    final sessionId = deps.startOrResumeSession(dishwasher);
    final session = deps.repairSessionRepository.getSession(sessionId)!;
    deps.sessionCoordinator.addEvidence(
      evidence: Evidence(
        id: deps.nextId('evidence'),
        sessionId: sessionId,
        applianceId: dishwasher.id,
        type: EvidenceType.structuredAnswer,
        observation: 'What is the dishwasher doing?',
        answer: 'Standing water',
        templateId: dishwasherComplaintTemplateId,
        collectedAt: deps.nextTimestamp(),
        collectedInState: session.currentState,
        source: EvidenceSource.user,
        schemaVersion: session.schemaVersion,
      ),
      evidenceLinkId: deps.nextId('evidence-link'),
    );
    deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleaned the tub filter',
    );
    final row = deps.repairHistoryForAppliance(dishwasher.id).single;
    expect(row.outcome.startSymptom, 'Standing water');
    expect(row.outcome.verified, isTrue);
    expect(
      repairHistoryHeadline(row.outcome),
      'Standing water — Cleaned the tub filter',
    );
  });

  testWidgets('washer Fixed shows date, summary, and not the empty state', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 16));
    deps.createHousehold('Washer Detail History');
    final washer = deps.addWasher();
    final sessionId = deps.startOrResumeSession(washer);
    deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleaned the drain filter',
    );

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('appliance-${washer.id}')));
    await tester.pumpAndSettle();

    expect(find.text(UserFacingCopy.noRepairsYet), findsNothing);
    expect(find.byKey(Key('repair-history-$sessionId')), findsOneWidget);
    expect(find.textContaining('Cleaned the drain filter'), findsOneWidget);
    expect(find.textContaining('2026-08-18 · Fixed'), findsOneWidget);
  });

  testWidgets(
    'dishwasher Fixed shows date, summary, and not the empty state',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 11));
      deps.createHousehold('Dishwasher Detail History');
      final dishwasher = deps.addDishwasher();
      final sessionId = deps.startOrResumeSession(dishwasher);
      deps.endSession(
        sessionId: sessionId,
        closeKind: SessionCloseKind.fixed,
        whatFixedIt: 'Cleaned the tub filter',
      );

      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(dependencies: deps)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('appliance-${dishwasher.id}')));
      await tester.pumpAndSettle();

      expect(find.text(UserFacingCopy.noRepairsYet), findsNothing);
      expect(find.byKey(Key('repair-history-$sessionId')), findsOneWidget);
      expect(find.textContaining('Cleaned the tub filter'), findsOneWidget);
      expect(find.textContaining('2026-08-19 · Fixed'), findsOneWidget);
    },
  );

  testWidgets(
    'finishing a dryer path as fixed shows one history row',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 12));
      await openDryerSession(tester, deps, 'Finished Path History');
      await selectFailureMode(tester, 'clogged-lint-pathway');
      await reachClosePathVerificationIfPresent(tester);
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-confirmed')),
      );
      await tapVisible(tester, find.byKey(const Key('end-session-button')));
      await saveSessionOutcome(tester);

      final dryer = deps.appliancesForCurrentHousehold().single;
      await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
      await tester.pumpAndSettle();

      final history = deps.repairHistoryForAppliance(dryer.id);
      expect(history, hasLength(1));
      expect(history.single.outcome.closeKind, SessionCloseKind.fixed);
      expect(find.text(UserFacingCopy.noRepairsYet), findsNothing);
      expect(
        find.byKey(Key('repair-history-${history.single.outcome.sessionId}')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('guidance-did-this')), findsNothing);

      await tester.tap(find.byKey(const Key('appliance-detail-start-repair')));
      await tester.pumpAndSettle();
      await dismissProblemStarterIfPresent(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(deps.repairHistoryForAppliance(dryer.id), hasLength(1));
      expect(
        find.byKey(Key('repair-history-${history.single.outcome.sessionId}')),
        findsOneWidget,
      );
      expect(find.text('Continue repair'), findsOneWidget);
      expect(find.text(UserFacingCopy.noRepairsYet), findsNothing);
    },
  );

  testWidgets('history row shows optional note and survives restore', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final clock = () => DateTime.utc(2026, 8, 22, 11);
    final deps = AppDependencies(clock: clock, store: store);
    await openDryerSession(tester, deps, 'History Persist House');
    await selectFailureMode(tester, 'clogged-lint-pathway');
    await reachClosePathVerificationIfPresent(tester);
    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-confirmed')),
    );
    await tapVisible(tester, find.byKey(const Key('end-session-button')));
    await saveSessionOutcome(tester, note: 'Kept the receipt');
    await deps.flushPersist();

    final firstHistory = deps.repairHistoryForAppliance(
      deps.appliancesForCurrentHousehold().single.id,
    );
    expect(firstHistory, hasLength(1));
    expect(firstHistory.single.outcome.closeKind, SessionCloseKind.fixed);
    expect(firstHistory.single.outcome.userNote, 'Kept the receipt');

    final restored = AppDependencies(clock: clock, store: store);
    await restored.restore();
    final dryer = restored.appliancesForCurrentHousehold().single;
    expect(restored.hasInProgressSession(dryer), isFalse);
    expect(restored.repairHistoryForAppliance(dryer.id), hasLength(1));

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: restored)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();

    final sessionId =
        restored.repairHistoryForAppliance(dryer.id).single.outcome.sessionId;
    expect(find.byKey(Key('repair-history-$sessionId')), findsOneWidget);
    expect(find.textContaining('2026-08-22 · Fixed'), findsOneWidget);
    expect(find.text('Kept the receipt'), findsOneWidget);
    expect(find.text(UserFacingCopy.noRepairsYet), findsNothing);
  });
}
