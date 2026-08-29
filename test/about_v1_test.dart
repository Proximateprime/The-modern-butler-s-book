import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/knowledge_package_catalog.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

Future<void> _openAbout(WidgetTester tester, AppDependencies deps) async {
  await prepareTallSurface(tester);
  await tester.pumpWidget(ModernButlerApp(dependencies: deps));
  await tester.tap(find.byKey(const Key('home-settings-button')));
  await tester.pumpAndSettle();
  await scrollSettingsUntil(tester, const Key('settings-version-badge'));
  await tapVisible(tester, find.byKey(const Key('settings-version-badge')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('About v1 shows version, installed guides, and core one-liner', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 13));
    deps.createHousehold('About House');

    await _openAbout(tester, deps);

    expect(find.byKey(const Key('about-screen')), findsOneWidget);
    expect(find.byKey(const Key('about-app-version')), findsOneWidget);
    expect(find.text('App $kAppVersionLabel'), findsWidgets);
    expect(find.text(kDeterministicCoreOneLiner), findsOneWidget);
    expect(find.byKey(const Key('about-package-version-dryer')), findsOneWidget);
    expect(find.byKey(const Key('about-package-version-washer')), findsOneWidget);
    expect(find.byKey(const Key('about-package-version-fridge')), findsOneWidget);
    expect(
      find.byKey(const Key('about-package-version-dishwasher')),
      findsOneWidget,
    );
    expect(
      find.text(
        knowledgePackageStatusLine(
          id: BundledKnowledgePackageCatalog.dryer.id,
          version: deps.dryerPackageVersion,
          installed: true,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        knowledgePackageStatusLine(
          id: BundledKnowledgePackageCatalog.washer.id,
          version: BundledKnowledgePackageCatalog.washer.version,
          installed: true,
        ),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Not on this device'), findsNothing);
  });

  testWidgets('About v1 licenses stub opens Flutter license page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 13));
    deps.createHousehold('License House');

    await _openAbout(tester, deps);

    expect(find.text(UserFacingCopy.aboutLicensesStub), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('about-licenses-button')));
    await tester.tap(find.byKey(const Key('about-licenses-button')));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('About v1 lists missing guides when none are installed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 13),
      knowledgePackageRepository: KnowledgePackageRepository(
        initialPackages: const [],
      ),
    );
    deps.createHousehold('Empty Guides House');

    await _openAbout(tester, deps);

    expect(find.text('Not on this device'), findsNWidgets(4));
  });
}
