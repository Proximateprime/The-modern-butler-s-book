import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/knowledge_package_catalog.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('theme choice survives local persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final first = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 21),
      store: store,
    );
    await first.applyThemeChoice(AppThemeChoice.modern);

    final second = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 21),
      store: store,
    );
    await second.loadThemeChoice();
    expect(second.themeChoice, AppThemeChoice.modern);
  });

  test('clearOpenSessions abandons in-progress repair without memory', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 21));
    deps.createHousehold('Clear House');
    final dryer = deps.addDryer();
    deps.startOrResumeSession(dryer);
    expect(deps.hasInProgressSession(dryer), isTrue);
    expect(deps.openSessionCount, 1);

    deps.clearOpenSessions();

    expect(deps.hasInProgressSession(dryer), isFalse);
    expect(deps.openSessionCount, 0);
    expect(deps.recentSessionOutcomes(), isEmpty);
  });

  testWidgets('settings persist Modern, show version, and link to tools', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 21),
      store: store,
    );
    deps.createHousehold('Settings House');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-theme-modern')));
    await tester.pumpAndSettle();
    expect(deps.themeChoice, AppThemeChoice.modern);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.scaffoldBackgroundColor, const Color(0xFFF4F6F8));

    await scrollSettingsUntil(tester, const Key('settings-version-badge'));
    expect(find.byKey(const Key('settings-version-badge')), findsOneWidget);
    expect(find.text('App $kAppVersionLabel'), findsOneWidget);
    expect(
      find.text('Feature freeze $kFeatureFreezeDate — bugfixes only'),
      findsOneWidget,
    );
    await tapVisible(tester, find.byKey(const Key('settings-version-badge')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('about-screen')), findsOneWidget);
    expect(find.byKey(const Key('about-app-version')), findsOneWidget);
    expect(find.byKey(const Key('about-deterministic-core')), findsOneWidget);
    expect(find.text(kDeterministicCoreOneLiner), findsOneWidget);
    expect(
      find.byKey(const Key('about-package-version-dryer')),
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
    expect(find.byKey(const Key('about-licenses-stub')), findsOneWidget);
    expect(find.text(UserFacingCopy.aboutLicensesStub), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-privacy-card'));
    expect(find.byKey(const Key('settings-privacy-card')), findsOneWidget);
    expect(find.text(UserFacingCopy.privacyLocalFirst), findsOneWidget);
    expect(find.text(UserFacingCopy.privacyWhatIsStored), findsOneWidget);
    expect(find.text(UserFacingCopy.privacyNoSkillProfiling), findsOneWidget);
    expect(find.text(UserFacingCopy.privacyPhrasingBackend), findsOneWidget);
    expect(find.textContaining('GROQ_API_KEY'), findsNothing);
    expect(find.textContaining('paste'), findsNothing);
    expect(find.textContaining('API key'), findsNothing);
    await scrollSettingsUntil(tester, const Key('settings-permissions-help'));
    expect(find.byKey(const Key('settings-permissions-help')), findsOneWidget);
    expect(find.text(UserFacingCopy.permissionsCameraMicWhy), findsOneWidget);
    expect(find.text(UserFacingCopy.permissionsDeniedManual), findsOneWidget);

    await scrollSettingsUntil(tester, const Key('settings-package-manager'));
    await tester.tap(find.byKey(const Key('settings-package-manager')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('package-manager-screen')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('settings-package-dryer')));
    expect(find.byKey(const Key('settings-package-dryer')), findsOneWidget);
    expect(find.byKey(const Key('settings-package-washer')), findsOneWidget);
    expect(find.byKey(const Key('settings-package-fridge')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('settings-package-dishwasher')),
    );
    expect(find.byKey(const Key('settings-package-dishwasher')), findsOneWidget);
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
    expect(find.byKey(const Key('settings-check-updates')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await scrollSettingsUntil(tester, const Key('settings-tools-item'));
    await tester.tap(find.byKey(const Key('settings-tools-item')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tools-inventory-screen')), findsOneWidget);
  });

  testWidgets('clear open session requires confirm', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 21));
    deps.createHousehold('Session House');
    final dryer = deps.addDryer();
    deps.startOrResumeSession(dryer);

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-clear-session-button'));
    await tester.tap(find.byKey(const Key('settings-clear-session-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-clear-session-cancel')));
    await tester.pumpAndSettle();
    expect(deps.hasInProgressSession(dryer), isTrue);

    await tester.tap(find.byKey(const Key('settings-clear-session-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-clear-session-confirm')));
    await tester.pumpAndSettle();
    expect(deps.hasInProgressSession(dryer), isFalse);
  });
}
