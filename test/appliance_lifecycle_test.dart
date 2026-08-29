import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/appliance_repository.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';

void main() {
  group('ApplianceRepository', () {
    test('listForHousehold hides retired appliances by default', () {
      final repo = ApplianceRepository();
      final timestamp = DateTime.utc(2026, 7, 24);
      repo.create(
        Appliance(
          id: 'appliance-1',
          householdId: 'household-1',
          name: 'Dryer A',
          category: 'dryer',
          manufacturer: 'Demo',
          modelNumber: 'A',
          location: 'Laundry',
          status: ApplianceStatus.active,
          schemaVersion: '1.0',
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
      repo.archive('appliance-1', updatedAt: timestamp);

      expect(repo.listForHousehold('household-1'), isEmpty);
      expect(
        repo.listForHousehold('household-1', includeArchived: true),
        hasLength(1),
      );
      expect(repo.getById('appliance-1')?.status, ApplianceStatus.retired);
    });
  });

  group('AppDependencies appliance lifecycle', () {
    final clock = () => DateTime.utc(2026, 7, 24, 12);

    AppDependencies buildDeps() => AppDependencies(clock: clock);

    test('starts a new session on the same dryer after the prior one closes', () {
      final deps = buildDeps();
      deps.createHousehold('Home');
      final dryer = deps.addDryer();

      final sessionOne = deps.startOrResumeSession(dryer);
      deps.endSession(
        sessionId: sessionOne,
        resolutionStatus: SessionResolutionStatus.resolved,
      );

      final sessionTwo = deps.startOrResumeSession(dryer);
      expect(sessionTwo, isNot(sessionOne));
      expect(deps.repairSessionRepository.getSession(sessionOne), isNotNull);
      expect(deps.repairSessionRepository.getSession(sessionTwo), isNotNull);
    });

    test('resume returns the in-progress session without creating another', () {
      final deps = buildDeps();
      deps.createHousehold('Home');
      final dryer = deps.addDryer();

      final sessionOne = deps.startOrResumeSession(dryer);
      final sessionAgain = deps.startOrResumeSession(dryer);
      expect(sessionAgain, sessionOne);
    });

    test('retire hides dryer from active list but keeps session history', () {
      final deps = buildDeps();
      deps.createHousehold('Home');
      final dryer = deps.addDryer();
      final sessionId = deps.startOrResumeSession(dryer);
      deps.endSession(
        sessionId: sessionId,
        resolutionStatus: SessionResolutionStatus.resolved,
      );

      deps.archiveAppliance(dryer);

      expect(deps.appliancesForCurrentHousehold(), isEmpty);
      expect(deps.applianceRepository.getById(dryer.id)?.status,
          ApplianceStatus.retired);
      expect(deps.repairSessionRepository.getSession(sessionId), isNotNull);
      expect(deps.recentSessionOutcomes(), isNotEmpty);

      expect(
        () => deps.startOrResumeSession(dryer),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('HomeScreen appliance flow', () {
    testWidgets('select existing dryer starts another session after resolve', (
      tester,
    ) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 7, 24, 12));
      deps.createHousehold('Home');
      final dryer = deps.addDryer();
      final first = deps.startOrResumeSession(dryer);
      deps.endSession(
        sessionId: first,
        resolutionStatus: SessionResolutionStatus.resolved,
      );

      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(dependencies: deps)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('appliance-${dryer.id}')), findsOneWidget);

      await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('appliance-detail-name')), findsOneWidget);
      expect(find.byKey(Key('appliance-start-${dryer.id}')), findsOneWidget);

      await tester.tap(find.byKey(const Key('appliance-detail-start-repair')));
      await tester.pumpAndSettle();
      expect(find.text('Now: Answering questions'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('archive-appliance-${dryer.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('confirm-archive-${dryer.id}')));
      await tester.pumpAndSettle();

      expect(find.text(UserFacingCopy.noDryersYet), findsOneWidget);
      expect(deps.appliancesForCurrentHousehold(), isEmpty);
      expect(deps.recentSessionOutcomes(), isNotEmpty);
    });

    testWidgets('in-progress session shows Continue repair on home list', (
      tester,
    ) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 7, 24, 12));
      deps.createHousehold('Home');
      final dryer = deps.addDryer();
      deps.startOrResumeSession(dryer);

      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(dependencies: deps)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('continue-repair-${dryer.id}')), findsOneWidget);
      expect(find.text('Continue repair'), findsOneWidget);
    });
  });
}
