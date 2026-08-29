import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/household_tools.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('catalog ids match readiness canonical ids', () {
    expect(toolIdFromInventoryLabel('Phillips screwdriver'), 'screwdriver');
    expect(toolIdFromInventoryLabel('Shallow pan and towel'), 'shallow-pan');
    expect(householdToolLabel('nut-driver'), 'Nut driver');
    expect(householdToolLabel('hex-key'), 'Hex Key');
  });

  test('add and remove owned tools on the household', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 18));
    deps.createHousehold('Tool House');
    deps.rememberOwnedTool('screwdriver');
    deps.rememberOwnedTool('flashlight');
    expect(
      deps.currentHousehold!.ownedToolIds,
      ['flashlight', 'screwdriver'],
    );

    deps.forgetOwnedTool('screwdriver');
    expect(deps.currentHousehold!.ownedToolIds, ['flashlight']);
    expect(deps.householdOwnsTool('screwdriver'), isFalse);
  });

  test('owned tools survive local persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final first = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 18),
      store: store,
    );
    first.createHousehold('Persist Tools');
    first.rememberOwnedTool('pliers');
    await first.flushPersist();

    final second = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 18),
      store: store,
    );
    await second.restore();
    expect(second.currentHousehold!.ownedToolIds, ['pliers']);
  });

  test('owned tools overlay survives a stale domain snapshot', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final first = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 19, 11),
      store: store,
    );
    first.createHousehold('Stale Snapshot Tools');
    first.rememberOwnedTool('flashlight');
    await first.flushPersist();

    final snapshot = await store.load();
    expect(snapshot, isNotNull);
    await store.save(
      DomainSnapshot(
        idCounter: snapshot!.idCounter,
        lastTimestamp: snapshot.lastTimestamp,
        currentHouseholdId: snapshot.currentHouseholdId,
        sessionIdByApplianceId: snapshot.sessionIdByApplianceId,
        packageRefsBySession: snapshot.packageRefsBySession,
        households: [
          for (final household in snapshot.households)
            household.copyWith(ownedToolIds: const []),
        ],
        appliances: snapshot.appliances,
        sessions: snapshot.sessions,
        evidence: snapshot.evidence,
        evidenceLinks: snapshot.evidenceLinks,
        hypotheses: snapshot.hypotheses,
        hypothesisIdsBySession: snapshot.hypothesisIdsBySession,
        outcomes: snapshot.outcomes,
        sessionUiResumeBySessionId: snapshot.sessionUiResumeBySessionId,
        maintenanceReminders: snapshot.maintenanceReminders,
        repairComfort: snapshot.repairComfort,
        expertMode: snapshot.expertMode,
      ),
    );

    final second = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 19, 11, 1),
      store: store,
    );
    await second.restore();
    expect(second.currentHousehold!.ownedToolIds, ['flashlight']);
  });

  test('newer snapshot tools survive a stale empty overlay', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final first = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 22, 9),
      store: store,
    );
    first.createHousehold('Stale Overlay Tools');
    first.rememberOwnedTool('screwdriver');
    await first.flushPersist();

    await prefs.setString(
      LocalDomainStore.ownedToolsOverlayKey,
      jsonEncode({
        first.currentHousehold!.id: {'ids': <String>[], 'generation': 0},
      }),
    );

    final second = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 22, 9, 1),
      store: store,
    );
    await second.restore();
    expect(second.currentHousehold!.ownedToolIds, ['screwdriver']);
    expect(second.householdOwnsTool('screwdriver'), isTrue);
  });

  testWidgets('home and settings open tools inventory add/remove', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 18));
    deps.createHousehold('Inventory House');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    expect(find.byKey(const Key('tools-inventory-button')), findsOneWidget);
    expect(find.byKey(const Key('home-settings-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-tools-item'));
    await tester.tap(find.byKey(const Key('settings-tools-item')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tools-inventory-screen')), findsOneWidget);
    expect(find.byKey(const Key('tools-inventory-empty')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tools-inventory-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tools-add-screwdriver')));
    await tester.pump();
    expect(find.byKey(const Key('tools-owned-screwdriver')), findsOneWidget);
    expect(deps.householdOwnsTool('screwdriver'), isTrue);

    await tester.enterText(
      find.byKey(const Key('tools-custom-name-field')),
      'hex key',
    );
    await tester.tap(find.byKey(const Key('tools-add-custom-button')));
    await tester.pump();
    expect(find.byKey(const Key('tools-owned-hex-key')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tools-remove-screwdriver')));
    await tester.pump();
    expect(find.byKey(const Key('tools-owned-screwdriver')), findsNothing);
    expect(deps.householdOwnsTool('screwdriver'), isFalse);
    expect(deps.householdOwnsTool('hex-key'), isTrue);
  });

  testWidgets('I have this can also save the tool to inventory', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 18));
    await openDryerSession(tester, deps, 'Seed From Readiness');
    await selectFailureMode(tester, 'thermal-fuse-open');
    await advanceClosePathFromConclusionIfPresent(tester);
    await completeInspectStepsIfPresent(tester);
    await tapVisible(
      tester,
      find.byKey(const Key('readiness-have-screwdriver')),
    );
    expect(deps.householdOwnsTool('screwdriver'), isFalse);
    await tapVisible(
      tester,
      find.byKey(const Key('readiness-save-screwdriver')),
    );

    expect(deps.householdOwnsTool('screwdriver'), isTrue);
    await tapVisible(
      tester,
      find.byKey(const Key('readiness-have-flashlight')),
    );
    expect(find.text('In your tools'), findsOneWidget);
    expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
    await tapVisible(tester, find.byKey(const Key('close-path-tools-continue')));
    expect(deps.householdOwnsTool('screwdriver'), isTrue);
  });

  testWidgets(
    'saved checklist tool survives persist, Tools, and the next repair',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 19, 10),
        store: store,
      );
      await openDryerSession(tester, deps, 'Persist Checklist Tool');
      await selectFailureMode(tester, 'thermal-fuse-open');
      await advanceClosePathFromConclusionIfPresent(tester);
      await completeInspectStepsIfPresent(tester);
      await tapVisible(
        tester,
        find.byKey(const Key('readiness-have-screwdriver')),
      );
      await tapVisible(
        tester,
        find.byKey(const Key('readiness-save-screwdriver')),
      );
      await tapVisible(
        tester,
        find.byKey(const Key('readiness-have-flashlight')),
      );
      await tapVisible(tester, find.byKey(const Key('close-path-tools-continue')));
      await deps.flushPersist();

      final restored = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 19, 10, 1),
        store: store,
      );
      await restored.restore();
      expect(restored.householdOwnsTool('screwdriver'), isTrue);
      restored.clearOpenSessions();

      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(dependencies: restored)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tools-inventory-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tools-owned-screwdriver')), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laundry Room Dryer'));
      await tester.pumpAndSettle();
      await startRepairFromDetail(tester);
      await dismissProblemStarterIfPresent(tester);
      await selectFailureMode(tester, 'thermal-fuse-open');
      await advanceClosePathFromConclusionIfPresent(tester);
      await completeInspectStepsIfPresent(tester);
      expect(
        find.byKey(const Key('readiness-in-inventory-screwdriver')),
        findsOneWidget,
      );
      expect(find.text('In your tools'), findsOneWidget);
      expect(find.byKey(const Key('readiness-save-screwdriver')), findsNothing);
    },
  );

  testWidgets(
    'tools inventory add survives persist and the next repair checklist',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 19, 10, 5),
        store: store,
      );
      deps.createHousehold('Persist Inventory Add');
      deps.addDryer();
      await prepareTallSurface(tester);
      await tester.pumpWidget(ModernButlerApp(dependencies: deps));
      await tester.tap(find.byKey(const Key('tools-inventory-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tools-add-screwdriver')));
      await tester.pump();
      expect(deps.householdOwnsTool('screwdriver'), isTrue);
      await deps.flushPersist();

      final restored = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 19, 10, 6),
        store: store,
      );
      await restored.restore();
      expect(restored.householdOwnsTool('screwdriver'), isTrue);

      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(dependencies: restored)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tools-inventory-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('tools-owned-screwdriver')), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laundry Room Dryer'));
      await tester.pumpAndSettle();
      await startRepairFromDetail(tester);
      await dismissProblemStarterIfPresent(tester);
      await selectFailureMode(tester, 'thermal-fuse-open');
      await advanceClosePathFromConclusionIfPresent(tester);
      await completeInspectStepsIfPresent(tester);
      expect(
        find.byKey(const Key('readiness-in-inventory-screwdriver')),
        findsOneWidget,
      );
    },
  );

  testWidgets('owned screwdriver is pre-marked on the repair checklist', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 16));
    deps.createHousehold('Owned Screwdriver');
    deps.addDryer();
    deps.rememberOwnedTool('screwdriver');

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laundry Room Dryer'));
    await tester.pumpAndSettle();
    await startRepairFromDetail(tester);
    await dismissProblemStarterIfPresent(tester);
    await selectFailureMode(tester, 'thermal-fuse-open');
    await advanceClosePathFromConclusionIfPresent(tester);
    await completeInspectStepsIfPresent(tester);

    expect(find.byKey(const Key('repair-readiness-card')), findsOneWidget);
    expect(
      find.byKey(const Key('readiness-in-inventory-screwdriver')),
      findsOneWidget,
    );
    expect(find.text('In your tools'), findsOneWidget);
    expect(find.byKey(const Key('readiness-save-screwdriver')), findsNothing);
    expect(
      find.byKey(const Key('readiness-in-inventory-flashlight')),
      findsNothing,
    );
    expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
    expect(find.textContaining('Open the heater service panel'), findsNothing);
  });

  testWidgets('I don\'t on a required owned tool still gates panel steps', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 17));
    deps.createHousehold('Missing After Owned');
    deps.addWasher();
    deps.rememberOwnedTool('shallow-pan');
    deps.rememberOwnedTool('flashlight');

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laundry Room Washer'));
    await tester.pumpAndSettle();
    await startRepairFromDetail(tester);
    await tapVisible(tester, find.byKey(const Key('answer-choice-won-t-drain')));
    await selectFailureMode(tester, 'clogged-washer-drain-filter');
    await advanceClosePathFromConclusionIfPresent(tester);
    await completeInspectStepsIfPresent(tester);

    expect(find.byKey(const Key('repair-readiness-card')), findsOneWidget);
    await tapVisible(
      tester,
      find.byKey(const Key('readiness-missing-shallow-pan')),
    );

    expect(
      find.byKey(const Key('readiness-missing-critical-panel')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
    expect(find.textContaining('Open only the user-accessible filter'), findsNothing);
    expect(deps.householdOwnsTool('shallow-pan'), isTrue);
  });
}
