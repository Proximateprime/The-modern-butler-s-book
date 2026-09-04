import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/helpers/repair_readiness.dart';
import 'package:modern_butlers_book/knowledge_factory/failure_mode_authoring_registry.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';

import 'support/session_test_helpers.dart';

void main() {
  group('readinessItemsFromToolsRequired', () {
    test('skips placeholder none/pro-only lines', () {
      final items = readinessItemsFromToolsRequired(const [
        'None for beginner exterior/lint checks',
        'Cabinet tools only for pros',
        'Settings/unlock only — no tools or wiring',
      ]);
      expect(items, isEmpty);
    });

    test('parses flashlight as optional on thermal-fuse beginner tools', () {
      final items = readinessItemsFromToolsRequired(
        FailureModeAuthoringRegistry.toolsRequiredFor('thermal-fuse-open'),
      );
      expect(items.map((item) => item.id).toSet(), {'screwdriver', 'flashlight'});
      expect(items.every((item) => item.optional), isTrue);
    });

    test('washer drain-filter pan is required and flashlight is optional', () {
      final items = readinessItemsFromToolsRequired(
        FailureModeAuthoringRegistry.toolsRequiredFor(
          'clogged-washer-drain-filter',
        ),
      );
      expect(items.map((item) => item.id), ['shallow-pan', 'flashlight']);
      expect(items.first.isCritical, isTrue);
      expect(items.last.optional, isTrue);
      expect(
        missingRequiredTools(
          items: items,
          haveByToolId: const {
            'shallow-pan': true,
            'flashlight': false,
          },
        ),
        isEmpty,
      );
    });

    test('live electrical missing tools block continue-with-caution', () {
      final items = readinessItemsFromToolsRequired(const [
        'Multimeter',
        'Screwdriver',
      ]);
      final missingMeter = items.where((item) => item.id == 'multimeter');
      expect(allowContinueWithCaution(missingMeter), isFalse);
      final missingDriver = items.where((item) => item.id == 'screwdriver');
      expect(allowContinueWithCaution(missingDriver), isTrue);
    });
  });

  testWidgets('fuse-path guidance shows checklist before steps', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 15));
    await openDryerSession(tester, deps, 'Readiness Household');
    await selectFailureMode(tester, 'thermal-fuse-open');

    await advanceClosePathFromConclusionIfPresent(tester);
    expect(
      find.byKey(const Key('inspect-step-card-inspect-lint-filter')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('repair-readiness-card')), findsNothing);
    await completeInspectStepsIfPresent(tester);
    expect(find.byKey(const Key('repair-readiness-card')), findsOneWidget);
    expect(find.byKey(const Key('readiness-tool-screwdriver')), findsOneWidget);
    expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
    expect(find.textContaining('Unplug the dryer'), findsNothing);

    await tapVisible(
      tester,
      find.byKey(const Key('readiness-have-screwdriver')),
    );
    expect(find.byKey(const Key('readiness-save-screwdriver')), findsOneWidget);
    expect(deps.householdOwnsTool('screwdriver'), isFalse);

    await tapVisible(
      tester,
      find.byKey(const Key('readiness-have-flashlight')),
    );
    expect(find.byKey(const Key('readiness-save-screwdriver')), findsOneWidget);
    expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
    await tapVisible(tester, find.byKey(const Key('close-path-tools-continue')));
    await acknowledgeProScopeIfPresent(tester);

    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    expect(find.textContaining('Open the heater service panel'), findsNothing);
    expect(deps.householdOwnsTool('screwdriver'), isFalse);
  });

  testWidgets('missing critical tool offers stop, call pro, and caution', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 16));
    await openWasherSession(tester, deps, 'Missing Tool Household');
    await tapVisible(tester, find.byKey(const Key('answer-choice-won-t-drain')));
    await selectFailureMode(tester, 'clogged-washer-drain-filter');

    await advanceClosePathFromConclusionIfPresent(tester);
    await completeInspectStepsIfPresent(tester);
    await tapVisible(
      tester,
      find.byKey(const Key('readiness-missing-shallow-pan')),
    );
    await tapVisible(
      tester,
      find.byKey(const Key('readiness-have-flashlight')),
    );

    expect(
      find.byKey(const Key('readiness-missing-critical-panel')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('blocking-reason-line')), findsOneWidget);
    expect(
      find.text('You need a shallow pan and towel for the next steps.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('next-action-cue')), findsNothing);
    expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
    expect(find.byKey(const Key('readiness-stop')), findsOneWidget);
    expect(find.byKey(const Key('readiness-call-pro')), findsOneWidget);
    expect(find.byKey(const Key('readiness-continue-caution')), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('readiness-continue-caution')));

    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    expect(find.textContaining('Open only the user-accessible filter'), findsNothing);
  });

  testWidgets('missing tool line clears after I have', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 13));
    await openWasherSession(tester, deps, 'Tool Line Clears');
    await tapVisible(tester, find.byKey(const Key('answer-choice-won-t-drain')));
    await selectFailureMode(tester, 'clogged-washer-drain-filter');
    await advanceClosePathFromConclusionIfPresent(tester);
    await completeInspectStepsIfPresent(tester);
    await tapVisible(
      tester,
      find.byKey(const Key('readiness-missing-shallow-pan')),
    );
    await tapVisible(
      tester,
      find.byKey(const Key('readiness-have-flashlight')),
    );
    expect(
      find.text('You need a shallow pan and towel for the next steps.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('next-action-cue')), findsNothing);

    await tapVisible(
      tester,
      find.byKey(const Key('readiness-have-shallow-pan')),
    );
    expect(find.byKey(const Key('blocking-reason-line')), findsNothing);
    expect(
      find.text('You need a shallow pan and towel for the next steps.'),
      findsNothing,
    );
    expect(find.byKey(const Key('readiness-missing-critical-panel')), findsNothing);
    expect(find.byKey(const Key('close-path-tools-continue')), findsOneWidget);
  });

  testWidgets('optional flashlight I don\'t does not block fuse panel steps', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 18));
    await openDryerSession(tester, deps, 'Optional Flashlight');
    await selectFailureMode(tester, 'thermal-fuse-open');
    await advanceClosePathFromConclusionIfPresent(tester);
    await completeClosePathInspectThenPartsIfPresent(tester);
    await tapVisible(
      tester,
      find.byKey(const Key('readiness-have-screwdriver')),
    );
    await tapVisible(
      tester,
      find.byKey(const Key('readiness-missing-flashlight')),
    );
    expect(
      find.byKey(const Key('readiness-missing-critical-panel')),
      findsNothing,
    );
    expect(find.byKey(const Key('readiness-save-screwdriver')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('close-path-tools-continue')));
    await acknowledgeProScopeIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    expect(find.byKey(const Key('readiness-missing-critical-panel')), findsNothing);
    expect(find.text('You need a screwdriver for the next steps.'), findsNothing);
    await completeGuidanceStepsIfPresent(tester);
    expect(find.byKey(const Key('pro-recommended-card')), findsNothing);
    expect(find.byKey(const Key('blocking-reason-line')), findsNothing);
  });

  testWidgets('owned pan is pre-marked on washer drain-filter checklist', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 19));
    deps.createHousehold('Owned Pan');
    deps.addWasher();
    deps.rememberOwnedTool('shallow-pan');

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
    expect(
      find.byKey(const Key('readiness-in-inventory-shallow-pan')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('readiness-save-shallow-pan')), findsNothing);
    expect(find.textContaining('Open only the user-accessible filter'), findsNothing);
  });

  testWidgets(
    'removing a required tool from inventory shows missing, adding back clears',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 20));
      deps.createHousehold('Inventory Round Trip');
      final washer = deps.addWasher();
      deps.rememberOwnedTool('shallow-pan');

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

      expect(
        find.byKey(const Key('readiness-in-inventory-shallow-pan')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('readiness-not-in-inventory-shallow-pan')),
        findsNothing,
      );

      await tapVisible(tester, find.byKey(const Key('session-exit-button')));
      deps.forgetOwnedTool('shallow-pan');
      await tester.tap(find.byKey(Key('continue-repair-${washer.id}')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('readiness-in-inventory-shallow-pan')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('readiness-not-in-inventory-shallow-pan')),
        findsOneWidget,
      );

      await tapVisible(tester, find.byKey(const Key('session-exit-button')));
      deps.rememberOwnedTool('shallow-pan');
      await tester.tap(find.byKey(Key('continue-repair-${washer.id}')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('readiness-in-inventory-shallow-pan')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('readiness-not-in-inventory-shallow-pan')),
        findsNothing,
      );
    },
  );

  testWidgets('missing washer pan blocks opening the drain filter', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 20));
    await openWasherSession(tester, deps, 'Missing Pan');
    await tapVisible(tester, find.byKey(const Key('answer-choice-won-t-drain')));
    await selectFailureMode(tester, 'clogged-washer-drain-filter');
    await advanceClosePathFromConclusionIfPresent(tester);
    await completeInspectStepsIfPresent(tester);
    await tapVisible(
      tester,
      find.byKey(const Key('readiness-missing-shallow-pan')),
    );
    await tapVisible(
      tester,
      find.byKey(const Key('readiness-have-flashlight')),
    );

    expect(
      find.byKey(const Key('readiness-missing-critical-panel')),
      findsOneWidget,
    );
    expect(
      find.text('You need a shallow pan and towel for the next steps.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
    expect(find.textContaining('Open only the user-accessible filter'), findsNothing);

    await tapVisible(tester, find.byKey(const Key('readiness-continue-caution')));
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    expect(find.textContaining('Open only the user-accessible filter'), findsNothing);
  });

  testWidgets('missing-tool stop closes the session without a memory duplicate', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 17));
    await openWasherSession(tester, deps, 'Stop Readiness Household');
    await tapVisible(tester, find.byKey(const Key('answer-choice-won-t-drain')));
    await selectFailureMode(tester, 'clogged-washer-drain-filter');

    await advanceClosePathFromConclusionIfPresent(tester);
    await completeInspectStepsIfPresent(tester);
    await tapVisible(
      tester,
      find.byKey(const Key('readiness-missing-shallow-pan')),
    );
    await tapVisible(
      tester,
      find.byKey(const Key('readiness-have-flashlight')),
    );
    await tapVisible(tester, find.byKey(const Key('readiness-stop')));

    final washer = deps.appliancesForCurrentHousehold().single;
    expect(deps.hasInProgressSession(washer), isFalse);
    expect(deps.recentSessionOutcomes(), hasLength(1));
    expect(
      deps.recentSessionOutcomes().single.outcome.closeKind,
      SessionCloseKind.stopped,
    );
  });
}
