import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/clue_copy.dart';
import 'package:modern_butlers_book/helpers/guidance_display.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/knowledge_factory/dryer_inspect_steps.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('version is 0.1.4+22', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+22');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+22'));
  });

  test('empty identity is Unknown, never a demo plate factory', () {
    expect(householdApplianceIdentity(''), kUnknownApplianceIdentity);
    expect(householdApplianceIdentity('  '), kUnknownApplianceIdentity);
    expect(householdApplianceIdentity('Maytag'), 'Maytag');
    expect(_read('lib/ui/app_dependencies.dart'),
        contains('_addHouseholdAppliance'));
    expect(_read('lib/ui/app_dependencies.dart'),
        isNot(contains('_addDemoAppliance')));
    expect(
      _read('lib/ui/app_dependencies.dart'),
      isNot(contains("'Demo Manufacturer'")),
    );
    expect(
        _read('lib/ui/app_dependencies.dart'), isNot(contains('DEMO-DRYER')));
  });

  test('one household clues label', () {
    expect(householdClueSummary(0), 'No clues yet');
    expect(householdClueSummary(1), '1 clue');
    expect(householdClueSummary(3), '3 clues');
    expect(UserFacingCopy.cluesListTitle, 'Clues');
  });

  test('energy Not sure copy does not overclaim heat checks', () {
    expect(UserFacingCopy.addApplianceEnergyHint.toLowerCase(),
        contains('not sure'));
    expect(
      UserFacingCopy.addApplianceEnergyHint.toLowerCase(),
      isNot(contains('needed before')),
    );
  });

  test('gas how-to has no gas-line inspect steps', () {
    final block = observationGuidanceForTemplate('gas-dryer-type')!;
    final how = block.how.toLowerCase();
    expect(how, contains('do not'));
    expect(how, contains('gas lines'));
    expect(how, isNot(contains('check the back of the dryer')));
    expect(how, isNot(contains('have a gas line')));
    expect(how, contains('not sure'));
  });

  test('drum-turns how-to keeps unplug before reach-in', () {
    final block = observationGuidanceForTemplate('drum-turns')!;
    final how = block.how.toLowerCase();
    expect(how, contains('closed door'));
    expect(how, contains('unplug'));
    expect(how, isNot(contains('or opening')));
    expect(block.whenToStop.toLowerCase(), contains('unplug'));
    expect(block.whenToStop.toLowerCase(), contains('reach'));
  });

  test("What's going on helper is observations, not a diagnosis", () {
    expect(UserFacingCopy.problemStarterHelper.toLowerCase(),
        contains('observations'));
    expect(UserFacingCopy.problemStarterHelper.toLowerCase(),
        contains('not a diagnosis'));
    final session = _read('lib/ui/session_screen.dart');
    expect(session, contains('Observations selected'));
    expect(session, isNot(contains("'Interpreted as'")));
  });

  test(
      'Pages/desktop copy honesty: no voice claim, Not OK does not fight Can\'t see',
      () {
    final session = _read('lib/ui/session_screen.dart');
    expect(session, contains('!kIsWeb'));
    expect(session, contains('voiceUnavailableHint'));
    expect(UserFacingCopy.inspectNotOkLooksLike, "Doesn't match looks like");
    expect(UserFacingCopy.inspectNotOkLooksLike.toLowerCase(),
        isNot(contains('not ok')));
    expect(dryerLintFilterInspectStep.notOkMeans.toLowerCase(),
        isNot(contains('cannot see')));
    expect(dryerLintFilterInspectStep.lookFor.toLowerCase(),
        isNot(contains('cannot see')));
    expect(_read('lib/ui/product_chrome.dart'), isNot(contains('Transform(')));
    expect(_read('web/index.html'), contains('bindFlutterPointerHost'));
  });

  testWidgets('empty brand and model Save stores Unknown, not DEMO',
      (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 2));
    deps.createHousehold('Empty Plate House');
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('add-dryer-button')));
    await tester.pumpAndSettle();
    await confirmAddAppliance(tester);

    final dryer = deps.appliancesForCurrentHousehold().single;
    expect(dryer.manufacturer, kUnknownApplianceIdentity);
    expect(dryer.modelNumber, kUnknownApplianceIdentity);
    expect(dryer.manufacturer.toLowerCase(), isNot(contains('demo')));
    expect(dryer.modelNumber.toUpperCase(), isNot(contains('DEMO-')));
  });

  testWidgets('add-appliance short pane scrolls to Energy and Save',
      (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 2, 5));
    deps.createHousehold('Short Add House');
    await prepareShortViewport(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('add-dryer-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-appliance-scroll-view')), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('add-appliance-scroll-view')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    final save = find.byKey(const Key('add-appliance-save-button'));
    expect(save, findsOneWidget);
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    expect(save.hitTestable(), findsOneWidget);
    expect(
        find.byKey(const Key('add-appliance-energy-unknown')), findsOneWidget);
    expect(find.text(UserFacingCopy.addApplianceEnergyHint), findsOneWidget);
  });

  testWidgets('session shows one clues count, not Evidence count vs history', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 2, 10));
    await openDryerSession(tester, deps, 'Clues Count House');

    expect(find.text('Evidence count: 0'), findsNothing);
    expect(find.textContaining('Evidence history ('), findsNothing);
    expect(find.text('No clues yet'), findsWidgets);
    expect(find.text(UserFacingCopy.cluesListTitle), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('context-evidence-count'))).data,
      'No clues yet',
    );

    await selectObservation(tester, 'heat-observed');
    await tapVisible(tester, find.byKey(const Key('answer-choice-no-warmth')));

    expect(find.text('1 clue'), findsWidgets);
    expect(find.text('Evidence count: 1'), findsNothing);
    expect(find.textContaining('Evidence history ('), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('context-evidence-count'))).data,
      '1 clue',
    );
  });

  testWidgets('Skip to best guess hides with zero clues and shows after one', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 2, 15));
    await openDryerSession(tester, deps, 'Skip Gate House');
    expect(find.byKey(const Key('skip-to-best-guess')), findsNothing);

    await selectObservation(tester, 'heat-observed');
    await tapVisible(tester, find.byKey(const Key('answer-choice-no-warmth')));
    expect(find.byKey(const Key('skip-to-best-guess')), findsOneWidget);
  });

  testWidgets(
    'Already checked hides on a first session with no history',
    (tester) async {
      final first =
          AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 2, 20));
      await openDryerSession(
        tester,
        first,
        'First Session House',
        skipProblemStarter: false,
      );
      await confirmNoHeatStarter(tester);
      await answerObservation(tester, 'drum-turns', 'turns-normally');
      expect(find.text('Already checked'), findsNothing);
      expect(
          find.byKey(const Key('inspect-chip-already-checked')), findsNothing);
      expect(find.text("Can't see"), findsOneWidget);
    },
  );

  testWidgets(
    'Already checked shows when this appliance has completed history',
    (tester) async {
      final withHistory =
          AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 2, 25));
      await openDryerSession(
        tester,
        withHistory,
        'History Session House',
        skipProblemStarter: false,
        priorRepairHistory: true,
      );
      await confirmNoHeatStarter(tester);
      await answerObservation(tester, 'drum-turns', 'turns-normally');
      expect(
        find.byKey(const Key('inspect-chip-already-checked')),
        findsOneWidget,
      );
      expect(find.text('Already checked'), findsOneWidget);
      expect(find.text("Can't see"), findsOneWidget);
    },
  );

  testWidgets("What's going on stays observation voice", (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 2, 30));
    await openDryerSession(
      tester,
      deps,
      'Starter Voice House',
      skipProblemStarter: false,
    );
    expect(find.text("What's going on?"), findsOneWidget);
    expect(find.text(UserFacingCopy.problemStarterHelper), findsWidgets);
    await tester.tap(find.byKey(const Key('starter-chip-no-heat')));
    await tester.pumpAndSettle();
    expect(find.text('Observations selected'), findsOneWidget);
    expect(find.text('Interpreted as'), findsNothing);
  });

  test('Skip on What Butler does uses first-pointer hit-target, not autofocus',
      () {
    final firstRun = _read('lib/ui/first_run_screen.dart');
    expect(firstRun, contains('onPointerDown'));
    expect(firstRun, contains('canRequestFocus: false'));
    expect(firstRun, contains('minHeight: 48'));
    expect(firstRun, isNot(contains('autofocus: true')));
    expect(firstRun, isNot(contains('requestFocus()')));
    expect(firstRun, isNot(contains('Transform(')));
    expect(_read('web/index.html'), contains('bindFlutterPointerHost'));
    expect(_read('lib/ui/product_chrome.dart'), isNot(contains('Transform(')));
  });

  testWidgets(
    'Skip from What Butler does leaves first-run on the first tap',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 9, 4, 2, 40),
        firstRunComplete: false,
        disclaimerAcknowledged: false,
      );
      await prepareTallSurface(tester);
      await tester.pumpWidget(ModernButlerApp(dependencies: deps));

      expect(find.byKey(const Key('first-run-page-what')), findsOneWidget);
      expect(find.text(UserFacingCopy.firstRunDoesTitle), findsOneWidget);

      final skip = find.byKey(const Key('first-run-skip-button'));
      expect(skip.hitTestable(), findsOneWidget);
      final skipBox = tester.getRect(skip);
      expect(skipBox.height, greaterThanOrEqualTo(48));

      await tester.tapAt(skipBox.center);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('first-run-page-what')), findsNothing);
      expect(find.byKey(const Key('first-run-page-not')), findsNothing);
      expect(find.byKey(const Key('first-run-screen')), findsNothing);
      expect(find.byKey(const Key('safety-disclaimer-screen')), findsOneWidget);
      expect(deps.firstRunComplete, isTrue);
      expect(deps.disclaimerAcknowledged, isFalse);
    },
  );

  testWidgets(
    'Skip from What Butler does still completes on the first tap after splash',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 9, 4, 2, 45),
        firstRunComplete: false,
        disclaimerAcknowledged: false,
      );
      await prepareShortViewport(tester);
      await tester.pumpWidget(
        ModernButlerApp(dependencies: deps, forceBrandSplash: true),
      );
      await tester.pump();
      expect(find.byKey(const Key('splash-screen')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 950));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('first-run-page-what')), findsOneWidget);
      expect(find.text(UserFacingCopy.firstRunDoesTitle), findsOneWidget);

      final skip = find.byKey(const Key('first-run-skip-button'));
      expect(skip.hitTestable(), findsOneWidget);
      await tester.tapAt(tester.getRect(skip).center);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('first-run-screen')), findsNothing);
      expect(find.byKey(const Key('first-run-page-not')), findsNothing);
      expect(find.byKey(const Key('safety-disclaimer-screen')), findsOneWidget);
      expect(deps.firstRunComplete, isTrue);
    },
  );
}
