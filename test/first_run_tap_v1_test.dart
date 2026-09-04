import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/primary_cta.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

String _read(String path) => File(path).readAsStringSync();

Finder _firstRunBodySafeArea() {
  return find.descendant(
    of: find.byKey(const Key('first-run-screen')),
    matching: find.byWidgetPredicate(
      (widget) => widget is SafeArea && widget.top == false && widget.bottom,
    ),
  );
}

void main() {
  test('version is 0.1.4+16', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+16');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+16'));
  });

  test('first-run tree has no Transform and Pages pointer host stays locked',
      () {
    final firstRun = _read('lib/ui/first_run_screen.dart');
    expect(firstRun, isNot(contains('Transform(')));
    expect(firstRun, isNot(contains('Transform.')));
    expect(firstRun, contains('SafeArea'));
    expect(firstRun, contains('first-run-next-button'));
    expect(firstRun, contains('first-run-done-button'));
    expect(firstRun, contains('minHeight: 48'));
    expect(firstRun, contains('onPointerDown'));
    expect(firstRun, contains('canRequestFocus: false'));
    expect(firstRun, isNot(contains('autofocus: true')));
    expect(firstRun, isNot(contains('requestFocus()')));

    final index = _read('web/index.html');
    expect(index, contains('overflow: hidden'));
    expect(index, contains('pointer-events: none'));
    expect(index, contains("view.focus({ preventScroll: true })"));
    expect(index, contains('bindFlutterPointerHost'));
    expect(index, contains('flutter-first-frame'));
    expect(index, isNot(contains('canvas.focus')));

    expect(_read('lib/ui/product_chrome.dart'), isNot(contains('Transform(')));
  });

  testWidgets('whole-screen tap advances; Skip stays a separate first tap', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 1),
      firstRunComplete: false,
    );
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    expect(find.byKey(const Key('first-run-screen')), findsOneWidget);
    expect(find.byKey(const Key('first-run-page-what')), findsOneWidget);
    expect(find.byType(PrimaryCta), findsNothing);
    expect(find.text(UserFacingCopy.firstRunContinue), findsNothing);
    expect(find.text('Get started'), findsNothing);

    final skip = tester.getRect(find.byKey(const Key('first-run-skip-button')));
    expect(skip.height, greaterThanOrEqualTo(48));

    final screen = tester.getRect(find.byKey(const Key('first-run-screen')));
    await tester.tapAt(Offset(screen.center.dx, screen.center.dy));
    await tester.pump();

    expect(find.byKey(const Key('first-run-page-not')), findsOneWidget);
    expect(find.byKey(const Key('first-run-page-what')), findsNothing);

    await tester.tap(find.text(UserFacingCopy.firstRunDoesNotTitle));
    await tester.pump();

    expect(find.byKey(const Key('first-run-page-privacy')), findsOneWidget);
    expect(find.byKey(const Key('first-run-done-button')), findsOneWidget);
    expect(find.byKey(const Key('first-run-next-button')), findsNothing);
  });

  testWidgets('first-run-next-button key still advances without a bottom CTA', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 1, 5),
      firstRunComplete: false,
    );
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    await tester.tap(find.byKey(const Key('first-run-next-button')));
    await tester.pump();
    expect(find.byKey(const Key('first-run-page-not')), findsOneWidget);

    await tester.tap(find.byKey(const Key('first-run-next-button')));
    await tester.pump();
    expect(find.byKey(const Key('first-run-page-privacy')), findsOneWidget);
  });

  testWidgets('Skip first tap still works after splash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 1, 10),
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
    final skipBox = tester.getRect(skip);
    expect(skipBox.height, greaterThanOrEqualTo(48));
    await tester.tap(skip);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-run-screen')), findsNothing);
    expect(find.byKey(const Key('safety-disclaimer-screen')), findsOneWidget);
    expect(deps.firstRunComplete, isTrue);
  });

  testWidgets('Skip cannot bypass the I understand acknowledgment', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 1, 15),
      firstRunComplete: false,
      disclaimerAcknowledged: false,
    );
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    await tester.tap(find.byKey(const Key('first-run-skip-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-run-screen')), findsNothing);
    expect(find.byKey(const Key('safety-disclaimer-screen')), findsOneWidget);
    expect(
        find.byKey(const Key('safety-disclaimer-acknowledge')), findsOneWidget);
    expect(
        find.text(UserFacingCopy.safetyDisclaimerAcknowledge), findsOneWidget);
    expect(find.byKey(const Key('create-household-button')), findsNothing);
    expect(deps.disclaimerAcknowledged, isFalse);

    await tester.tap(find.byKey(const Key('safety-disclaimer-screen')));
    await tester.pump();
    expect(find.byKey(const Key('safety-disclaimer-screen')), findsOneWidget);
    expect(deps.disclaimerAcknowledged, isFalse);

    await tester.tap(find.byKey(const Key('safety-disclaimer-acknowledge')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('safety-disclaimer-screen')), findsNothing);
    expect(find.byKey(const Key('create-household-button')), findsOneWidget);
    expect(deps.disclaimerAcknowledged, isTrue);
  });

  testWidgets(
      'last-page tap finishes first-run then still requires I understand', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 1, 20),
      firstRunComplete: false,
      disclaimerAcknowledged: false,
    );
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    await tester.tap(find.byKey(const Key('first-run-next-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('first-run-next-button')));
    await tester.pump();
    expect(find.byKey(const Key('first-run-page-privacy')), findsOneWidget);

    await tester.tap(find.byKey(const Key('first-run-done-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-run-screen')), findsNothing);
    expect(find.byKey(const Key('safety-disclaimer-screen')), findsOneWidget);
    expect(deps.firstRunComplete, isTrue);
    expect(deps.disclaimerAcknowledged, isFalse);
  });

  testWidgets('SafeArea keeps first-run content above a system nav inset', (
    tester,
  ) async {
    const bottomInset = 48.0;
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 1, 25),
      firstRunComplete: false,
    );
    await prepareTallSurface(tester);
    tester.view.padding = const FakeViewPadding(
      left: 0,
      top: 24,
      right: 0,
      bottom: bottomInset,
    );
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.pump();

    expect(_firstRunBodySafeArea(), findsOneWidget);
    final safeArea = tester.widget<SafeArea>(_firstRunBodySafeArea());
    expect(safeArea.bottom, isTrue);
    expect(safeArea.top, isFalse);

    final viewHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final advance =
        tester.getRect(find.byKey(const Key('first-run-next-button')));
    expect(
      advance.bottom,
      lessThanOrEqualTo(viewHeight - bottomInset + 0.5),
      reason: 'advance hit target must sit above the system nav inset',
    );
    final page = tester.getRect(find.byKey(const Key('first-run-page-what')));
    expect(page.bottom, lessThanOrEqualTo(advance.bottom + 0.5));
  });

  testWidgets(
      'advance hit target matches painted first-run body, not a Transform', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 1, 30),
      firstRunComplete: false,
    );
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    final firstRunSource = _read('lib/ui/first_run_screen.dart');
    expect(firstRunSource, isNot(contains('Transform(')));
    expect(firstRunSource, isNot(contains('Matrix4')));

    final next = find.byKey(const Key('first-run-next-button'));
    final box = tester.getRect(next);
    expect(box.height, greaterThan(200),
        reason: 'advance target is the body, not a bottom strip');

    final paintedTitle =
        tester.getRect(find.text(UserFacingCopy.firstRunDoesTitle));
    expect(box.contains(paintedTitle.center), isTrue);

    await tester.tapAt(paintedTitle.center);
    await tester.pump();
    expect(find.byKey(const Key('first-run-page-not')), findsOneWidget);
  });
}
