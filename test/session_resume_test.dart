import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/models/session_ui_resume_state.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/home_screen.dart';
import 'package:modern_butlers_book/ui/session_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('session UI resume state survives domain snapshot round-trip', () {
    final snapshot = DomainSnapshot(
      idCounter: 3,
      lastTimestamp: DateTime.utc(2026, 7, 24, 12),
      currentHouseholdId: 'household-1',
      sessionIdByApplianceId: const {'appliance-1': 'session-1'},
      packageRefsBySession: const {},
      households: const [],
      appliances: const [],
      sessions: const [],
      evidence: const [],
      evidenceLinks: const [],
      hypotheses: const [],
      hypothesisIdsBySession: const {},
      outcomes: const [],
      sessionUiResumeBySessionId: const {
        'session-1': SessionUiResumeState(
          pendingObservationTemplateId: 'cycle-heat-setting',
          pendingCloseVerificationFailureModeId: 'heating-element-failed',
          closePathPhase: ClosePathPhase.guidance,
          choseRepair: true,
          guidanceStepIndex: 2,
          completedGuidanceStepIds: ['0:lint', '1:hood'],
        ),
      },
    );

    final restored = DomainSnapshot.fromJson(snapshot.toJson());
    final resume = restored.sessionUiResumeBySessionId['session-1'];
    expect(resume?.pendingObservationTemplateId, 'cycle-heat-setting');
    expect(
      resume?.pendingCloseVerificationFailureModeId,
      'heating-element-failed',
    );
    expect(resume?.closePathPhase, ClosePathPhase.guidance);
    expect(resume?.choseRepair, isTrue);
    expect(resume?.guidanceStepIndex, 2);
    expect(resume?.completedGuidanceStepIds, ['0:lint', '1:hood']);
  });

  test('repair session JSON keeps guidance step progress', () {
    final session = RepairSession(
      id: 'session-1',
      applianceId: 'appliance-1',
      householdId: 'household-1',
      currentState: RepairSessionState.safeGuidance,
      startedAt: DateTime.utc(2026, 8, 18, 10),
      lastActivityAt: DateTime.utc(2026, 8, 18, 10),
      createdByUserId: 'user-1',
      packageId: 'dryer-core',
      packageVersion: '1.4.0',
      schemaVersion: '1.0',
      stateHistory: const [],
      guidanceStepIndex: 2,
      completedGuidanceStepIds: const ['0:lint', '1:hood'],
    );
    final snapshot = DomainSnapshot(
      idCounter: 1,
      lastTimestamp: DateTime.utc(2026, 8, 18, 10),
      currentHouseholdId: 'household-1',
      sessionIdByApplianceId: const {'appliance-1': 'session-1'},
      packageRefsBySession: const {},
      households: const [],
      appliances: const [],
      sessions: [session],
      evidence: const [],
      evidenceLinks: const [],
      hypotheses: const [],
      hypothesisIdsBySession: const {},
      outcomes: const [],
    );
    final restored = DomainSnapshot.fromJson(snapshot.toJson()).sessions.single;
    expect(restored.guidanceStepIndex, 2);
    expect(restored.completedGuidanceStepIds, ['0:lint', '1:hood']);
  });

  testWidgets(
    'leave and return keeps evidence, primary, and verification panel',
    (tester) async {
      final fixedTime = DateTime.utc(2026, 7, 24, 12);
      final dependencies = AppDependencies(clock: () => fixedTime);

      await openDryerSession(tester, dependencies, 'Resume Household');

      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );
      await selectObservation(tester, 'cycle-heat-setting');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-yes-heat-cycle')),
      );
      await selectFailureMode(tester, 'heating-element-failed');

      expect(find.byKey(const Key('primary-hypothesis-banner')), findsOneWidget);
      expect(find.byKey(const Key('current-conclusion-card')), findsOneWidget);
      expect(find.text('Evidence count: 2'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      final dryer = dependencies.appliancesForCurrentHousehold().single;
      expect(find.text('Continue repair'), findsOneWidget);
      expect(find.byKey(Key('continue-repair-${dryer.id}')), findsOneWidget);
      expect(find.textContaining('Continue in-progress session'), findsOneWidget);
      expect(dependencies.hasInProgressSession(dryer), isTrue);
      expect(dependencies.recentSessionOutcomes(), isEmpty);

      await startRepairFromDetail(tester);
      await dismissProblemStarterIfPresent(tester);

      expect(find.text('Evidence count: 2'), findsOneWidget);
      expect(find.byKey(const Key('primary-hypothesis-banner')), findsOneWidget);
      expect(find.byKey(const Key('current-conclusion-card')), findsOneWidget);
    },
  );

  testWidgets('leave and return keeps a manually chosen active question', (
    tester,
  ) async {
    final fixedTime = DateTime.utc(2026, 7, 24, 13);
    final dependencies = AppDependencies(clock: () => fixedTime);

    await openDryerSession(tester, dependencies, 'Question Resume');

    await selectObservation(tester, 'heat-observed');
    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-no-warmth')),
    );
    await selectObservation(tester, 'cycle-heat-setting');
    expect(
      find.descendant(
        of: find.byKey(const Key('answer-choice-panel')),
        matching: find.byKey(const Key('observation-prompt-cycle-heat-setting')),
      ),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await startRepairFromDetail(tester);
    await dismissProblemStarterIfPresent(tester);

    expect(
      find.descendant(
        of: find.byKey(const Key('answer-choice-panel')),
        matching: find.byKey(const Key('observation-prompt-cycle-heat-setting')),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('answer-choice-yes-heat-cycle')), findsOneWidget);
  });

  testWidgets('resume state survives local store restore', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final fixedTime = DateTime.utc(2026, 7, 24, 14);
    final first = AppDependencies(clock: () => fixedTime, store: store);

    await openDryerSession(tester, first, 'Persisted Resume');
    await selectObservation(tester, 'heat-observed');
    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-no-warmth')),
    );
    await selectFailureMode(tester, 'heating-element-failed');
    expect(find.byKey(const Key('current-conclusion-card')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await first.flushPersist();

    final second = AppDependencies(clock: () => fixedTime, store: store);
    await second.restore();
    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: second));
    await tester.pumpAndSettle();

    final dryer = second.appliancesForCurrentHousehold().single;
    expect(find.text('Continue repair'), findsOneWidget);
    expect(find.byKey(Key('continue-repair-${dryer.id}')), findsOneWidget);
    expect(second.hasInProgressSession(dryer), isTrue);
    expect(second.recentSessionOutcomes(), isEmpty);

    await tester.tap(find.byKey(Key('continue-repair-${dryer.id}')));
    await tester.pumpAndSettle();
    await dismissProblemStarterIfPresent(tester);

    expect(find.text('Evidence count: 1'), findsOneWidget);
    expect(find.byKey(const Key('primary-hypothesis-banner')), findsOneWidget);
    expect(find.byKey(const Key('current-conclusion-card')), findsOneWidget);
    expect(second.repairSessionRepository.listAllSessions(), hasLength(1));
    expect(second.recentSessionOutcomes(), isEmpty);
  });

  test('exit without outcome stays open; resume does not duplicate memory',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final clock = DateTime.utc(2026, 8, 16, 15);
    final first = AppDependencies(clock: () => clock, store: store);

    first.createHousehold('Open Session House');
    final dryer = first.addDryer();
    final sessionId = first.startOrResumeSession(dryer);
    first.saveSessionUiResume(
      sessionId,
      const SessionUiResumeState(
        pendingObservationTemplateId: 'heat-observed',
        starterConfirmed: true,
      ),
    );

    expect(first.hasInProgressSession(dryer), isTrue);
    expect(first.recentSessionOutcomes(), isEmpty);
    expect(first.startOrResumeSession(dryer), sessionId);
    expect(first.repairSessionRepository.listAllSessions(), hasLength(1));

    final snapshot = first.activeSessionSnapshotFor(dryer);
    expect(snapshot, isNotNull);
    expect(snapshot!.sessionId, sessionId);
    expect(snapshot.applianceId, dryer.id);
    expect(snapshot.currentState, RepairSessionState.evidenceCollection);
    expect(snapshot.uiResume?.pendingObservationTemplateId, 'heat-observed');

    await first.flushPersist();

    final second = AppDependencies(clock: () => clock, store: store);
    await second.restore();
    final restoredDryer = second.appliancesForCurrentHousehold().single;
    final restored = second.activeSessionSnapshotFor(restoredDryer);
    expect(restored?.sessionId, sessionId);
    expect(restored?.applianceId, restoredDryer.id);
    expect(restored?.currentState, RepairSessionState.evidenceCollection);
    expect(restored?.uiResume?.pendingObservationTemplateId, 'heat-observed');
    expect(second.startOrResumeSession(restoredDryer), sessionId);
    expect(second.repairSessionRepository.listAllSessions(), hasLength(1));
    expect(second.recentSessionOutcomes(), isEmpty);

    second.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.fixed,
      whatFixedIt: 'Cleaned the lint trap',
    );
    expect(second.hasInProgressSession(restoredDryer), isFalse);
    expect(second.activeSessionSnapshotFor(restoredDryer), isNull);
    expect(second.recentSessionOutcomes(), hasLength(1));
    expect(
      second.recentSessionOutcomes().single.outcome.sessionId,
      sessionId,
    );
  });

  testWidgets('detail Continue repair resumes the same open session', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 16, 16));
    deps.createHousehold('Detail Continue');
    final dryer = deps.addDryer();
    final sessionId = deps.startOrResumeSession(dryer);

    await prepareTallSurface(tester);
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(dependencies: deps)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Continue repair'), findsOneWidget);
    expect(find.byKey(Key('continue-repair-${dryer.id}')), findsOneWidget);

    await startRepairFromDetail(tester);
    await dismissProblemStarterIfPresent(tester);

    expect(deps.startOrResumeSession(dryer), sessionId);
    expect(deps.repairSessionRepository.listAllSessions(), hasLength(1));
    expect(deps.recentSessionOutcomes(), isEmpty);
  });

  testWidgets(
    'app kill after two guidance steps resumes on step 3',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = DateTime.utc(2026, 8, 18, 15);
      final first = AppDependencies(clock: () => clock, store: store);

      await openDryerSession(tester, first, 'Guidance Persist');
      await selectFailureMode(tester, 'thermal-fuse-open');
      await completeRepairReadinessIfPresent(tester);
      await tapVisible(tester, find.byKey(const Key('guidance-did-this')));
      await tapVisible(tester, find.byKey(const Key('guidance-did-this')));
      expect(find.textContaining('Step 3 of'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await first.flushPersist();

      final second = AppDependencies(clock: () => clock, store: store);
      await second.restore();
      await prepareTallSurface(tester);
      await tester.pumpWidget(ModernButlerApp(dependencies: second));
      await tester.pumpAndSettle();

      final dryer = second.appliancesForCurrentHousehold().single;
      await tester.tap(find.byKey(Key('continue-repair-${dryer.id}')));
      await tester.pumpAndSettle();
      await dismissProblemStarterIfPresent(tester);

      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.textContaining('Step 3 of'), findsOneWidget);
      expect(
        second.uiResumeForSession(
          second.repairSessionRepository.listAllSessions().single.id,
        )?.completedGuidanceStepIds,
        hasLength(2),
      );
      expect(
        second.repairSessionRepository.listAllSessions().single.guidanceStepIndex,
        2,
      );
      expect(
        second.repairSessionRepository
            .listAllSessions()
            .single
            .completedGuidanceStepIds,
        hasLength(2),
      );
    },
  );

  testWidgets(
    'Continue repair with tools done and no I did this opens step 1',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 17));
      await openDryerSession(tester, deps, 'Tools Then Resume');
      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );
      await selectFailureMode(tester, 'thermal-fuse-open');
      await completeRepairReadinessIfPresent(tester);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.textContaining('Step 1 of'), findsOneWidget);
      expect(find.text('Evidence count: 4'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await startRepairFromDetail(tester);
      await dismissProblemStarterIfPresent(tester);

      expect(find.text(UserFacingCopy.resumeFailed), findsNothing);
      expect(find.byKey(const Key('repair-readiness-card')), findsNothing);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.textContaining('Step 1 of'), findsOneWidget);
      expect(find.text('Evidence count: 4'), findsOneWidget);
    },
  );

  testWidgets(
    'leave after tools marked, before guidance, resumes on tools not inspect',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 10));
      await openDryerSession(tester, deps, 'Tools Done Leave');
      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );
      await selectFailureMode(tester, 'thermal-fuse-open');
      await markRepairReadinessHaveIfPresent(tester);
      expect(find.byKey(const Key('repair-readiness-card')), findsOneWidget);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
      expect(find.byKey(const Key('inspect-step-card-inspect-lint-filter')), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await startRepairFromDetail(tester);
      await dismissProblemStarterIfPresent(tester);

      expect(find.text(UserFacingCopy.resumeFailed), findsNothing);
      expect(find.byKey(const Key('repair-readiness-card')), findsNothing);
      expect(find.byKey(const Key('inspect-step-card-inspect-lint-filter')), findsNothing);
      await acknowledgeProScopeIfPresent(tester);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.textContaining('Step 1 of'), findsOneWidget);
    },
  );

  testWidgets(
    'Continue repair on conclusion does not skip I\'ll repair',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 18));
      await openDryerSession(tester, deps, 'Conclusion Resume');
      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );
      await selectFailureMode(tester, 'thermal-fuse-open');
      expect(find.byKey(const Key('current-conclusion-card')), findsOneWidget);
      expect(find.byKey(const Key('close-path-ill-repair')), findsNothing);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
      expect(find.text('Evidence count: 1'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await startRepairFromDetail(tester);
      await dismissProblemStarterIfPresent(tester);

      expect(find.text(UserFacingCopy.resumeFailed), findsNothing);
      expect(find.byKey(const Key('current-conclusion-card')), findsOneWidget);
      expect(find.byKey(const Key('close-path-ill-repair')), findsNothing);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
      expect(find.text('Evidence count: 1'), findsOneWidget);
    },
  );

  testWidgets(
    'stale pending question does not blank a mid-guidance resume',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 11));
      await openDryerSession(tester, deps, 'Stale Prompt Resume');
      await selectFailureMode(tester, 'thermal-fuse-open');
      await completeRepairReadinessIfPresent(tester);
      await tapVisible(tester, find.byKey(const Key('guidance-did-this')));
      expect(find.textContaining('Step 2 of'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      final session = deps.repairSessionRepository.listAllSessions().single;
      final saved = deps.uiResumeForSession(session.id)!;
      deps.saveSessionUiResume(
        session.id,
        saved.copyWith(pendingObservationTemplateId: 'not-a-real-template'),
      );

      await startRepairFromDetail(tester);
      await dismissProblemStarterIfPresent(tester);

      expect(find.text(UserFacingCopy.resumeFailed), findsNothing);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.textContaining('Step 2 of'), findsOneWidget);
      expect(
        find.textContaining('This repair session is no longer available.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'washer Continue repair keeps clues and first incomplete guidance step',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 12));
      await openWasherSession(tester, deps, 'Washer Guidance Resume');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-won-t-drain')),
      );
      await selectFailureMode(tester, 'clogged-washer-drain-filter');
      await completeRepairReadinessIfPresent(tester);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('guidance-did-this')));
      expect(find.textContaining('Step 2 of'), findsOneWidget);
      expect(find.textContaining('Evidence count:'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await startRepairFromDetail(tester);

      expect(find.text(UserFacingCopy.resumeFailed), findsNothing);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.textContaining('Step 2 of'), findsOneWidget);
      expect(find.textContaining('Evidence count: 3'), findsOneWidget);
    },
  );

  testWidgets(
    'Settings clear open session starts fresh without old chips',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 19));
      await openDryerSession(tester, deps, 'Cleared Session');
      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );
      expect(find.text('Evidence count: 1'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-settings-button')));
      await tester.pumpAndSettle();
      await scrollSettingsUntil(
        tester,
        const Key('settings-clear-session-button'),
      );
      await tester.tap(find.byKey(const Key('settings-clear-session-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-clear-session-confirm')));
      await tester.pumpAndSettle();

      final dryer = deps.appliancesForCurrentHousehold().single;
      expect(deps.hasInProgressSession(dryer), isFalse);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Continue repair'), findsNothing);
      await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
      await tester.pumpAndSettle();
      expect(find.text('Start repair'), findsOneWidget);
      await startRepairFromDetail(tester);
      await dismissProblemStarterIfPresent(tester);

      expect(find.text(UserFacingCopy.resumeFailed), findsNothing);
      expect(find.textContaining('Answer: No warmth'), findsNothing);
      expect(find.text('Evidence count: 0'), findsOneWidget);
    },
  );

  testWidgets(
    'Continue repair does not re-ask a completed observation chip',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 16));
      deps.createHousehold('Completed Chip');
      final dryer = deps.addDryer();
      final sessionId = deps.startOrResumeSession(dryer);
      final session = deps.repairSessionRepository.getSession(sessionId)!;
      deps.sessionCoordinator.addEvidence(
        evidence: Evidence(
          id: deps.nextId('evidence'),
          sessionId: sessionId,
          applianceId: dryer.id,
          type: EvidenceType.structuredAnswer,
          observation: 'Is there any warmth after the dryer has run briefly?',
          answer: 'No warmth',
          templateId: 'heat-observed',
          collectedAt: deps.nextTimestamp(),
          collectedInState: session.currentState,
          source: EvidenceSource.user,
          schemaVersion: session.schemaVersion,
        ),
        evidenceLinkId: deps.nextId('evidence-link'),
      );
      deps.saveSessionUiResume(
        sessionId,
        const SessionUiResumeState(
          pendingObservationTemplateId: 'heat-observed',
          starterConfirmed: true,
        ),
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

      expect(find.text(UserFacingCopy.resumeFailed), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('answer-choice-panel')),
          matching: find.byKey(const Key('observation-prompt-heat-observed')),
        ),
        findsNothing,
      );
    },
  );
}
