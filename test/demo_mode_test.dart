import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/helpers/demo_sample_home.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/models/session_ui_resume_state.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

Appliance _dryer(AppDependencies deps) {
  return deps.appliancesForCurrentHousehold().firstWhere(
    (item) => item.category == 'dryer',
  );
}

Appliance _washer(AppDependencies deps) {
  return deps.appliancesForCurrentHousehold().firstWhere(
    (item) => item.category == 'washer',
  );
}

void main() {
  test('load sample home seeds dryer and washer with stable labels', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23));
    deps.createHousehold('Real House');
    final realDryer = deps.addDryer(name: 'Keep This Dryer');

    deps.loadSampleHome();

    expect(deps.currentHousehold?.name, DemoSampleHome.householdName);
    final appliances = deps.appliancesForCurrentHousehold();
    expect(appliances, hasLength(2));
    final dryer = _dryer(deps);
    expect(dryer.name, DemoSampleHome.dryerName);
    expect(dryer.manufacturer, DemoSampleHome.manufacturer);
    expect(dryer.modelNumber, DemoSampleHome.modelNumber);
    expect(dryer.serialNumber, DemoSampleHome.dryerSerial);
    final washer = _washer(deps);
    expect(washer.name, DemoSampleHome.washerName);
    expect(washer.modelNumber, DemoSampleHome.washerModelNumber);
    expect(washer.serialNumber, DemoSampleHome.washerSerial);

    final history = deps.repairHistoryForAppliance(dryer.id);
    expect(history, hasLength(2));
    expect(
      history.map((item) => item.outcome.closeKind).toSet(),
      {SessionCloseKind.fixed},
    );
    expect(deps.hasInProgressSession(dryer), isTrue);
    expect(deps.hasInProgressSession(washer), isFalse);
    expect(deps.openSessionCount, 1);

    deps.switchHousehold(
      deps.listHouseholds().firstWhere((item) => item.name == 'Real House').id,
    );
    expect(deps.appliancesForCurrentHousehold().single.id, realDryer.id);
  });

  test('include sample open session toggle matches the label', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23));
    deps.includeSampleOpenSession = false;
    deps.loadSampleHome();
    expect(deps.hasInProgressSession(_dryer(deps)), isFalse);
    expect(deps.repairHistoryForAppliance(_dryer(deps).id), hasLength(2));

    deps.includeSampleOpenSession = true;
    deps.loadSampleHome();
    expect(deps.hasInProgressSession(_dryer(deps)), isTrue);
    expect(deps.hasInProgressSession(_washer(deps)), isFalse);
  });

  test('reset sample data restores canned state and leaves other homes', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23));
    deps.createHousehold('Keep House');
    deps.addDryer(name: 'Keep Dryer');

    deps.loadSampleHome();
    deps.addWasher(name: 'Extra Washer');
    expect(deps.appliancesForCurrentHousehold(), hasLength(3));

    deps.resetSampleData();
    deps.resetSampleData();

    final appliances = deps.appliancesForCurrentHousehold();
    expect(appliances, hasLength(2));
    expect(_dryer(deps).name, DemoSampleHome.dryerName);
    expect(_washer(deps).name, DemoSampleHome.washerName);
    expect(deps.hasInProgressSession(_dryer(deps)), isTrue);
    expect(deps.repairHistoryForAppliance(_dryer(deps).id), hasLength(2));

    final keep = deps.listHouseholds().firstWhere(
      (item) => item.name == 'Keep House',
    );
    deps.switchHousehold(keep.id);
    expect(
      deps.appliancesForCurrentHousehold().single.name,
      'Keep Dryer',
    );
  });

  test('reset with no sample and clear with no session do not throw', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23, 5));
    expect(deps.resetSampleData(), isNull);
    expect(deps.resetSampleData(), isNull);
    deps.clearOpenSessions();
    deps.clearOpenSessions();
    expect(deps.openSessionCount, 0);
    expect(deps.listHouseholds(), isEmpty);
  });

  test('clear open session drops Continue repair and guidance resume', () {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23, 6));
    deps.loadSampleHome(includeOpenSession: true);
    final dryer = _dryer(deps);
    final sessionId = deps.startOrResumeSession(dryer);
    deps.saveSessionUiResume(
      sessionId,
      const SessionUiResumeState(
        closePathPhase: ClosePathPhase.guidance,
        choseRepair: true,
        guidanceStepIndex: 2,
        completedGuidanceStepIds: ['0:lint', '1:hood'],
      ),
    );
    expect(deps.hasInProgressSession(dryer), isTrue);
    expect(deps.uiResumeForSession(sessionId), isNotNull);

    deps.clearOpenSessions();

    expect(deps.hasInProgressSession(dryer), isFalse);
    expect(deps.openSessionCount, 0);
    expect(deps.uiResumeForSession(sessionId), isNull);
    expect(
      deps.repairHistoryForAppliance(dryer.id).map((row) => row.outcome.closeKind),
      everyElement(SessionCloseKind.fixed),
    );
    final fresh = deps.startOrResumeSession(dryer);
    expect(fresh, isNot(sessionId));
    expect(deps.uiResumeForSession(fresh), isNull);
  });

  testWidgets('home load sample home fills the screen for screenshots', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23));
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    await tester.tap(find.byKey(const Key('load-sample-home-button')));
    await tester.pumpAndSettle();

    expect(find.text(DemoSampleHome.householdName), findsOneWidget);
    expect(find.text(DemoSampleHome.dryerName), findsWidgets);
    expect(find.text(DemoSampleHome.washerName), findsWidgets);
    expect(find.byKey(const Key('recent-activity-list')), findsOneWidget);
    expect(find.textContaining('Continue repair'), findsOneWidget);
  });

  testWidgets('settings reset sample data restores canned dryer and washer', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23));
    deps.loadSampleHome();
    deps.addWasher(name: 'Extra Washer');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-reset-sample-data'));
    await tester.tap(find.byKey(const Key('settings-reset-sample-data')));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text(DemoSampleHome.dryerName), findsWidgets);
    expect(find.text(DemoSampleHome.washerName), findsWidgets);
    expect(find.text('Extra Washer'), findsNothing);
  });

  testWidgets('settings reset and clear are safe when sample was never loaded', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23, 8));
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-reset-sample-data'));
    await tester.tap(find.byKey(const Key('settings-reset-sample-data')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-reset-sample-data')));
    await tester.pumpAndSettle();

    await scrollSettingsUntil(tester, const Key('settings-clear-session-button'));
    await tester.tap(find.byKey(const Key('settings-clear-session-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-clear-session-confirm')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings toggle then load sample omits Continue repair', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 23, 9));
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));

    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-sample-open-session'));
    await tester.tap(find.byKey(const Key('settings-sample-open-session')));
    await tester.pumpAndSettle();
    expect(deps.includeSampleOpenSession, isFalse);

    await scrollSettingsUntil(tester, const Key('settings-load-sample-home'));
    await tester.tap(find.byKey(const Key('settings-load-sample-home')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text(DemoSampleHome.dryerName), findsWidgets);
    expect(find.textContaining('Continue repair'), findsNothing);
    expect(deps.hasInProgressSession(_dryer(deps)), isFalse);
  });
}
