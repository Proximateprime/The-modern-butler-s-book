import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/knowledge_package_catalog.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('empty repo can install a bundled dryer guide locally', () {
    final repo = KnowledgePackageRepository(initialPackages: const []);
    expect(repo.isEmpty, isTrue);
    expect(repo.loadByCategory('dryer'), isEmpty);

    final installed = repo.installBundledCategory('dryer');
    expect(installed, isNotNull);
    expect(installed!.id, BundledKnowledgePackageCatalog.dryer.id);
    expect(installed.version, BundledKnowledgePackageCatalog.dryer.version);
    expect(repo.loadByCategory('dryer'), hasLength(1));
    expect(repo.installBundledCategory('dryer')!.id, installed.id);
  });

  test('status lines match PACKAGE_INVENTORY ids and versions', () {
    expect(
      knowledgePackageIdVersionLabel(id: 'dryer-core', version: '1.4.2'),
      'dryer-core 1.4.2',
    );
    expect(
      knowledgePackageStatusLine(
        id: BundledKnowledgePackageCatalog.dryer.id,
        version: BundledKnowledgePackageCatalog.dryer.version,
        installed: true,
      ),
      'dryer-core 1.4.2 · Installed',
    );
    expect(
      knowledgePackageStatusLine(
        id: BundledKnowledgePackageCatalog.washer.id,
        version: BundledKnowledgePackageCatalog.washer.version,
        installed: true,
      ),
      'washer-core 0.2.3 · Installed',
    );
    expect(
      knowledgePackageStatusLine(
        id: BundledKnowledgePackageCatalog.fridge.id,
        version: BundledKnowledgePackageCatalog.fridge.version,
        installed: true,
      ),
      'fridge-core 1.0.1 · Installed',
    );
    expect(
      knowledgePackageStatusLine(
        id: BundledKnowledgePackageCatalog.dishwasher.id,
        version: BundledKnowledgePackageCatalog.dishwasher.version,
        installed: true,
      ),
      'dishwasher-core 0.2.3 · Installed',
    );
  });

  test('update stub is local-only copy', () {
    expect(
      packageUpdatesStubMessage(online: true),
      contains('No updates'),
    );
    expect(
      packageUpdatesStubMessage(online: false),
      contains('offline'),
    );
    expect(packageUpdatesStubMessage(online: true), isNot(contains('http')));
  });

  testWidgets('settings lists installed guides and check-for-updates stub', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 19));
    deps.createHousehold('Guides House');
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();

    await scrollSettingsUntil(tester, const Key('settings-package-manager'));
    await tester.tap(find.byKey(const Key('settings-package-manager')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('package-manager-screen')), findsOneWidget);
    expect(find.byKey(const Key('settings-package-dryer')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('settings-package-dryer')));
    expect(find.byKey(const Key('package-id-dryer')), findsOneWidget);
    expect(
      find.text(
        knowledgePackageStatusLine(
          id: BundledKnowledgePackageCatalog.dryer.id,
          version: BundledKnowledgePackageCatalog.dryer.version,
          installed: true,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Washer guide'), findsOneWidget);
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
    expect(find.text('Fridge guide'), findsOneWidget);
    expect(
      find.text(
        knowledgePackageStatusLine(
          id: BundledKnowledgePackageCatalog.fridge.id,
          version: BundledKnowledgePackageCatalog.fridge.version,
          installed: true,
        ),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(const Key('settings-package-dishwasher')));
    expect(find.text('Dishwasher guide'), findsOneWidget);
    expect(
      find.text(
        knowledgePackageStatusLine(
          id: BundledKnowledgePackageCatalog.dishwasher.id,
          version: BundledKnowledgePackageCatalog.dishwasher.version,
          installed: true,
        ),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const Key('settings-check-updates')));
    await tester.tap(find.byKey(const Key('settings-check-updates')));
    await tester.pump();
    expect(find.text(packageUpdatesStubMessage(online: true)), findsOneWidget);
  });

  testWidgets('offline indicator on home and settings', (tester) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 19),
      isOnline: () => false,
    );
    deps.createHousehold('Offline Guides');
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    expect(find.byKey(const Key('home-offline-indicator')), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-package-manager'));
    await tester.tap(find.byKey(const Key('settings-package-manager')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('settings-check-updates')));
    await tester.tap(find.byKey(const Key('settings-check-updates')));
    await tester.pump();
    expect(find.text(packageUpdatesStubMessage(online: false)), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-offline-banner'));
    expect(find.byKey(const Key('settings-offline-banner')), findsOneWidget);
    expect(find.text(UserFacingCopy.offlineGuidesStillWork), findsOneWidget);
  });

  testWidgets('missing category installs from this device then starts', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 19),
      knowledgePackageRepository: KnowledgePackageRepository(
        initialPackages: const [],
      ),
    );
    deps.createHousehold('Install House');
    final fridge = deps.addFridge();

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(Key('appliance-${fridge.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('appliance-missing-package')), findsOneWidget);
    await tester.tap(find.byKey(const Key('appliance-install-package')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('package-install-screen')), findsOneWidget);
    expect(find.text(UserFacingCopy.packageInstallHint), findsOneWidget);

    await tester.tap(find.byKey(const Key('package-install-local-button')));
    await tester.pumpAndSettle();
    expect(deps.hasInstalledPackageFor('fridge'), isTrue);
    expect(find.byKey(const Key('appliance-missing-package')), findsNothing);

    await startRepairFromDetail(tester);
    expect(find.byKey(const Key('problem-starter-panel')), findsNothing);
    expect(find.text('What is the fridge doing?'), findsOneWidget);
  });
}
