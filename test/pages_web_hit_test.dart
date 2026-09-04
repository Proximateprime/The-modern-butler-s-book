import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/product_chrome.dart';

import 'support/session_test_helpers.dart';

String _read(String path) => File(path).readAsStringSync();

bool _starterChipSelected(WidgetTester tester, String id) {
  return find
      .descendant(
        of: find.byKey(Key('starter-chip-$id')),
        matching: find.byIcon(Icons.check_box),
      )
      .evaluate()
      .isNotEmpty;
}

Future<void> _tapPaintedCenter(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  final box = tester.getRect(finder);
  expect(
    box.height,
    lessThan(100),
    reason: 'painted chip/CTA must stay one row, not ~164px / 4 rows',
  );
  await tester.tapAt(box.center);
  await tester.pumpAndSettle();
}

void main() {
  test('version is 0.1.4+13', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+13');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+13'));
  });

  test('Pages host keeps pointer events on flutter-view, not the canvas', () {
    final index = _read('web/index.html');
    expect(index, contains('A household repair book'));
    expect(index, contains('#F3EDE3'));
    expect(index, contains('overflow: hidden'));
    expect(index, contains('flutter-view'));
    expect(index, contains('position: absolute'));
    expect(index, contains('inset: 0'));
    expect(index, contains('pointer-events: none'));
    expect(index, contains("view.focus({ preventScroll: true })"));
    expect(index, contains('bindFlutterPointerHost'));
    expect(index, contains('flutter-first-frame'));
    expect(index, isNot(contains('canvas.focus')));
    expect(index, isNot(contains('developer demo')));
    expect(
      _read('lib/ui/product_chrome.dart'),
      isNot(contains('Transform(')),
    );
    expect(
      _read('lib/ui/product_chrome.dart'),
      contains('class ButlerPageBody'),
    );
    expect(
      _read('lib/ui/session_screen.dart'),
      contains('session-scroll-view'),
    );
  });

  testWidgets(
    'painted Burning smell center selects that chip, not Won\'t start',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 22));
      await openDryerSession(
        tester,
        deps,
        'Pages Hit House',
        skipProblemStarter: false,
      );

      expect(find.text("What's going on?"), findsOneWidget);
      final burning = find.byKey(const Key('starter-chip-hazard-signs'));
      final wontStart = find.byKey(const Key('starter-chip-will-not-start'));
      expect(burning, findsOneWidget);
      expect(wontStart, findsOneWidget);

      final burningBox = tester.getRect(burning);
      final wontBox = tester.getRect(wontStart);
      expect(burningBox.top, greaterThan(wontBox.bottom));
      expect(burningBox.height, lessThan(80));
      expect(wontBox.height, lessThan(80));
      expect(
        burningBox.center.dy - wontBox.center.dy,
        greaterThan(100),
        reason: 'four starter rows sit between Won\'t start and Burning smell',
      );

      await _tapPaintedCenter(tester, burning);
      expect(_starterChipSelected(tester, 'hazard-signs'), isTrue);
      expect(_starterChipSelected(tester, 'will-not-start'), isFalse);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('problem-starter-interpretation')))
            .data,
        contains('Burning smell'),
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('problem-starter-interpretation')))
            .data,
        isNot(contains('Will not start')),
      );
    },
  );

  testWidgets(
    'painted Won\'t start center selects that chip on a 656px Pages pane',
    (tester) async {
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 29, 22, 5),
      );
      await openDryerSession(
        tester,
        deps,
        'Pages Short Hit',
        skipProblemStarter: false,
      );
      tester.view.physicalSize = const Size(800, 656);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('session-scroll-view')), findsOneWidget);
      final wontStart = find.byKey(const Key('starter-chip-will-not-start'));
      await _tapPaintedCenter(tester, wontStart);
      expect(_starterChipSelected(tester, 'will-not-start'), isTrue);
      expect(_starterChipSelected(tester, 'hazard-signs'), isFalse);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('problem-starter-interpretation')))
            .data,
        contains('Will not start'),
      );
    },
  );

  testWidgets(
    '1.25 DPR still maps the painted Burning smell row to that chip',
    (tester) async {
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 29, 22, 10),
      );
      await openDryerSession(
        tester,
        deps,
        'Pages DPR House',
        skipProblemStarter: false,
      );
      tester.view.devicePixelRatio = 1.25;
      tester.view.physicalSize = const Size(800 * 1.25, 656 * 1.25);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsWidgets);
      expect(find.byType(ButlerPageBody), findsWidgets);
      final burning = find.byKey(const Key('starter-chip-hazard-signs'));
      await _tapPaintedCenter(tester, burning);
      expect(_starterChipSelected(tester, 'hazard-signs'), isTrue);
      expect(_starterChipSelected(tester, 'will-not-start'), isFalse);
    },
  );

  testWidgets('painted Home Name this home center opens that dialog', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 22, 15));
    await prepareShortViewport(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    final nameHome = find.byKey(const Key('create-household-button'));
    expect(nameHome, findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(ButlerPageBody), findsOneWidget);
    await _tapPaintedCenter(tester, nameHome);
    expect(find.byKey(const Key('household-name-field')), findsOneWidget);
    expect(find.text(UserFacingCopy.createHouseholdAction), findsWidgets);
  });

  testWidgets('painted Load sample home center loads the sample, not Name this home', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 22, 20));
    await prepareShortViewport(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    final sample = find.byKey(const Key('load-sample-home-button'));
    final nameHome = find.byKey(const Key('create-household-button'));
    expect(tester.getRect(sample).top, greaterThan(tester.getRect(nameHome).bottom));
    await _tapPaintedCenter(tester, sample);
    expect(find.byKey(const Key('household-name-field')), findsNothing);
    expect(find.byKey(const Key('create-household-button')), findsNothing);
    expect(deps.currentHousehold, isNotNull);
  });
}
