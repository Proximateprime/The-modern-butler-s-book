import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets('first run skip still requires a one-time disclaimer', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 8),
      store: store,
      firstRunComplete: false,
      disclaimerAcknowledged: false,
    );

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('first-run-skip-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safety-disclaimer-screen')), findsOneWidget);
    expect(find.text(UserFacingCopy.safetyDisclaimerTitle), findsWidgets);
    expect(find.textContaining('not a substitute'), findsOneWidget);
    expect(find.textContaining('gas'), findsOneWidget);
    expect(find.textContaining('isolating power'), findsOneWidget);
    expect(find.byKey(const Key('create-household-button')), findsNothing);

    await tester.tap(find.byKey(const Key('safety-disclaimer-acknowledge')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safety-disclaimer-screen')), findsNothing);
    expect(find.byKey(const Key('create-household-button')), findsOneWidget);
    expect(deps.disclaimerAcknowledged, isTrue);
    expect(await store.loadDisclaimerAcknowledged(), isTrue);
  });

  testWidgets('disclaimer persists and is not shown again', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final first = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 8),
      store: store,
      firstRunComplete: true,
      disclaimerAcknowledged: false,
    );

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: first));
    expect(find.byKey(const Key('safety-disclaimer-screen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('safety-disclaimer-acknowledge')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('create-household-button')), findsOneWidget);

    final second = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 8),
      store: store,
      firstRunComplete: true,
      disclaimerAcknowledged: await store.loadDisclaimerAcknowledged(),
    );
    await tester.pumpWidget(ModernButlerApp(dependencies: second));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('safety-disclaimer-screen')), findsNothing);
    expect(find.byKey(const Key('create-household-button')), findsOneWidget);
  });

  testWidgets('first repair is blocked until the disclaimer is acknowledged', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 8),
      firstRunComplete: true,
      disclaimerAcknowledged: false,
    );
    deps.createHousehold('Disclaimer House');
    final dryer = deps.addDryer();

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();
    await startRepairFromDetail(tester);

    expect(find.byKey(const Key('safety-disclaimer-screen')), findsOneWidget);
    expect(find.byKey(const Key('problem-starter-panel')), findsNothing);

    await tester.tap(find.byKey(const Key('safety-disclaimer-acknowledge')));
    await tester.pumpAndSettle();
    expect(deps.disclaimerAcknowledged, isTrue);
    expect(find.byKey(const Key('problem-starter-panel')), findsOneWidget);
  });

  testWidgets('settings can re-read the disclaimer', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 8));
    deps.createHousehold('Reread House');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const Key('settings-safety-disclaimer')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safety-disclaimer-screen')), findsOneWidget);
    expect(find.byKey(const Key('safety-disclaimer-close')), findsOneWidget);
    expect(find.byKey(const Key('safety-disclaimer-acknowledge')), findsNothing);
    await tester.tap(find.byKey(const Key('safety-disclaimer-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-screen')), findsOneWidget);
  });

  testWidgets('acknowledging the disclaimer does not skip hazard hard-stop', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 8));
    await openDryerSession(tester, deps, 'Disclaimer Hazard');
    await selectObservation(tester, 'hazard-observation');
    await tapVisible(tester, find.byKey(const Key('answer-choice-yes')));
    expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
  });
}
