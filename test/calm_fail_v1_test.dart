import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/degraded_mode.dart';
import 'package:modern_butlers_book/helpers/package_resolve.dart';
import 'package:modern_butlers_book/helpers/package_usability.dart';
import 'package:modern_butlers_book/helpers/phrasing_request.dart';
import 'package:modern_butlers_book/helpers/phrasing_service.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/helpers/why_ask_this.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/household.dart';
import 'package:modern_butlers_book/models/knowledge_package.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/diagnostic_reasoning.dart';
import 'package:modern_butlers_book/services/groq_phrasing_client.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/services/voice_answer.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/error_banner.dart';

import 'support/session_test_helpers.dart';

String _read(String path) => File(path).readAsStringSync();

KnowledgePackage _thinDryerPackage({
  bool includeHazardTemplate = true,
  bool emptyId = false,
}) {
  return KnowledgePackage(
    id: emptyId ? '' : 'dryer-core',
    category: 'dryer',
    version: '0.0.1-thin',
    displayName: 'Thin dryer fixture',
    schemaVersion: '1.0',
    failureModes: const [],
    symptoms: const [],
    evidenceTemplates: includeHazardTemplate
        ? [
            EvidenceTemplate(
              id: 'hazard-observation',
              promptText:
                  'Any smoke, burning smell, sparking, or melting?',
              expectedEvidenceType: EvidenceType.structuredAnswer,
              relatedFailureModeIds: const [],
              answerChoices: const ['Yes', 'No', 'Not sure'],
            ),
          ]
        : const [],
    safeChecks: const [],
    createdAt: DateTime.utc(2026, 9, 4),
    source: 'test-fixture',
    status: KnowledgePackageStatus.staging,
  );
}

Evidence _structured({
  required String templateId,
  required String answer,
  String observation = 'observation',
}) {
  return Evidence(
    id: 'e-$templateId',
    sessionId: 'session-1',
    applianceId: 'appliance-1',
    type: EvidenceType.structuredAnswer,
    observation: observation,
    answer: answer,
    templateId: templateId,
    collectedAt: DateTime.utc(2026, 9, 4),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1.0',
  );
}

GroqPhrasingRequest _questionRequest() {
  return GroqPhrasingRequest(
    hook: GroqPhrasingHook.questionCard,
    family: 'dryer',
    energy: 'electric',
    state: 'evidence',
    comfort: 'normal',
    evidenceNeeded: 'heat-observed',
    options: const ['Yes', 'No', 'Not sure'],
    lastObs: 'no-heat: clothes stay damp',
    whyEngine: whyAskAuthoredByTemplateId['heat-observed']!,
    safety: 'none',
    packagedTitle: 'Did the dryer blow warm air?',
    packagedWhyOneLine: whyAskAuthoredByTemplateId['heat-observed']!,
    packagedOptionLabels: const {
      'Yes': 'Yes',
      'No': 'No',
      'Not sure': 'Not sure',
    },
  );
}

void main() {
  test('version is 0.1.4+19', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+19');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+19'));
  });

  test('GOLDEN Call a pro stays frozen', () {
    expect(kGoldenChromeFrozenLabels, contains('Call a pro'));
  });

  test('offline Groq uses packaged copy and does not call the network', () async {
    final client = FakeGroqPhrasingClient(
      hasApiKey: true,
      response: GroqPhrasingJson(title: 'Invented diagnosis'),
    );
    final service = GroqPhrasingService(
      client: client,
      isOnline: () => false,
    );
    expect(service.shouldCallNetwork, isFalse);
    final accepted = await service.phrase(_questionRequest());
    expect(accepted.fromGroq, isFalse);
    expect(accepted.title, 'Did the dryer blow warm air?');
    expect(client.completeCalls, 0);
  });

  test('missing Groq model maps to calm copy and packaged phrasing', () async {
    expect(
      userFacingErrorMessage(StateError('model_not_found llama-3')),
      UserFacingCopy.onDeviceModelUnavailable,
    );
    final client = FakeGroqPhrasingClient(hasApiKey: true, throwTimeout: true);
    final service = GroqPhrasingService(client: client);
    final accepted = await service.phrase(_questionRequest());
    expect(accepted.fromGroq, isFalse);
    expect(accepted.title, isNot(contains('Exception')));
  });

  test('full dryer package still diagnoses from templates without Groq', () {
    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    const reasoning = DiagnosticReasoning();
    final result = reasoning.evaluate(
      package: package,
      evidence: [
        _structured(templateId: 'drum-turns', answer: 'Turns normally'),
        _structured(templateId: 'heat-observed', answer: 'No warmth'),
      ],
    );
    expect(result.orderedFailureModes, isNotEmpty);
    expect(result.suggestedNextTemplateId, isNotNull);
    expect(
      result.orderedFailureModes.map((mode) => mode.id),
      isNot(contains('invented-failure-mode')),
    );
  });

  test('thin dryer package does not invent failure modes or part swaps', () {
    final thin = _thinDryerPackage();
    expect(assessKnowledgePackage(thin), PackageUsabilityKind.thin);
    expect(packageCanDiagnose(thin), isFalse);
    expect(
      closePathIfAuthoredInPackage(
        package: thin,
        failureModeId: 'thermal-fuse-open',
      ),
      isNull,
    );

    const reasoning = DiagnosticReasoning();
    final result = reasoning.evaluate(
      package: thin,
      evidence: [
        _structured(templateId: 'heat-observed', answer: 'No warmth'),
      ],
    );
    expect(result.orderedFailureModes, isEmpty);
    expect(result.recommendPrimaryFailureModeId, isNull);
    expect(result.clearLeaderFailureModeId, isNull);
    expect(result.closePath, isNull);
    expect(result.topFailureModeIds, isEmpty);
    expect(result.suggestedNextTemplateId, isNot(equals('heat-observed')));
    expect(
      result.suggestedNextTemplateId == null ||
          result.suggestedNextTemplateId == 'hazard-observation',
      isTrue,
    );
  });

  test('missing package does not invent a family guide', () {
    final repo = KnowledgePackageRepository(initialPackages: const []);
    expect(
      tryResolveKnowledgePackage(repository: repo, category: 'dryer'),
      isNull,
    );
    expect(
      userFacingErrorMessage(
        StateError('No knowledge package is installed for dryer.'),
      ),
      UserFacingCopy.packageUnavailable,
    );
  });

  test('corrupt package is not treated as diagnosable', () {
    final corrupt = _thinDryerPackage(emptyId: true);
    expect(assessKnowledgePackage(corrupt), PackageUsabilityKind.corrupt);
    expect(packageCanDiagnose(corrupt), isFalse);
    expect(degradedModeMessage(DegradedModeKind.packageCorrupt), UserFacingCopy.packageCorrupt);
    expect(degradedModeMessage(DegradedModeKind.packageThin), UserFacingCopy.cantHelpYet);
  });

  test('safety stop still fires on a thin package from hazard evidence', () {
    final stop = evaluateSafetyStop(
      evidence: [
        _structured(
          templateId: 'hazard-observation',
          answer: 'Yes',
          observation: 'Any smoke, burning smell, sparking, or melting?',
        ),
      ],
    );
    expect(stop, isNotNull);
    expect(stop!.reason.toLowerCase(), contains('fire'));
    expect(UserFacingCopy.safetyStopOfficial.toLowerCase(), contains('unplug'));
  });

  test('corrupt resume row is dropped without wiping the household', () {
    final snapshot = DomainSnapshot(
      idCounter: 2,
      lastTimestamp: DateTime.utc(2026, 9, 4, 12),
      currentHouseholdId: 'household-1',
      sessionIdByApplianceId: const {},
      packageRefsBySession: const {},
      households: [
        Household(
          id: 'household-1',
          name: 'Keep this house',
          ownerUserId: 'owner-1',
          createdAt: DateTime.utc(2026, 9, 4),
          schemaVersion: '1.0',
        ),
      ],
      appliances: const [],
      sessions: const [],
      evidence: const [],
      evidenceLinks: const [],
      hypotheses: const [],
      hypothesisIdsBySession: const {},
      outcomes: const [],
    );
    final raw = Map<String, dynamic>.from(snapshot.toJson());
    raw['sessionUiResumeBySessionId'] = {
      'session-bad': 'not-a-map',
      'session-nulls': {
        'pendingObservationTemplateId': 12,
        'starterSymptomIds': 'nope',
        'guidanceStepIndex': 'three',
      },
    };
    final restored = DomainSnapshot.fromJson(raw);
    expect(restored.households.single.name, 'Keep this house');
    expect(restored.sessionUiResumeBySessionId.containsKey('session-bad'), isFalse);
    final kept = restored.sessionUiResumeBySessionId['session-nulls'];
    expect(kept, isNotNull);
    expect(kept!.pendingObservationTemplateId, isNull);
    expect(kept.starterSymptomIds, isEmpty);
    expect(kept.guidanceStepIndex, 0);
  });

  test('start without a dryer package throws household copy, not a stack', () {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 15),
      knowledgePackageRepository: KnowledgePackageRepository(
        initialPackages: const [],
      ),
    );
    deps.createHousehold('Missing Pack House');
    final dryer = deps.addDryer();
    expect(
      () => deps.startOrResumeSession(dryer),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          UserFacingCopy.packageUnavailable,
        ),
      ),
    );
  });

  testWidgets('offline dryer session still asks and is not a crash screen', (
    tester,
  ) async {
    final client = FakeGroqPhrasingClient(hasApiKey: true);
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 16),
      isOnline: () => false,
      groqPhrasing: GroqPhrasingService(
        client: client,
        isOnline: () => false,
      ),
    );
    await openDryerSession(
      tester,
      deps,
      'Calm Offline',
      skipProblemStarter: false,
    );
    expect(find.byKey(const Key('session-offline-banner')), findsOneWidget);
    expect(find.text(UserFacingCopy.offlineGuidesStillWork), findsWidgets);
    expect(find.text("What's going on?"), findsOneWidget);
    expect(find.text('No heat'), findsOneWidget);
    expect(find.byKey(const Key('calm-error-screen')), findsNothing);
    expect(find.textContaining('#0'), findsNothing);
    expect(client.completeCalls, 0);
  });

  testWidgets('thin package session shows can’t-help-yet and no invented FMs', (
    tester,
  ) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 17),
      knowledgePackageRepository: KnowledgePackageRepository(
        initialPackages: [_thinDryerPackage()],
      ),
    );
    await openDryerSession(tester, deps, 'Thin Pack House');
    expect(find.byKey(const Key('session-thin-package-banner')), findsOneWidget);
    expect(find.text(UserFacingCopy.cantHelpYet), findsOneWidget);
    expect(find.byKey(const Key('skip-to-best-guess')), findsNothing);
    expect(find.textContaining('thermal fuse'), findsNothing);
    expect(find.textContaining('Restricted vent'), findsNothing);
    expect(find.textContaining('#0'), findsNothing);
  });

  testWidgets('unavailable mic shows calm copy and keeps chips', (tester) async {
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 9, 4, 18),
      voiceAnswer: ScriptedVoiceAnswerListener(
        VoiceAnswerCapture.unavailable,
      ),
    );
    await openDryerSession(tester, deps, 'Mic Unavailable');
    await tapVisible(tester, find.byKey(const Key('voice-answer-mic')));
    expect(find.byKey(const Key('error-banner-microphone')), findsOneWidget);
    expect(find.text(UserFacingCopy.voicePermissionDenied), findsOneWidget);
    expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
    expect(find.textContaining('Exception:'), findsNothing);
  });

  testWidgets('calm error widget never paints a stack', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: butlerErrorWidget(
          FlutterErrorDetails(exception: StateError('engine dump\n#0 foo')),
        ),
      ),
    );
    expect(find.byKey(const Key('calm-error-screen')), findsOneWidget);
    expect(find.text(UserFacingCopy.genericError), findsOneWidget);
    expect(find.textContaining('#0'), findsNothing);
    expect(find.textContaining('StateError'), findsNothing);
  });
}
