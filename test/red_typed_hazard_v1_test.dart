import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/phrasing_request.dart';
import 'package:modern_butlers_book/helpers/hazard_language.dart';
import 'package:modern_butlers_book/helpers/report_wrong.dart';
import 'package:modern_butlers_book/helpers/resume_open_observation.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/helpers/voice_answer.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_ui_resume_state.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('version is 0.1.4+26', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppBuildNumber, '26');
    expect(kAppVersionLabel, '0.1.4+26');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+26'));
  });

  test('GOLDEN Call a pro stays frozen', () {
    expect(kGoldenChromeFrozenLabels, contains('Call a pro'));
  });

  test('smell-gas / gas-leak / propane / bare-burning share one list', () {
    expect(kSharedHazardLanguageMarkers, containsAll(kSmellGasHazardMarkers));
    expect(kSharedHazardLanguageMarkers, containsAll(kGasLeakHazardMarkers));
    expect(kSharedHazardLanguageMarkers, containsAll(kPropaneHazardMarkers));
    expect(kSharedHazardLanguageMarkers, containsAll(kBareBurningHazardMarkers));

    expect(textSuggestsHazard('I smell gas'), isTrue);
    expect(classifyHazardLanguage('I smell gas'), HazardLanguageKind.gas);
    expect(classifyHazardLanguage('gas leak at the flex'), HazardLanguageKind.gas);
    expect(classifyHazardLanguage('propane odor'), HazardLanguageKind.gas);
    expect(classifyHazardLanguage('burning plastic'), HazardLanguageKind.fireSmoke);
    expect(transcriptSuggestsHazard('I smell gas'), isTrue);

    final shared = _read('lib/helpers/hazard_language.dart');
    expect(shared, contains('kSmellGasHazardMarkers'));
    expect(shared, contains('kGasLeakHazardMarkers'));
    expect(shared, contains('kPropaneHazardMarkers'));
    expect(shared, contains('kBareBurningHazardMarkers'));
    expect(shared, contains('kSharedHazardLanguageMarkers'));

    expect(_read('lib/helpers/voice_answer.dart'), contains('textSuggestsHazard'));
    expect(
      _read('lib/helpers/dryer_problem_starter.dart'),
      contains('kSharedHazardLanguageMarkers'),
    );
    expect(_read('lib/helpers/safety_stop.dart'), contains('hazardLanguageStopReason'));
    expect(
      _read('lib/helpers/safety_stop.dart'),
      contains('Other / describe must run the shared gas matcher'),
    );

    for (final path in [
      'lib/helpers/voice_answer.dart',
      'lib/helpers/safety_stop.dart',
      'lib/helpers/dryer_problem_starter.dart',
    ]) {
      final src = _read(path);
      expect(src, isNot(contains("'gas smell'")));
      expect(src, isNot(contains("'gas leak'")));
      expect(src, isNot(contains("'propane'")));
      expect(src, isNot(contains("'burning smell'")));
    }
  });

  test('hazard-observation Other with gas language is not skipped', () {
    final evidence = Evidence(
      id: 'e1',
      sessionId: 's1',
      applianceId: 'a1',
      type: EvidenceType.structuredAnswer,
      observation: 'Do you observe a burning smell or smoke?',
      answer: 'Other / describe: I smell gas',
      templateId: 'hazard-observation',
      collectedAt: DateTime.utc(2026, 9, 4),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
    expect(
      evaluateSafetyStop(evidence: [evidence])?.reason,
      kHazardLanguageGasReason,
    );
  });

  test('recover hold keeps _choseRepair false so invent cannot reopen', () {
    expect(
      choseRepairHonoringOpenInterviewHold(
        holdOpenInterview: true,
        storedChoseRepair: true,
        storedPhase: ClosePathPhase.guidance,
      ),
      isFalse,
    );
    expect(
      choseRepairHonoringOpenInterviewHold(
        holdOpenInterview: false,
        storedChoseRepair: false,
        storedPhase: ClosePathPhase.guidance,
      ),
      isTrue,
    );
    expect(
      recoverTreatsPendingObservationAsStillOpen(
        pendingTemplateId: 'lint-filter-condition',
        templateFound: false,
        interviewStillOpen: false,
      ),
      isTrue,
    );

    final recover = _read('lib/ui/session_screen.dart');
    final start = recover.indexOf('void _recoverResumeAfterError()');
    expect(start, greaterThan(0));
    final body = recover.substring(start, start + 3500);
    expect(body, contains('choseRepairHonoringOpenInterviewHold'));
    expect(body, contains('resumeClosePathPhaseHonoringOpenObservation'));
    expect(body, contains('shouldHoldUnansweredOpenInterviewOnResume'));
    expect(
      body,
      isNot(contains('_choseRepair = resume.choseRepair ||')),
    );
  });

  test('empty report-wrong notes are rejected and not persisted', () {
    expect(shouldRejectEmptyReportWrongNote(''), isTrue);
    expect(shouldRejectEmptyReportWrongNote('   '), isTrue);
    expect(shouldRejectEmptyReportWrongNote('the heat path was wrong'), isFalse);
    expect(
      _read('lib/ui/app_dependencies.dart'),
      contains('shouldRejectEmptyReportWrongNote'),
    );
    expect(
      _read('lib/ui/report_wrong_screen.dart'),
      contains('shouldRejectEmptyReportWrongNote'),
    );
  });

  testWidgets(
    'typed Other I smell gas writes hazard-observation and locks chips',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 20));
      await openDryerSession(tester, deps, 'Typed Hazard Other');
      expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
      await selectFailureMode(tester, 'thermal-fuse-open');
      expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);

      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-other-describe')),
      );
      expect(find.byKey(const Key('answer-other-note-field')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('answer-other-note-field')),
        'I smell gas',
      );
      await tester.tap(find.byKey(const Key('answer-other-confirm')));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('voice-hazard-confirm-banner')), findsOneWidget);
      expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
      expect(find.byKey(const Key('answer-choice-panel')), findsNothing);

      final session = deps.repairSessionRepository.listAllSessions().single;
      final recorded = deps.repairSessionRepository.evidenceForSession(session.id);
      expect(
        recorded
            .where((item) => item.templateId == 'hazard-observation')
            .map((item) => item.answer),
        contains('Yes'),
      );
      expect(
        recorded.any(
          (item) => (item.answer ?? '').startsWith('$kOtherDescribeChoiceId:'),
        ),
        isFalse,
      );
    },
  );

  testWidgets(
    'hazard-observation Other with gas language writes Yes and locks',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 20, 10));
      await openDryerSession(tester, deps, 'Hazard Other Gas');
      await selectObservation(tester, 'hazard-observation');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-other-describe')),
      );
      await tester.enterText(
        find.byKey(const Key('answer-other-note-field')),
        'I smell gas',
      );
      await tester.tap(find.byKey(const Key('answer-other-confirm')));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('voice-hazard-confirm-banner')), findsOneWidget);
      expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
      expect(find.byKey(const Key('answer-choice-panel')), findsNothing);
      final session = deps.repairSessionRepository.listAllSessions().single;
      expect(
        deps.repairSessionRepository
            .evidenceForSession(session.id)
            .where((item) => item.templateId == 'hazard-observation')
            .map((item) => item.answer),
        contains('Yes'),
      );
    },
  );

  testWidgets(
    'free observation I smell gas writes hazard and does not leave chips live',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 20, 20));
      await openDryerSession(tester, deps, 'Typed Hazard Free Note');
      await tapVisible(tester, find.byKey(const Key('free-observation-field')));
      await tester.enterText(
        find.byKey(const Key('free-observation-field')),
        'I smell gas',
      );
      await tapVisible(tester, find.byKey(const Key('free-observation-save')));

      expect(find.byKey(const Key('voice-hazard-confirm-banner')), findsOneWidget);
      expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
      expect(find.byKey(const Key('answer-choice-panel')), findsNothing);
      expect(find.byKey(const Key('free-observation-intake')), findsNothing);

      final session = deps.repairSessionRepository.listAllSessions().single;
      final recorded =
          deps.repairSessionRepository.evidenceForSession(session.id);
      expect(
        recorded
            .where((item) => item.templateId == 'hazard-observation')
            .map((item) => item.answer),
        contains('Yes'),
      );
      expect(
        recorded.where((item) => item.templateId == 'free-observation-note'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'typed Other gas under Continue settle still records and locks',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = DateTime.utc(2026, 9, 4, 21);
      final first = AppDependencies(clock: () => clock, store: store);
      first.createHousehold('Typed Hazard Settle House');
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

      final restored = AppDependencies(clock: () => clock, store: store);
      await restored.restore();
      await prepareTallSurface(tester);
      await tester.pumpWidget(ModernButlerApp(dependencies: restored));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('continue-repair-${dryer.id}')));
      await tester.pump();
      await tester.pump();
      if (find.byKey(const Key('answer-choice-other-describe')).evaluate().isEmpty) {
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('answer-choice-other-describe')), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-other-describe')),
      );
      await tester.enterText(
        find.byKey(const Key('answer-other-note-field')),
        'I smell gas',
      );
      await tester.tap(find.byKey(const Key('answer-other-confirm')));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('voice-hazard-confirm-banner')), findsOneWidget);
      expect(find.byKey(const Key('answer-choice-panel')), findsNothing);
      expect(
        restored.repairSessionRepository
            .evidenceForSession(sessionId)
            .where((item) => item.templateId == 'hazard-observation')
            .map((item) => item.answer),
        contains('Yes'),
      );
    },
  );

  testWidgets('empty report-wrong note is rejected and not saved', (
    tester,
  ) async {
    late List<Uri> openedMail;
    openedMail = <Uri>[];
    reportWrongMailtoOpener = (uri) async {
      openedMail.add(uri);
      return true;
    };
    addTearDown(() {
      reportWrongMailtoOpener = openReportWrongMailto;
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 16, 30),
      store: store,
    );
    deps.createHousehold('Empty Report House');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-report-wrong'));
    await tapVisible(tester, find.byKey(const Key('settings-report-wrong')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-wrong-save-email')));
    await tester.pumpAndSettle();

    expect(deps.wrongReports, isEmpty);
    expect(openedMail, isEmpty);
    expect(find.text(UserFacingCopy.reportWrongEmptyNote), findsOneWidget);
    expect(find.text(UserFacingCopy.reportWrongEmailOpened), findsNothing);

    final rejected = await deps.saveWrongReport(userNote: '   ');
    expect(rejected, isNull);
    expect(deps.wrongReports, isEmpty);
  });
}
