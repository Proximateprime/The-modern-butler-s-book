import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/device_online.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('airplane / none is offline; wifi is online', () {
    expect(connectivityMeansOnline(const [ConnectivityResult.none]), isFalse);
    expect(connectivityMeansOnline(const []), isFalse);
    expect(connectivityMeansOnline(const [ConnectivityResult.wifi]), isTrue);
    expect(
      connectivityMeansOnline(const [
        ConnectivityResult.none,
        ConnectivityResult.wifi,
      ]),
      isTrue,
    );
  });

  test('simulate offline hides network without changing guides', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 13));
    expect(deps.isOnline, isTrue);
    expect(deps.hasInstalledPackageFor('dryer'), isTrue);
    deps.simulateOffline = true;
    expect(deps.isOnline, isFalse);
    expect(deps.hasInstalledPackageFor('dryer'), isTrue);
    expect(deps.installBundledPackage('washer'), isTrue);
  });

  testWidgets('offline dryer session still asks questions and is not blank', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 22, 13),
      isOnline: () => false,
    );
    await openDryerSession(
      tester,
      deps,
      'Offline Dryer',
      skipProblemStarter: false,
    );

    expect(find.byKey(const Key('session-offline-banner')), findsOneWidget);
    expect(find.text(UserFacingCopy.offlineGuidesStillWork), findsWidgets);
    expect(find.text("What's going on?"), findsOneWidget);
    expect(find.text('No heat'), findsOneWidget);
    expect(find.textContaining('#0'), findsNothing);
    expect(find.textContaining('Exception:'), findsNothing);
  });

  testWidgets('offline install from this device still works', (tester) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 22, 13, 5),
      isOnline: () => false,
      knowledgePackageRepository: KnowledgePackageRepository(
        initialPackages: const [],
      ),
    );
    deps.createHousehold('Offline Install');
    final fridge = deps.addFridge();

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(Key('appliance-${fridge.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appliance-missing-package')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appliance-install-package')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('package-install-offline')), findsOneWidget);
    expect(find.text(UserFacingCopy.packageInstallHint), findsOneWidget);

    await tester.tap(find.byKey(const Key('package-install-local-button')));
    await tester.pumpAndSettle();
    expect(deps.hasInstalledPackageFor('fridge'), isTrue);
    expect(find.textContaining('#0'), findsNothing);
  });
}
