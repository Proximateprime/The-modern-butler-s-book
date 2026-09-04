import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/helpers/phrasing_request.dart';
import 'package:modern_butlers_book/helpers/published_version.dart';
import 'package:modern_butlers_book/helpers/repair_readiness.dart';
import 'package:modern_butlers_book/helpers/report_wrong.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_ui_resume_state.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/services/voice_answer.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('version is 0.1.4+25', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppBuildNumber, '25');
    expect(kAppVersionLabel, '0.1.4+25');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+25'));
  });

  test('GOLDEN Call a pro stays frozen', () {
    expect(kGoldenChromeFrozenLabels, contains('Call a pro'));
  });

  test('published site/version.json build matches pubspec', () {
    final pubspec = _read('pubspec.yaml');
    final match = RegExp(r'^version:\s*([0-9.]+)\+(\d+)\s*$', multiLine: true)
        .firstMatch(pubspec);
    expect(match, isNotNull);
    final version = match!.group(1)!;
    final build = match.group(2)!;
    final published = parsePublishedVersionJson(_read('site/version.json'));
    expect(published.version, version);
    expect(published.buildNumber, build);
    expect(
      publishedBuildMismatchLine(
        appVersion: version,
        appBuildNumber: build,
        publishedVersion: published.version,
        publishedBuildNumber: published.buildNumber,
      ),
      isNull,
    );
    expect(
      publishedBuildMismatchLine(
        appVersion: version,
        appBuildNumber: build,
        publishedVersion: version,
        publishedBuildNumber: '22',
      ),
      contains('hosted book reports'),
    );
  });

  test('web host cache-busts bootstrap and version.json', () {
    final index = _read('web/index.html');
    expect(index, contains('flutter_bootstrap.js?v=$kAppVersionLabel'));
    expect(index.toLowerCase(), contains('no-cache'));
  });

  test('stopReason uses household labels, never session.currentState.name', () {
    expect(
      _read('lib/helpers/report_wrong.dart'),
      isNot(contains('session.currentState.name')),
    );
    final ctx = buildReportWrongContext(
      session: RepairSession(
        id: 's1',
        applianceId: 'a1',
        householdId: 'h1',
        currentState: RepairSessionState.evidenceCollection,
        startedAt: DateTime.utc(2026, 9, 4),
        lastActivityAt: DateTime.utc(2026, 9, 4),
        createdByUserId: 'u1',
        packageId: 'dryer-core',
        packageVersion: '1.0',
        schemaVersion: '1.0',
        stateHistory: const [],
      ),
    );
    expect(ctx.stopReason, 'Answering questions');
    expect(ctx.stopReason, isNot(contains('evidenceCollection')));
  });

  test('report-wrong maps package id and question slug to household labels', () {
    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    final ctx = buildReportWrongContext(
      package: package,
      uiResume: const SessionUiResumeState(
        pendingObservationTemplateId: 'odor-type',
      ),
    );
    expect(ctx.packageId, 'Dryer guide');
    expect(ctx.packageId, isNot(contains('dryer-core')));
    expect(ctx.packageVersion, isNull);
    expect(ctx.lastQuestionId, isNot('odor-type'));
    expect(ctx.lastQuestionId, isNot(contains('odor-type')));
    expect(
      toolsChecklistHelperLine(const [
        RepairReadinessItem(
          id: 'screwdriver',
          label: 'Screwdriver (optional)',
          optional: true,
          liveElectrical: false,
        ),
      ]),
      contains('Optional tools can be I don’t'),
    );
    expect(
      toolsChecklistHelperLine(const [
        RepairReadinessItem(
          id: 'shallow-pan',
          label: 'Shallow pan and towel',
          optional: false,
          liveElectrical: false,
        ),
      ]),
      contains('Required tools must be marked I have'),
    );
  });

  test('report-wrong copy is draft-only, not a live inbox', () {
    expect(kReportWrongSupportEmail, endsWith('.invalid'));
    expect(UserFacingCopy.reportWrongEmailOpened.toLowerCase(), contains('draft'));
    expect(
      UserFacingCopy.reportWrongEmailOpened.toLowerCase(),
      contains('no support inbox'),
    );
    expect(
      UserFacingCopy.reportWrongEmailOpened.toLowerCase(),
      isNot(contains('delivered to support')),
    );
    expect(formatReportWrongEmailBody(
      ReportWrongNote(
        id: 'n1',
        recordedAt: DateTime.utc(2026, 9, 4),
        userNote: 'off',
        appVersionLabel: kAppVersionLabel,
      ),
    ), contains('no support inbox yet'));
  });

  test('session gates: hazard write outside invent; honesty empty ≠ verify', () {
    final screen = _read('lib/ui/session_screen.dart');
    expect(screen, contains("promptId == 'hazard-observation'"));
    expect(screen, contains('wroteHazard'));
    expect(screen, contains('_voiceHazardConfirm'));
    expect(screen, contains('_guidanceEmptyBecauseHonesty'));
    expect(screen, contains('honesty-empty-stop-panel'));
    expect(screen, contains('_restoreHeldObservationAfterRecover'));
    expect(screen, contains('heldTap'));
    expect(screen, contains('resumeRowWasCorrupt'));
    expect(screen, contains('_voiceHazardConfirm'));
    expect(
      screen,
      contains('isTerminal || safetyStop != null || _voiceHazardConfirm'),
    );
    expect(
      screen,
      contains(
        'final showProHandoff =\n'
        '            diyPro && !_choseRepair && !showProWarning && safeChecksDone;',
      ),
    );
  });

  testWidgets(
    'voice hazard under unanswered hold still records and locks chips',
    (tester) async {
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 9, 4, 20),
        voiceAnswer: ScriptedVoiceAnswerListener(
          VoiceAnswerCapture.heard('there is smoke coming out'),
        ),
      );
      await openDryerSession(tester, deps, 'Hazard Under Hold');
      expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
      await selectFailureMode(tester, 'thermal-fuse-open');
      expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('voice-answer-mic')));
      expect(find.byKey(const Key('voice-hazard-confirm-banner')), findsOneWidget);
      expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
      expect(find.byKey(const Key('answer-choice-panel')), findsNothing);
      expect(find.text(UserFacingCopy.voiceHazardConfirm), findsOneWidget);

      final session = deps.repairSessionRepository.listAllSessions().single;
      final answers = deps.repairSessionRepository
          .evidenceForSession(session.id)
          .where((item) => item.templateId == 'hazard-observation')
          .map((item) => item.answer);
      expect(answers, contains('Yes'));
    },
  );

  testWidgets(
    'voice hazard during Continue settle still records and locks',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = DateTime.utc(2026, 9, 4, 21);
      final first = AppDependencies(clock: () => clock, store: store);
      first.createHousehold('Hazard Settle House');
      final dryer = first.addDryer();
      final sessionId = first.startOrResumeSession(dryer);
      first.saveSessionUiResume(
        sessionId,
        const SessionUiResumeState(
          pendingObservationTemplateId: 'gas-dryer-type',
          starterConfirmed: true,
          starterSymptomIds: ['no-heat'],
          closePathPhase: ClosePathPhase.conclusion,
        ),
      );
      await first.flushPersist();

      final restored = AppDependencies(
        clock: () => clock,
        store: store,
        voiceAnswer: ScriptedVoiceAnswerListener(
          VoiceAnswerCapture.heard('I smell burning plastic'),
        ),
      );
      await restored.restore();
      await prepareTallSurface(tester);
      await tester.pumpWidget(ModernButlerApp(dependencies: restored));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('continue-repair-${dryer.id}')));
      await tester.pump();
      await tester.pump();
      if (find.byKey(const Key('voice-answer-mic')).evaluate().isEmpty) {
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('voice-answer-mic')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('voice-answer-mic')));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('voice-hazard-confirm-banner')), findsOneWidget);
      expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
      expect(find.byKey(const Key('answer-choice-panel')), findsNothing);
      final answers = restored.repairSessionRepository
          .evidenceForSession(sessionId)
          .where((item) => item.templateId == 'hazard-observation')
          .map((item) => item.answer);
      expect(answers, contains('Yes'));
    },
  );

  testWidgets(
    'no-tools honesty empty path never opens verification',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 22));
      deps.setExpertMode(enabled: true, adultConfirmed: true);
      await openDryerSession(tester, deps, 'Honesty Empty Verify');
      await selectFailureMode(tester, 'thermal-fuse-open');
      await advanceClosePathFromConclusionIfPresent(tester);
      await completeInspectStepsIfPresent(tester);
      expect(find.byKey(const Key('repair-readiness-card')), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const Key('readiness-missing-screwdriver')),
      );
      await tapVisible(
        tester,
        find.byKey(const Key('readiness-missing-flashlight')),
      );
      await tapVisible(tester, find.byKey(const Key('close-path-tools-continue')));
      await acknowledgeProScopeIfPresent(tester);

      expect(find.byKey(const Key('close-path-phase-verification')), findsNothing);
      expect(find.byKey(const Key('close-path-continue')), findsNothing);

      for (var i = 0; i < 20; i++) {
        expect(
          find.byKey(const Key('close-path-phase-verification')),
          findsNothing,
        );
        expect(find.byKey(const Key('close-path-continue')), findsNothing);
        if (find.byKey(const Key('pro-recommended-card')).evaluate().isNotEmpty ||
            find.byKey(const Key('honesty-empty-stop-panel')).evaluate().isNotEmpty ||
            find.byKey(const Key('guidance-could-not-panel')).evaluate().isNotEmpty) {
          break;
        }
        final did = find.byKey(const Key('guidance-did-this'));
        if (did.evaluate().isEmpty) {
          break;
        }
        await tapVisible(tester, did);
      }

      expect(find.byKey(const Key('close-path-phase-verification')), findsNothing);
      expect(find.byKey(const Key('close-path-continue')), findsNothing);
      expect(
        find.byKey(const Key('pro-recommended-card')).evaluate().isNotEmpty ||
            find.byKey(const Key('honesty-empty-stop-panel')).evaluate().isNotEmpty ||
            find.byKey(const Key('guidance-could-not-panel')).evaluate().isNotEmpty,
        isTrue,
      );
    },
  );

  testWidgets(
    'corrupt resume row shows calm resume-failed, does not invent',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = DateTime.utc(2026, 9, 4, 23);
      final first = AppDependencies(clock: () => clock, store: store);
      first.createHousehold('Corrupt Resume House');
      final dryer = first.addDryer();
      final sessionId = first.startOrResumeSession(dryer);
      first.saveSessionUiResume(
        sessionId,
        const SessionUiResumeState(
          pendingObservationTemplateId: 'lint-filter-condition',
          starterConfirmed: true,
        ),
      );
      await first.flushPersist();

      final raw = prefs.getString('modern_butler_domain_v1');
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      decoded['sessionUiResumeBySessionId'] = {sessionId: 'not-a-map'};
      await prefs.setString('modern_butler_domain_v1', jsonEncode(decoded));

      final restored = AppDependencies(clock: () => clock, store: store);
      await restored.restore();
      expect(restored.resumeRowWasCorrupt(sessionId), isTrue);

      await prepareTallSurface(tester);
      await tester.pumpWidget(ModernButlerApp(dependencies: restored));
      await tester.tap(find.byKey(Key('continue-repair-${dryer.id}')));
      await tester.pumpAndSettle();
      expect(find.text(UserFacingCopy.resumeFailed), findsOneWidget);
    },
  );

  testWidgets(
    'after I\'ll repair, DIY chrome does not say a pro must finish the job',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 23, 10));
      await openDryerSession(tester, deps, 'Ill Repair No Lecture');
      await selectFailureMode(tester, 'thermal-fuse-open');
      await tapVisible(tester, find.byKey(const Key('close-path-continue')));
      expect(find.byKey(const Key('close-path-ill-repair')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('close-path-ill-repair')));
      await completeInspectStepsIfPresent(tester);
      expect(
        find.textContaining('A technician fits this part on this path'),
        findsNothing,
      );
      expect(find.byKey(const Key('parts-cost-pro-only-note')), findsNothing);
      await markRepairReadinessHaveIfPresent(tester);
      final cont = find.byKey(const Key('close-path-tools-continue'));
      if (cont.evaluate().isNotEmpty) {
        await tapVisible(tester, cont);
      }
      expect(find.byKey(const Key('pro-scope-warning-card')), findsNothing);
      expect(find.textContaining('A full fix likely needs a pro'), findsNothing);
      expect(
        find.textContaining('won’t be able to finish the repair yourself at home'),
        findsNothing,
      );
      expect(
        find.textContaining('A technician fits this part on this path'),
        findsNothing,
      );
      await completeGuidanceStepsIfPresent(tester);
      expect(find.byKey(const Key('pro-recommended-card')), findsNothing);
      expect(find.byKey(const Key('pro-handoff-why')), findsNothing);
      expect(find.byKey(const Key('pro-handoff-understand')), findsNothing);
    },
  );
}
