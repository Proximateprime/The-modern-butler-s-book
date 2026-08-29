import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/models/knowledge_package_ref.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/session_screen.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('stale package version remaps to the bundled dryer guide', () {
    final repo = KnowledgePackageRepository();
    final current = repo.loadById('dryer-core')!;
    final stale = KnowledgePackageRef(
      id: 'dryer-core',
      applianceCategory: 'dryer',
      version: '1.4.0',
      displayName: current.displayName,
    );
    expect(repo.loadByRef(stale), isNull);
    expect(repo.resolveCompatible(stale), same(current));
    expect(
      repo.resolveCompatible(
        const KnowledgePackageRef(
          id: 'dryer',
          applianceCategory: 'dryer',
          version: '0.1.0',
          displayName: 'Dryer',
        ),
      ),
      same(current),
    );
    expect(
      repo.resolveForResume(
        const KnowledgePackageRef(
          id: 'legacy-dryer-pack',
          applianceCategory: 'dryer',
          version: '0.9.0',
          displayName: 'Dryer',
        ),
      ),
      same(current),
    );
    expect(
      repo.resolveCompatible(
        const KnowledgePackageRef(
          id: 'missing-package',
          applianceCategory: 'dryer',
          version: '1.0.0',
          displayName: 'Missing',
        ),
      ),
      isNull,
    );
  });

  testWidgets(
    'Continue repair after upgrade remaps old dryer version and shows questions',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 25, 15));
      deps.createHousehold('Upgrade Resume');
      final dryer = deps.addDryer();
      final sessionId = deps.startOrResumeSession(dryer);
      final refs = Map<String, KnowledgePackageRef>.from(
        deps.sessionCoordinator.exportPackageRefs(),
      );
      final original = refs[sessionId]!;
      refs[sessionId] = KnowledgePackageRef(
        id: original.id,
        applianceCategory: original.applianceCategory,
        version: '1.4.0',
        displayName: original.displayName,
      );
      deps.sessionCoordinator.importPackageRefs(refs);
      deps.repairSessionRepository.rebindPackage(
        sessionId: sessionId,
        packageId: original.id,
        packageVersion: '1.4.0',
      );

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

      expect(find.byKey(const Key('missing-guide-scaffold')), findsNothing);
      expect(find.byKey(const Key('problem-starter-panel')), findsOneWidget);
      expect(
        deps.repairSessionRepository.getSession(sessionId)!.packageVersion,
        '1.4.2',
      );
    },
  );

  testWidgets(
    'missing package is a real scaffold; Install loads the session; OK pops',
    (tester) async {
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 25, 15, 10),
        knowledgePackageRepository: KnowledgePackageRepository(
          initialPackages: const [],
        ),
      );
      deps.createHousehold('Missing Guide House');
      final dryer = deps.addDryer();
      final household = deps.currentHousehold!;
      final session = deps.repairSessionRepository.createSession(
        id: 'session-missing-guide',
        applianceId: dryer.id,
        householdId: household.id,
        createdByUserId: household.ownerUserId,
        packageId: 'dryer-core',
        packageVersion: '1.4.0',
        schemaVersion: '1.0',
        initialHistoryEntryId: 'hist-missing',
        startedAt: DateTime.utc(2026, 8, 25, 15, 10),
      );
      deps.sessionCoordinator.importPackageRefs({
        session.id: const KnowledgePackageRef(
          id: 'dryer-core',
          applianceCategory: 'dryer',
          version: '1.4.0',
          displayName: 'Dryer Knowledge Package',
        ),
      });

      await prepareTallSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  key: const Key('open-stuck-session'),
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder:
                            (context) => SessionScreen(
                              dependencies: deps,
                              appliance: dryer,
                              sessionId: session.id,
                            ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-stuck-session')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('missing-guide-scaffold')), findsOneWidget);
      expect(find.byKey(const Key('prompts-unavailable-message')), findsOneWidget);
      expect(find.text(UserFacingCopy.installGuide), findsOneWidget);
      expect(find.text(UserFacingCopy.continueManually), findsNothing);
      expect(find.byType(AppBar), findsOneWidget);

      await tester.tap(find.byKey(const Key('missing-guide-ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('missing-guide-scaffold')), findsNothing);
      expect(find.byKey(const Key('open-stuck-session')), findsOneWidget);

      await tester.tap(find.byKey(const Key('open-stuck-session')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('package-install-local-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('missing-guide-scaffold')), findsNothing);
      expect(find.byKey(const Key('problem-starter-panel')), findsOneWidget);
    },
  );

  testWidgets('Start fresh from missing-guide pops and does not leave a blank route', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 25, 15, 20),
      knowledgePackageRepository: KnowledgePackageRepository(
        initialPackages: const [],
      ),
    );
    deps.createHousehold('Start Fresh House');
    final dryer = deps.addDryer();
    final household = deps.currentHousehold!;
    final session = deps.repairSessionRepository.createSession(
      id: 'session-start-fresh',
      applianceId: dryer.id,
      householdId: household.id,
      createdByUserId: household.ownerUserId,
      packageId: 'dryer-core',
      packageVersion: '1.4.0',
      schemaVersion: '1.0',
      initialHistoryEntryId: 'hist-fresh',
      startedAt: DateTime.utc(2026, 8, 25, 15, 20),
    );
    deps.sessionCoordinator.importPackageRefs({
      session.id: const KnowledgePackageRef(
        id: 'dryer-core',
        applianceCategory: 'dryer',
        version: '1.4.0',
        displayName: 'Dryer Knowledge Package',
      ),
    });

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                key: const Key('open-fresh-session'),
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder:
                          (context) => SessionScreen(
                            dependencies: deps,
                            appliance: dryer,
                            sessionId: session.id,
                          ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-fresh-session')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('missing-guide-scaffold')), findsOneWidget);

    await tester.tap(find.byKey(const Key('missing-guide-start-fresh')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('missing-guide-scaffold')), findsNothing);
    expect(find.byKey(const Key('open-fresh-session')), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(
      deps.repairSessionRepository.getSession(session.id)!.currentState.name,
      'abandoned',
    );
  });
}
