import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/knowledge_package_ref.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';
import 'package:modern_butlers_book/ui/session_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('user-facing errors never return stack traces', () {
    expect(
      userFacingErrorMessage(
        StateError('No knowledge package is available for "dryer".'),
      ),
      UserFacingCopy.packageUnavailable,
    );
    expect(
      userFacingErrorMessage(
        Exception(
          'Exception: boom\n#0      foo (package:modern_butlers_book/x.dart:1:1)',
        ),
      ),
      UserFacingCopy.genericError,
    );
  });

  testWidgets('first launch shows what it does, what it doesn’t, then privacy', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 16),
      firstRunComplete: false,
    );
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    expect(find.byKey(const Key('first-run-screen')), findsOneWidget);
    expect(find.byKey(const Key('first-run-page-what')), findsOneWidget);
    expect(find.text(UserFacingCopy.firstRunGreeting), findsOneWidget);
    expect(find.text(UserFacingCopy.firstRunDoesTitle), findsOneWidget);
    expect(find.textContaining('House Book'), findsOneWidget);
    expect(find.text('1 of 3'), findsNothing);
    expect(find.byKey(const Key('first-run-progress')), findsNothing);
    expect(find.byKey(const Key('create-household-button')), findsNothing);

    await tester.tap(find.byKey(const Key('first-run-next-button')));
    await tester.pump();

    expect(find.byKey(const Key('first-run-page-not')), findsOneWidget);
    expect(find.text(UserFacingCopy.firstRunDoesNotTitle), findsOneWidget);
    expect(find.textContaining('camera never diagnoses'), findsOneWidget);
    expect(find.textContaining('gas'), findsOneWidget);
    expect(find.text(UserFacingCopy.firstRunGreeting), findsNothing);
    expect(find.text('2 of 3'), findsNothing);

    await tester.tap(find.byKey(const Key('first-run-next-button')));
    await tester.pump();

    expect(find.byKey(const Key('first-run-page-privacy')), findsOneWidget);
    expect(find.text(UserFacingCopy.firstRunPrivacyTitle), findsOneWidget);
    expect(find.textContaining('this device'), findsWidgets);
    expect(find.textContaining('cloud account'), findsOneWidget);
    expect(find.textContaining('Groq'), findsOneWidget);
    expect(find.textContaining('butler backend'), findsOneWidget);
    expect(find.text('3 of 3'), findsNothing);
    expect(find.byKey(const Key('first-run-done-button')), findsOneWidget);
  });

  testWidgets('skip completes first run and is not shown again', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final first = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 16),
      store: store,
      firstRunComplete: false,
    );

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: first));
    await tester.tap(find.byKey(const Key('first-run-skip-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-run-screen')), findsNothing);
    expect(find.byKey(const Key('create-household-button')), findsOneWidget);
    expect(await store.loadFirstRunComplete(), isTrue);

    final second = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 16),
      store: store,
      firstRunComplete: await store.loadFirstRunComplete(),
    );
    await tester.pumpWidget(ModernButlerApp(dependencies: second));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-run-screen')), findsNothing);
    expect(find.byKey(const Key('create-household-button')), findsOneWidget);
  });

  testWidgets('done completes first run and is not shown again', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final first = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 16),
      store: store,
      firstRunComplete: false,
    );

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: first));
    await tester.tap(find.byKey(const Key('first-run-next-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('first-run-next-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('first-run-done-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-run-screen')), findsNothing);
    expect(await store.loadFirstRunComplete(), isTrue);

    final second = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 16),
      store: store,
      firstRunComplete: await store.loadFirstRunComplete(),
    );
    await tester.pumpWidget(ModernButlerApp(dependencies: second));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('first-run-screen')), findsNothing);
  });

  testWidgets('empty home has household and dryer CTAs and empty history', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 16));
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    expect(find.byKey(const Key('create-household-button')), findsOneWidget);
    expect(find.byKey(const Key('empty-home-create-household')), findsOneWidget);
    expect(find.text(UserFacingCopy.createHouseholdAction), findsNWidgets(2));
    expect(find.text(UserFacingCopy.emptyHomeNoHousehold), findsWidgets);
    expect(find.text('Create Household'), findsNothing);
    expect(find.text(UserFacingCopy.noRepairsYet), findsOneWidget);
    expect(find.byKey(const Key('add-dryer-button')), findsNothing);

    await tester.tap(find.byKey(const Key('create-household-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('household-name-field')),
      'Empty Home',
    );
    await tester.tap(find.byKey(const Key('confirm-household-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-dryer-button')), findsOneWidget);
    expect(find.text(UserFacingCopy.noDryersYet), findsOneWidget);
    expect(find.text(UserFacingCopy.emptyHomeNoDryer), findsOneWidget);
    expect(find.text(UserFacingCopy.noRepairsYet), findsOneWidget);
  });

  testWidgets('missing package shows human copy not a stack trace', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 16, 16),
      knowledgePackageRepository: KnowledgePackageRepository(
        initialPackages: const [],
      ),
    );
    deps.createHousehold('Offline House');
    final dryer = deps.addDryer();

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('appliance-missing-package')), findsOneWidget);
    await startRepairFromDetail(tester);

    expect(find.byKey(const Key('package-install-screen')), findsOneWidget);
    expect(find.text(UserFacingCopy.packageUnavailable), findsWidgets);
    expect(find.textContaining('StateError'), findsNothing);
    expect(find.textContaining('#0'), findsNothing);

    await tester.tap(find.byKey(const Key('package-install-local-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('problem-starter-panel')), findsOneWidget);
  });

  testWidgets('session with stale package version remaps onto the bundled guide', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 16));
    deps.createHousehold('Missing Guide');
    final dryer = deps.addDryer();
    final sessionId = deps.startOrResumeSession(dryer);
    final refs = Map<String, KnowledgePackageRef>.from(
      deps.sessionCoordinator.exportPackageRefs(),
    );
    final original = refs[sessionId]!;
    refs[sessionId] = KnowledgePackageRef(
      id: original.id,
      applianceCategory: original.applianceCategory,
      version: '99.0.0-missing',
      displayName: original.displayName,
    );
    deps.sessionCoordinator.importPackageRefs(refs);

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SessionScreen(
          dependencies: deps,
          appliance: dryer,
          sessionId: sessionId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('problem-starter-panel')), findsOneWidget);
    expect(find.byKey(const Key('prompts-unavailable-message')), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
    expect(find.textContaining('stack'), findsNothing);
  });
}
