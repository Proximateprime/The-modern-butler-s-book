import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/repair_log_share.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/primary_cta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('version is 0.1.4+14', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+14');
  });

  test('first-run greeting uses book theme type, not a bare Georgia family', () {
    final source = File('lib/ui/first_run_screen.dart').readAsStringSync();
    expect(source, isNot(contains("fontFamily: 'Georgia'")));
    expect(source, contains('text.headlineSmall'));
    expect(source, contains('UserFacingCopy.firstRunGreeting'));
    expect(UserFacingCopy.firstRunDoesBody, isNot(contains('premium add-on')));
    expect(UserFacingCopy.firstRunDoesBody, contains('House Book'));
    expect(UserFacingCopy.firstRunDoesBody, contains('this device'));
    expect(UserFacingCopy.firstRunPrivacyBody, contains('on this device'));
    expect(UserFacingCopy.firstRunPrivacyBody, contains('Diagnosis stays'));
    expect(UserFacingCopy.firstRunPrivacyBody, isNot(contains('Groq')));
    expect(UserFacingCopy.firstRunPrivacyBody, isNot(contains('butler backend')));
    expect(UserFacingCopy.firstRunPrivacyBody, isNot(contains('cloud account')));
    expect(
      UserFacingCopy.firstRunPrivacyBody,
      isNot(contains('Nothing is uploaded')),
    );
    expect(UserFacingCopy.privacyPhrasingBackend, contains('Groq'));
    expect(UserFacingCopy.privacyPhrasingBackend, contains('butler'));
    expect(UserFacingCopy.privacyLocalFirst, contains('on this device'));
    expect(
      UserFacingCopy.privacyLocalFirst,
      isNot(contains('Nothing is uploaded')),
    );
  });

  test('Pages source chrome is a household book, not a developer demo', () {
    final index = File('web/index.html').readAsStringSync();
    final manifest = File('web/manifest.json').readAsStringSync();
    expect(index, isNot(contains('developer demo')));
    expect(index, isNot(contains('#3F51B5')));
    expect(index, contains('A household repair book'));
    expect(index, contains('#F3EDE3'));
    expect(manifest, isNot(contains('developer demo')));
    expect(manifest, isNot(contains('#3F51B5')));
    expect(manifest, contains('A household repair book'));
    expect(manifest, contains('#F3EDE3'));
  });

  testWidgets(
    'first-run is a greeting without page-counter chrome',
    (tester) async {
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 29, 21),
        firstRunComplete: false,
      );
      await prepareTallSurface(tester);
      await tester.pumpWidget(ModernButlerApp(dependencies: deps));

      expect(find.byKey(const Key('first-run-screen')), findsOneWidget);
      expect(find.byKey(const Key('first-run-skip-button')), findsOneWidget);
      expect(find.text(UserFacingCopy.firstRunGreeting), findsOneWidget);
      final greeting = tester.widget<Text>(
        find.text(UserFacingCopy.firstRunGreeting),
      );
      final bookType = Theme.of(
        tester.element(find.byKey(const Key('first-run-screen'))),
      ).textTheme.headlineSmall;
      expect(greeting.style, bookType);
      expect(greeting.style?.fontFamily, isNot('Georgia'));
      expect(find.byKey(const Key('first-run-page-what')), findsOneWidget);
      expect(find.text(UserFacingCopy.firstRunDoesTitle), findsOneWidget);
      expect(find.byKey(const Key('first-run-progress')), findsNothing);
      expect(find.text('1 of 3'), findsNothing);
      expect(find.text('Next'), findsNothing);

      await tester.tap(find.byKey(const Key('first-run-next-button')));
      await tester.pump();
      expect(find.byKey(const Key('first-run-page-not')), findsOneWidget);
      expect(find.text(UserFacingCopy.firstRunDoesNotTitle), findsOneWidget);
      expect(find.text('2 of 3'), findsNothing);

      await tester.tap(find.byKey(const Key('first-run-next-button')));
      await tester.pump();
      expect(find.byKey(const Key('first-run-page-privacy')), findsOneWidget);
      expect(find.text(UserFacingCopy.firstRunPrivacyTitle), findsOneWidget);
      expect(find.byKey(const Key('first-run-done-button')), findsOneWidget);
      expect(find.text('3 of 3'), findsNothing);
    },
  );

  testWidgets('first-run Skip still completes on the first tap', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 29, 21, 5),
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

    final skip = find.byKey(const Key('first-run-skip-button'));
    expect(skip.hitTestable(), findsOneWidget);
    await tester.tap(skip);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-run-screen')), findsNothing);
    expect(find.byKey(const Key('safety-disclaimer-screen')), findsOneWidget);
    expect(deps.firstRunComplete, isTrue);
  });

  testWidgets('empty home speaks in household voice', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 21, 10));
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    expect(find.byKey(const Key('create-household-button')), findsOneWidget);
    expect(find.byKey(const Key('empty-home-create-household')), findsNothing);
    expect(find.byKey(const Key('empty-home-load-sample')), findsNothing);
    expect(find.byKey(const Key('load-sample-home-button')), findsOneWidget);
    expect(find.byKey(const Key('empty-home-appliances')), findsNothing);
    expect(find.byKey(const Key('export-inventory-button')), findsNothing);
    expect(find.byKey(const Key('household-name')), findsOneWidget);
    expect(find.text(UserFacingCopy.createHouseholdAction), findsOneWidget);
    expect(find.text('Load sample home'), findsOneWidget);
    expect(find.text(UserFacingCopy.emptyHomeNoHousehold), findsOneWidget);
    expect(find.text(UserFacingCopy.noDryersYet), findsNothing);
    expect(find.text('Create Household'), findsNothing);
    expect(find.text('Choose an appliance to start or continue a repair.'), findsNothing);

    await tester.tap(find.byKey(const Key('create-household-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('household-name-field')),
      'Town House',
    );
    await tester.tap(find.byKey(const Key('confirm-household-button')));
    await tester.pumpAndSettle();

    expect(find.text(UserFacingCopy.emptyHomeNoDryer), findsOneWidget);
    expect(find.text(UserFacingCopy.noDryersYet), findsOneWidget);
    expect(find.byKey(const Key('empty-home-appliances')), findsOneWidget);
    expect(find.text('Choose an appliance to start or continue a repair.'), findsNothing);

    await tester.tap(find.byKey(const Key('add-dryer-button')));
    await tester.pumpAndSettle();
    await confirmAddAppliance(tester);

    expect(find.text(UserFacingCopy.emptyHomeHasAppliances), findsOneWidget);
    expect(find.text('Choose an appliance to start or continue a repair.'), findsNothing);
    expect(find.byKey(const Key('household-name')), findsOneWidget);
  });

  testWidgets(
    'pro handoff uses book chrome and keeps share/copy keys',
    (tester) async {
      late List<String> shared;
      late List<String> copied;
      shared = <String>[];
      copied = <String>[];
      repairLogShareHandler = (text) async {
        shared.add(text);
      };
      repairLogCopyHandler = (text) async {
        copied.add(text);
      };
      addTearDown(() {
        repairLogShareHandler = shareRepairLogViaSystem;
        repairLogCopyHandler = copyRepairLogToClipboard;
      });

      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 21, 15));
      await openDryerSession(tester, deps, 'Handoff House');

      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );
      await selectFailureMode(tester, 'heating-element-failed');
      await reachClosePathVerificationIfPresent(tester);
      await tapVisible(tester, find.byKey(const Key('pro-handoff-understand')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('outcome-needs-professional')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('outcome-note-field')),
        'Calling Monday',
      );
      await tester.tap(find.byKey(const Key('outcome-save-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pro-handoff-screen')), findsOneWidget);
      expect(find.text(UserFacingCopy.proHandoffLead), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Technician handoff'),
        ),
        findsNothing,
      );
      expect(find.byType(PrimaryCta), findsWidgets);
      expect(find.byKey(const Key('pro-handoff-preview')), findsOneWidget);
      expect(find.byKey(const Key('pro-handoff-share')), findsOneWidget);
      expect(find.byKey(const Key('pro-handoff-copy')), findsOneWidget);
      expect(find.byKey(const Key('completion-save-home')), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('pro-handoff-share')));
      expect(shared, hasLength(1));
      expect(shared.single, contains('Technician handoff'));
      await tapVisible(tester, find.byKey(const Key('pro-handoff-copy')));
      expect(copied, hasLength(1));
    },
  );
}
