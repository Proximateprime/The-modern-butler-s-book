import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/degraded_mode.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/helpers/washer_latch_copy.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/maintenance_notifier.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/settings_screen.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets(
    'safety stop opens Needs a professional handoff and stores stop level',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 12));
      await openDryerSession(
        tester,
        deps,
        'Stop Handoff House',
        skipProblemStarter: false,
      );
      await tester.tap(find.byKey(const Key('starter-chip-hazard-signs')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem-starter-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
      expect(find.textContaining('Unplug if it is safe'), findsWidgets);
      expect(find.textContaining('ventilate'), findsWidgets);

      final dryer = deps.appliancesForCurrentHousehold().single;
      final sessionId = deps.startOrResumeSession(dryer);
      expect(deps.buildDecisionContext(sessionId).safetyLevel, 'stop');
      expect(
        deps.buildDecisionContext(sessionId).safetyLevel,
        isNot('not evaluated'),
      );

      await tapVisible(tester, find.byKey(const Key('end-session-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('outcome-needs-professional')), findsOneWidget);
      expect(find.byKey(const Key('recent-activity-title')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('outcome-save-button')));
      await tester.tap(find.byKey(const Key('outcome-save-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pro-handoff-screen')), findsOneWidget);
    },
  );

  test('typed burning-smell path includes unplug/ventilate copy', () {
    expect(
      UserFacingCopy.safetyStopOfficial.toLowerCase(),
      contains('unplug'),
    );
    expect(
      UserFacingCopy.safetyStopOfficial.toLowerCase(),
      contains('ventilate'),
    );
    expect(
      UserFacingCopy.safetyStopOfficial.toLowerCase(),
      contains('do not keep running'),
    );
    expect(
      UserFacingCopy.voiceHazardConfirm,
      UserFacingCopy.safetyStopOfficial,
    );
  });

  testWidgets('camera-denied Start fresh abandons the open session', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 12, 10));
    deps.simulateMediaDenied = true;
    await openDryerSession(tester, deps, 'Denied Fresh House');
    final dryer = deps.appliancesForCurrentHousehold().single;
    final firstId = deps.startOrResumeSession(dryer);
    expect(deps.hasInProgressSession(dryer), isTrue);

    expect(find.byKey(const Key('error-banner-camera')), findsOneWidget);
    await tester.tap(find.byKey(degradedStartFreshKey(DegradedModeKind.cameraDenied)));
    await tester.pumpAndSettle();

    final session = deps.repairSessionRepository.getSession(firstId);
    expect(session?.currentState, RepairSessionState.abandoned);
    final nextId = deps.startOrResumeSession(dryer);
    expect(nextId, isNot(firstId));
  });

  testWidgets('top-load washer chips say lid', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 12, 20));
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('create-household-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('household-name-field')),
      'Lid House',
    );
    await tester.tap(find.byKey(const Key('confirm-household-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-washer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-washer-load-topLoad')));
    await tester.pumpAndSettle();
    await confirmAddAppliance(tester);
    expect(
      deps.appliancesForCurrentHousehold().single.washerLoadStyle,
      WasherLoadStyle.topLoad,
    );
    await tester.tap(find.text('Laundry Room Washer'));
    await tester.pumpAndSettle();
    await startRepairFromDetail(tester);
    await dismissProblemStarterIfPresent(tester);
    expect(find.text("Lid won't close"), findsOneWidget);
    expect(find.text("Door won't close"), findsNothing);
    expect(
      washerLatchClickPrompt(WasherLoadStyle.topLoad).toLowerCase(),
      contains('lid'),
    );
  });

  testWidgets('Expert switch without adult checkbox shows a message', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 12, 30));
    deps.createHousehold('Expert House');
    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          dependencies: deps,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-expert-mode'));
    await tester.tap(find.byKey(const Key('settings-expert-mode')));
    await tester.pumpAndSettle();
    expect(deps.expertMode, isFalse);
    expect(find.text(UserFacingCopy.expertModeNeedAdult), findsOneWidget);
  });

  testWidgets(
    'reminder success copy does not claim no ping when notifier is armed',
    (tester) async {
      final notifier = SilentMaintenanceNotifier(notificationsAllowed: true);
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 29, 12, 40),
        maintenanceNotifier: notifier,
      );
      await openDryerSession(tester, deps, 'Reminder House');
      await selectObservation(tester, 'clothes-remain-damp');
      await tapVisible(tester, find.byKey(const Key('answer-choice-still-damp')));
      await selectObservation(tester, 'exterior-airflow');
      await tapInspectOrAnswerChoice(tester, 'weak');
      await selectFailureMode(tester, 'restricted-exhaust-airflow');
      await completeRepairReadinessIfPresent(tester);
      await completeGuidanceStepsIfPresent(tester);
      await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
      await tapVisible(tester, find.byKey(const Key('end-session-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('outcome-resolved')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('outcome-what-fixed-field')),
        'Cleared the crushed vent hose',
      );
      await tester.tap(find.byKey(const Key('outcome-save-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('completion-add-reminder')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('reminder-note-field')),
        'Clean the lint filter next month',
      );
      await tester.tap(find.byKey(const Key('reminder-save-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('completion-reminder-saved')), findsOneWidget);
      expect(find.textContaining('No notification will be sent'), findsNothing);
      expect(find.textContaining(UserFacingCopy.reminderPingScheduled), findsOneWidget);
    },
  );
}
