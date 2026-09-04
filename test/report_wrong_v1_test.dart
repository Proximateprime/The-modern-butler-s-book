import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/phrasing_request.dart';
import 'package:modern_butlers_book/helpers/report_wrong.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_ui_resume_state.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  late List<Uri> openedMail;

  setUp(() {
    openedMail = <Uri>[];
    reportWrongMailtoOpener = (uri) async {
      openedMail.add(uri);
      return true;
    };
  });

  tearDown(() {
    reportWrongMailtoOpener = openReportWrongMailto;
  });

  test('version is 0.1.4+26', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+26');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+26'));
  });

  test('GOLDEN Call a pro stays frozen', () {
    expect(kGoldenChromeFrozenLabels, contains('Call a pro'));
  });

  test('mailto body has stub fields and no photo or vendor upload', () {
    final note = ReportWrongNote(
      id: 'wrong-1',
      recordedAt: DateTime.utc(2026, 9, 4, 12),
      userNote: 'Heat path asked the wrong thing',
      appVersionLabel: kAppVersionLabel,
      applianceCategory: 'dryer',
      packageId: 'Dryer guide',
      stopReason: 'Needs a professional',
      lastQuestionId: 'Is there any warmth after the dryer has run briefly?',
      clueCount: 2,
    );
    final body = formatReportWrongEmailBody(note);
    expect(body, contains('App: $kAppVersionLabel'));
    expect(body, contains('Appliance category: dryer'));
    expect(body, contains('Guide: Dryer guide'));
    expect(body, isNot(contains('dryer-core')));
    expect(body, isNot(contains('1.4.2')));
    expect(body, contains('Stop reason: Needs a professional'));
    expect(body, contains('Last question: Is there any warmth'));
    expect(body, isNot(contains('Last question id:')));
    expect(body, isNot(contains('heat-observed')));
    expect(body, contains('Clue count: 2'));
    expect(body, contains('Note: Heat path asked the wrong thing'));
    expect(body, contains('no support inbox yet'));
    expect(body.toLowerCase(), isNot(contains('datadog')));
    expect(body.toLowerCase(), isNot(contains('sentry')));
    expect(body.toLowerCase(), isNot(contains('firebase')));
    expect(body, isNot(contains('http')));
    final uri = reportWrongMailtoUri(note);
    expect(uri.scheme, 'mailto');
    expect(uri.path, kReportWrongSupportEmail);
    expect(uri.queryParameters['subject'], contains('This was wrong'));
    expect(uri.queryParameters['body'], contains('Appliance category: dryer'));
    expect(uri.queryParameters['body'], contains('Clue count: 2'));
  });

  test('context is PII-minimal: category and ids, not photos', () {
    final ctx = buildReportWrongContext(
      appliance: Appliance(
        id: 'a1',
        householdId: 'h1',
        name: 'Secret House Dryer',
        category: 'dryer',
        manufacturer: 'Maytag',
        modelNumber: 'XYZ',
        location: 'basement floor plan north wall',
        status: ApplianceStatus.active,
        schemaVersion: '1',
        createdAt: DateTime.utc(2026, 9, 1),
        updatedAt: DateTime.utc(2026, 9, 1),
      ),
      uiResume: const SessionUiResumeState(
        pendingObservationTemplateId: 'heat-observed',
      ),
      evidence: [
        Evidence(
          id: 'e1',
          sessionId: 's1',
          applianceId: 'a1',
          type: EvidenceType.structuredAnswer,
          observation: 'Is there any warmth after the dryer has run briefly?',
          answer: 'No warmth',
          templateId: 'heat-observed',
          collectedAt: DateTime.utc(2026, 9, 4, 12),
          collectedInState: RepairSessionState.evidenceCollection,
          source: EvidenceSource.user,
          schemaVersion: '1',
          localPhotoPath: '/tmp/secret.jpg',
        ),
      ],
    );
    expect(ctx.applianceCategory, 'dryer');
    expect(ctx.lastQuestionId, isNot(contains('heat-observed')));
    expect(ctx.lastQuestionId, contains('warmth'));
    expect(ctx.packageId, 'Dryer guide');
    expect(ctx.packageVersion, isNull);
    expect(ctx.clueCount, 1);
    final note = ReportWrongNote(
      id: 'wrong-2',
      recordedAt: DateTime.utc(2026, 9, 4),
      userNote: 'off',
      appVersionLabel: kAppVersionLabel,
      applianceCategory: ctx.applianceCategory,
      lastQuestionId: ctx.lastQuestionId,
      clueCount: ctx.clueCount,
    );
    final body = formatReportWrongEmailBody(note);
    expect(body, isNot(contains('Secret House Dryer')));
    expect(body, isNot(contains('basement')));
    expect(body, isNot(contains('secret.jpg')));
    expect(body, isNot(contains('Maytag')));
  });

  test('local note persists across AppDependencies with SharedPreferences',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final first = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 14),
      store: store,
    );
    first.createHousehold('Report House');
    final dryer = first.addDryer();
    final sessionId = first.startOrResumeSession(dryer);
    first.saveSessionUiResume(
      sessionId,
      const SessionUiResumeState(pendingObservationTemplateId: 'heat-observed'),
    );

    final saved = await first.saveWrongReport(
      userNote: 'Wrong question after no warmth',
      sessionId: sessionId,
    );
    expect(saved, isNotNull);
    expect(saved!.applianceCategory, 'dryer');
    expect(saved.lastQuestionId, isNot('heat-observed'));
    expect(saved.lastQuestionId, isNotNull);
    expect(saved.packageId, 'Dryer guide');
    expect(saved.packageVersion, isNull);
    expect(saved.userNote, 'Wrong question after no warmth');
    expect(saved.appVersionLabel, kAppVersionLabel);

    final second = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 15),
      store: store,
    );
    await second.loadWrongReports();
    expect(second.wrongReports, isNotEmpty);
    expect(second.wrongReports.first.userNote, 'Wrong question after no warmth');
    expect(second.wrongReports.first.applianceCategory, 'dryer');
    expect(second.wrongReports.first.lastQuestionId, isNot('heat-observed'));
    expect(second.wrongReports.first.packageId, 'Dryer guide');
  });

  testWidgets('Settings Report a problem is reachable and saves mailto stub', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 16),
      store: store,
    );
    deps.createHousehold('Reachable House');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-report-wrong'));
    expect(find.byKey(const Key('settings-report-wrong')), findsOneWidget);
    expect(find.text(UserFacingCopy.reportWrongTitle), findsWidgets);
    await tapVisible(tester, find.byKey(const Key('settings-report-wrong')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('report-wrong-screen')), findsOneWidget);
    expect(find.byKey(const Key('report-wrong-privacy')), findsOneWidget);
    expect(find.text('Gallery'), findsNothing);
    expect(find.text('Camera'), findsNothing);
    await tester.enterText(
      find.byKey(const Key('report-wrong-note-field')),
      'Step told me to open a panel I should not.',
    );
    await tester.tap(find.byKey(const Key('report-wrong-save-email')));
    await tester.pumpAndSettle();
    expect(deps.wrongReports, hasLength(1));
    expect(deps.wrongReports.single.userNote, contains('open a panel'));
    expect(openedMail, hasLength(1));
    expect(openedMail.single.scheme, 'mailto');
    expect(
      openedMail.single.queryParameters['body'],
      contains('Appliance category:'),
    );
    expect(openedMail.single.queryParameters['body'], contains('Clue count:'));
    expect(openedMail.single.queryParameters['body'], isNot(contains('http')));
    expect(find.text(UserFacingCopy.reportWrongEmailOpened), findsOneWidget);
  });

  testWidgets('email unavailable still keeps the local note', (tester) async {
    reportWrongMailtoOpener = (uri) async => false;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 17),
      store: store,
    );
    deps.createHousehold('No Mail House');

    await prepareTallSurface(tester);
    await tester.pumpWidget(ModernButlerApp(dependencies: deps));
    await tester.tap(find.byKey(const Key('home-settings-button')));
    await tester.pumpAndSettle();
    await scrollSettingsUntil(tester, const Key('settings-report-wrong'));
    await tapVisible(tester, find.byKey(const Key('settings-report-wrong')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('report-wrong-note-field')),
      'Kept locally',
    );
    await tester.tap(find.byKey(const Key('report-wrong-save-email')));
    await tester.pumpAndSettle();
    expect(deps.wrongReports.single.userNote, 'Kept locally');
    expect(
      find.text(UserFacingCopy.reportWrongEmailUnavailable),
      findsOneWidget,
    );
  });

  testWidgets('This was wrong is on pro handoff after session end', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 18));
    await openDryerSession(tester, deps, 'Handoff Report House');
    await selectObservation(tester, 'heat-observed');
    await tapVisible(
      tester,
      find.byKey(const Key('answer-choice-no-warmth')),
    );
    await selectFailureMode(tester, 'heating-element-failed');
    await chooseCallAProFromDecision(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('outcome-needs-professional')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('outcome-save-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pro-handoff-screen')), findsOneWidget);
    expect(find.text(UserFacingCopy.reportWrongThisWasWrong), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('report-wrong-entry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('report-wrong-screen')), findsOneWidget);
    expect(find.byKey(const Key('report-wrong-category')), findsOneWidget);
    expect(find.textContaining('dryer'), findsWidgets);
    expect(find.text('Gallery'), findsNothing);
    expect(find.text('Camera'), findsNothing);
  });

  test('report path source does not invent telemetry or Groq diagnosis', () {
    final helper = _read('lib/helpers/report_wrong.dart');
    final screen = _read('lib/ui/report_wrong_screen.dart');
    for (final source in [helper, screen]) {
      expect(source.toLowerCase(), isNot(contains('datadog')));
      expect(source.toLowerCase(), isNot(contains('sentry')));
      expect(source.toLowerCase(), isNot(contains('firebase')));
      expect(source.toLowerCase(), isNot(contains('analytics')));
      expect(source, isNot(contains('GroqPhrasing')));
    }
    expect(helper, contains('mailto'));
    expect(helper, contains('kReportWrongSupportEmail'));
  });
}
