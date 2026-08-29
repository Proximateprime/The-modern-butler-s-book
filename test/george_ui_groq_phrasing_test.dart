import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/confidence_display.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/groq_phrasing.dart';
import 'package:modern_butlers_book/helpers/package_release_validator.dart';
import 'package:modern_butlers_book/helpers/phrasing_request.dart';
import 'package:modern_butlers_book/helpers/phrasing_safety_gate.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/helpers/why_ask_this.dart';
import 'package:modern_butlers_book/models/enrichment_note.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/inspect_step.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/repair_comfort_profile.dart';
import 'package:modern_butlers_book/models/session_ui_resume_state.dart';
import 'package:modern_butlers_book/services/enrichment_provider.dart';
import 'package:modern_butlers_book/services/groq_phrasing_client.dart';
import 'package:modern_butlers_book/services/groq_phrasing_service.dart';
import 'package:modern_butlers_book/services/question_selection_service.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/app_info.dart';

import 'support/session_test_helpers.dart';

GroqPhrasingRequest _questionRequest({
  List<String> options = const ['Yes', 'No', 'Not sure'],
  String comfort = 'normal',
  bool safetyCritical = false,
}) {
  return GroqPhrasingRequest(
    hook: GroqPhrasingHook.questionCard,
    family: 'dryer',
    energy: 'electric',
    state: 'evidence',
    comfort: comfort,
    evidenceNeeded: 'heat-observed',
    options: options,
    lastObs: 'no-heat: clothes stay damp',
    whyEngine: whyAskAuthoredByTemplateId['heat-observed']!,
    safety: 'none',
    packagedTitle: 'Did the dryer blow warm air?',
    packagedWhyOneLine: whyAskAuthoredByTemplateId['heat-observed']!,
    packagedOptionLabels: {for (final id in options) id: id},
    safetyCritical: safetyCritical,
  );
}

GroqPhrasingRequest _stopRequest({String comfort = 'normal'}) {
  return GroqPhrasingRequest(
    hook: GroqPhrasingHook.safetyStop,
    family: 'dryer',
    energy: 'unknown',
    state: 'stop',
    comfort: comfort,
    evidenceNeeded: 'safety-stop',
    options: const [],
    lastObs: 'hazard-observation: Yes',
    whyEngine: UserFacingCopy.safetyStopOfficial,
    safety: 'stop_unplug',
    packagedTitle: 'Possible fire or smoke hazard',
    packagedWhyOneLine: UserFacingCopy.safetyStopOfficial,
    safetyCritical: true,
  );
}

void main() {
  test('version is 0.1.4+3', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+3');
  });

  test('QuestionSelectionService still does not call Groq', () {
    final fake = FakeGroqPhrasingClient(
      response: const GroqPhrasingJson(title: 'should not run'),
    );
    const QuestionSelectionService().suggestNext(
      templates: const [],
      recordedEvidence: const [],
    );
    expect(fake.completeCalls, 0);
    expect(fake.liveNetworkCalls, 0);
    expect(fake.requests, isEmpty);
  });

  test('missing key client never posts and service stays packaged', () async {
    var posts = 0;
    final client = GroqOpenAiPhrasingClient(
      apiKey: '',
      httpPost: (uri, headers, body) async {
        posts += 1;
        return '{}';
      },
    );
    expect(client.hasApiKey, isFalse);
    final parsed = await client.complete(_questionRequest());
    expect(parsed, isNull);
    expect(posts, 0);

    final service = GroqPhrasingService(client: client);
    final accepted = await service.phrase(_questionRequest());
    expect(accepted.fromGroq, isFalse);
    expect(accepted.title, 'Did the dryer blow warm air?');
    expect(accepted.whyOneLine, whyAskAuthoredByTemplateId['heat-observed']);
    expect(service.liveNetworkCalls, 0);
  });

  test('timeout and validator reject fall back to packaged', () async {
    final timeoutClient = FakeGroqPhrasingClient(throwTimeout: true);
    final timeoutService = GroqPhrasingService(client: timeoutClient);
    final timedOut = await timeoutService.phrase(_questionRequest());
    expect(timedOut.fromGroq, isFalse);
    expect(timedOut.title, 'Did the dryer blow warm air?');

    final banned = acceptGroqPhrasing(
      request: _questionRequest(),
      parsed: const GroqPhrasingJson(
        title: 'Check the gas_train next',
        whyOneLine: 'A look, not a diagnosis.',
      ),
    );
    expect(banned, isNull);

    final extraOption = acceptGroqPhrasing(
      request: _questionRequest(),
      parsed: const GroqPhrasingJson(
        title: 'Was there warmth?',
        whyOneLine: 'This splits heat from airflow.',
        optionLabelsOnly: {
          'Yes': 'Warmth',
          'No': 'Cold',
          'Not sure': 'Unsure',
          'invented-chip': 'Fourth option',
        },
      ),
    );
    expect(extraOption, isNull);

    final liveVoltage = acceptGroqPhrasing(
      request: _questionRequest(),
      parsed: const GroqPhrasingJson(
        title: 'Measure live_voltage at the terminal',
        whyOneLine: 'Use a meter.',
      ),
    );
    expect(liveVoltage, isNull);

    final sealed = acceptGroqPhrasing(
      request: _questionRequest(),
      parsed: const GroqPhrasingJson(
        title: 'Open the sealed system',
        whyOneLine: 'Add refrigerant.',
      ),
    );
    expect(sealed, isNull);
  });

  test('stop shorten missing unplug-ventilate-don’t-keep-running is packaged',
      () {
    final rejected = acceptGroqPhrasing(
      request: _stopRequest(),
      parsed: const GroqPhrasingJson(
        whyOneLine: 'Stop and call someone when you can.',
      ),
    );
    expect(rejected, isNull);
    expect(
      safetyStopOfficialCopy(groqShortened: 'Just step away.'),
      UserFacingCopy.safetyStopOfficial,
    );

    const ok =
        'Unplug if safe, ventilate, and do not keep running the machine.';
    final accepted = acceptGroqPhrasing(
      request: _stopRequest(comfort: 'short'),
      parsed: const GroqPhrasingJson(whyOneLine: ok),
    );
    expect(accepted, isNotNull);
    expect(accepted!.fromGroq, isTrue);
    expect(safetyStopOfficialCopy(groqShortened: ok), ok);
    expect(
      safetyStopDisplayCopy(
        const SafetyStop(reason: 'Possible fire or smoke hazard'),
        groqShortenedOfficial: ok,
      ),
      contains('Unplug'),
    );
    expect(
      safetyStopDisplayCopy(
        const SafetyStop(reason: 'Possible fire or smoke hazard'),
      ),
      contains(UserFacingCopy.safetyStopOfficial),
    );
  });

  test('prefetch is the already-chosen next id only', () async {
    final fake = FakeGroqPhrasingClient(
      response: const GroqPhrasingJson(
        title: 'Any warmth from the drum?',
        whyOneLine: 'Warmth versus none splits airflow from no heat.',
      ),
    );
    final service = GroqPhrasingService(client: fake);
    final next = _questionRequest().copyWith(evidenceNeeded: 'heat-observed');
    await service.prefetchAlreadyChosenNext(next);
    expect(fake.requests, hasLength(1));
    expect(fake.requests.single.evidenceNeeded, 'heat-observed');
    expect(fake.requests.single.prefetchOnly, isTrue);
    expect(
      service.requestedEvidenceIds,
      ['heat-observed'],
    );
    expect(service.requestedEvidenceIds, isNot(contains('vent-hose-condition')));
    expect(service.requestedEvidenceIds, isNot(contains('lint-filter-condition')));
    expect(fake.liveNetworkCalls, 0);
  });

  test('Confirm ≠ Fixed phrasing cannot flip eligibility', () {
    final path = closePathForFailureMode('thermal-fuse-open')!;
    expect(path.allowResolvedWhenConfirmed, isFalse);
    expect(
      closeResolveEligibility(
        safetyStopActive: false,
        primaryFailureModeId: 'thermal-fuse-open',
        verificationOutcome: VerificationOutcome.supported,
        closePath: path,
      ),
      CloseResolveEligibility.needsProfessional,
    );

    final flipped = acceptGroqPhrasing(
      request: const GroqPhrasingRequest(
        hook: GroqPhrasingHook.confirmNotFixed,
        family: 'dryer',
        energy: 'electric',
        state: 'verify',
        comfort: 'normal',
        evidenceNeeded: 'thermal-fuse-open',
        options: [],
        lastObs: 'verified: Confirmed',
        whyEngine: kConfirmNotFixedPackaged,
        safety: 'none',
        packagedTitle: kConfirmNotFixedPackaged,
        packagedWhyOneLine: kConfirmNotFixedPackaged,
        allowResolvedWhenConfirmed: false,
        offersFixed: false,
      ),
      parsed: const GroqPhrasingJson(
        whyOneLine: 'Confirmed — you can record Fixed now.',
      ),
    );
    expect(flipped, isNull);
    expect(
      confirmNotFixedPhrasingFlipsEligibility(
        allowResolvedWhenConfirmed: false,
        phrasing: 'You can record Fixed.',
      ),
      isTrue,
    );

    final ok = acceptGroqPhrasing(
      request: const GroqPhrasingRequest(
        hook: GroqPhrasingHook.confirmNotFixed,
        family: 'dryer',
        energy: 'electric',
        state: 'verify',
        comfort: 'normal',
        evidenceNeeded: 'thermal-fuse-open',
        options: [],
        lastObs: 'verified: Confirmed',
        whyEngine: kConfirmNotFixedPackaged,
        safety: 'none',
        packagedTitle: kConfirmNotFixedPackaged,
        packagedWhyOneLine: kConfirmNotFixedPackaged,
        allowResolvedWhenConfirmed: false,
        offersFixed: false,
      ),
      parsed: const GroqPhrasingJson(whyOneLine: kConfirmNotFixedPackaged),
    );
    expect(ok, isNotNull);
    expect(path.allowResolvedWhenConfirmed, isFalse);
  });

  test('shorter comfort still keeps unplug/never/do not on safety-critical', () {
    const step =
        'Unplug first. Never test live. Do not keep running the machine.';
    final visibility = comfortStepVisibility(
      level: RepairComfortLevel.shorter,
      step: step,
    );
    expect(visibility.showFullStep, isTrue);
    expect(step.toLowerCase(), contains('unplug'));
    expect(step.toLowerCase(), contains('never'));
    expect(step.toLowerCase(), contains('do not'));

    final rejected = acceptGroqPhrasing(
      request: _stopRequest(comfort: 'short').copyWith(
        hook: GroqPhrasingHook.skillComfort,
        safetyCritical: true,
      ),
      parsed: const GroqPhrasingJson(
        whyOneLine: 'Keep going if you feel comfortable.',
      ),
    );
    expect(rejected, isNull);

    final accepted = acceptGroqPhrasing(
      request: _stopRequest(comfort: 'short').copyWith(
        hook: GroqPhrasingHook.skillComfort,
        safetyCritical: true,
      ),
      parsed: const GroqPhrasingJson(
        whyOneLine:
            'Unplug if safe, ventilate, and do not keep running the machine.',
      ),
    );
    expect(accepted, isNotNull);
    expect(groqComfortToken(RepairComfortLevel.shorter), 'short');
    expect(groqComfortToken(RepairComfortLevel.moreDetail), 'cautious');
    expect(groqComfortToken(RepairComfortLevel.standard), 'normal');
    const profile = RepairComfortProfile();
    expect(profile.levelFor('dryer'), RepairComfortLevel.standard);
  });

  test('whyAskThisQuestion remains packaged source of truth', () {
    final packaged = whyAskThisQuestion(templateId: 'heat-observed');
    expect(packaged.body, contains('Warmth versus no warmth'));
    final swapped = acceptGroqPhrasing(
      request: _questionRequest(),
      parsed: const GroqPhrasingJson(
        title: 'Any warmth from the clothes?',
        whyOneLine: 'Warm air versus cold air splits vent from heater.',
        optionLabelsOnly: {'Yes': 'Warm', 'No': 'Cold', 'Not sure': 'Unsure'},
      ),
    );
    expect(swapped, isNotNull);
    expect(swapped!.title, 'Any warmth from the clothes?');
    expect(whyAskThisQuestion(templateId: 'heat-observed').body, packaged.body);
  });

  test('novel question slot and confidence numbers are rejected', () {
    final novel = acceptGroqPhrasing(
      request: _questionRequest(),
      parsed: const GroqPhrasingJson(
        title:
            'First look at the vent. Then think about the fuse. After that '
            'consider the heater path and whether the house breaker tripped.',
      ),
    );
    expect(novel, isNull);

    final percent = acceptGroqPhrasing(
      request: _questionRequest(),
      parsed: const GroqPhrasingJson(
        title: 'Was there heat?',
        whyOneLine: 'This is 87% likely a fuse.',
      ),
    );
    expect(percent, isNull);
  });

  test('resume phrasing does not write SessionUiResumeState', () {
    const state = SessionUiResumeState(
      pendingObservationTemplateId: 'heat-observed',
    );
    final evidence = [
      Evidence(
        id: 'e1',
        sessionId: 's1',
        applianceId: 'a1',
        type: EvidenceType.structuredAnswer,
        observation: 'Did you notice warmth?',
        answer: 'No warmth',
        templateId: 'heat-observed',
        collectedAt: DateTime.utc(2026, 8, 29),
        collectedInState: RepairSessionState.evidenceCollection,
        source: EvidenceSource.user,
        schemaVersion: '1',
      ),
    ];
    final line = packagedResumeKnewLine(state: state, evidence: evidence);
    expect(line, startsWith(kResumeKnewLead));
    expect(state.pendingObservationTemplateId, 'heat-observed');
    expect(state.toJson()['pendingObservationTemplateId'], 'heat-observed');
  });

  testWidgets('offline with no key still shows packaged question and stop',
      (tester) async {
    final fake = FakeGroqPhrasingClient(hasApiKey: false);
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 29, 16),
      groqPhrasing: GroqPhrasingService(client: fake),
      isOnline: () => false,
    );
    await openDryerSession(
      tester,
      deps,
      'Groq Missing Key',
      skipProblemStarter: false,
    );
    expect(find.textContaining(UserFacingCopy.safetyStopOfficial), findsNothing);
    await tester.tap(find.byKey(const Key('starter-chip-hazard-signs')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('problem-starter-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
    expect(find.textContaining(UserFacingCopy.safetyStopOfficial), findsWidgets);
    expect(find.textContaining('Unplug if it is safe'), findsWidgets);
    expect(find.textContaining('ventilate'), findsWidgets);
    expect(fake.completeCalls, 0);
    expect(fake.liveNetworkCalls, 0);
  });

  test('Confirm ≠ Fixed packaged source of truth is the SuperGrok sentence', () {
    const closestShipped =
        'Confirming no warmth is not a completed repair.';
    expect(kConfirmNotFixedPackaged, UserFacingCopy.confirmNotFixedPackaged);
    expect(
      kConfirmNotFixedPackaged,
      'We confirmed the part is open. The dryer still isn’t fixed until '
      'heat returns.',
    );
    expect(kConfirmNotFixedPackaged, isNot(closestShipped));
    expect(
      closePathForFailureMode('thermal-fuse-open')!.safeGuidanceSteps.join(' '),
      contains(closestShipped),
    );
    expect(
      packagedConfirmNotFixedLine(
        allowResolvedWhenConfirmed: false,
        verificationSupported: true,
      ),
      kConfirmNotFixedPackaged,
    );
    final typed = PhrasingRequest.confirmNotFixed(
      family: 'dryer',
      energy: 'electric',
      comfort: 'normal',
      evidenceNeeded: 'thermal-fuse-open',
      lastObs: 'verified: Confirmed',
    );
    expect(typed.slot, PhrasingSlot.confirmNotFixed);
    expect(typed.packagedWhyOneLine, kConfirmNotFixedPackaged);
    expect(typed.allowResolvedWhenConfirmed, isFalse);
    expect(typed.offersFixed, isFalse);
  });

  test('attach-map gates reject unsafe instruction and percentages', () {
    expect(
      lineLooksLikeUnsafeInstruction('Bypass the thermal fuse with a jumper.'),
      isTrue,
    );
    expect(
      groqStringPassesSafetyGate(
        'Bypass the thermal fuse with a jumper.',
        requireOfficialStop: false,
      ),
      isFalse,
    );
    expect(standingLooksLikePercentage('87% likely'), isTrue);
    expect(
      groqStringPassesSafetyGate('This is 87% likely', requireOfficialStop: false),
      isFalse,
    );
    expect(
      groqStringPassesSafetyGate(
        'Unplug if safe, ventilate, and do not keep running.',
        requireOfficialStop: true,
      ),
      isTrue,
    );
    expect(
      groqStringPassesSafetyGate(
        'Just step away.',
        requireOfficialStop: true,
      ),
      isFalse,
    );
  });

  test('GOLDEN chrome labels are not paraphrased', () {
    expect(kGoldenChromeFrozenLabels, contains("I'll repair"));
    expect(kGoldenChromeFrozenLabels, contains('Call a pro'));
    expect(kGoldenChromeFrozenLabels, contains('Most likely'));
    expect(kGoldenChromeFrozenLabels, contains('Current question'));
    expect(kGoldenChromeFrozenLabels, contains(UserFacingCopy.whyAskThis));
    expect(kGoldenChromeFrozenLabels, contains('Continue repair'));
    expect(kGoldenChromeFrozenLabels, contains('Start repair'));
    expect(kGoldenChromeFrozenLabels, contains(inspectMatchesOkChip));
    expect(kGoldenChromeFrozenLabels, contains(inspectDoesntMatchChip));

    final remappedChip = acceptGroqPhrasing(
      request: _questionRequest(
        options: [inspectMatchesOkChip, inspectDoesntMatchChip],
      ),
      parsed: GroqPhrasingJson(
        title: 'Was there warmth?',
        optionLabelsOnly: {
          inspectMatchesOkChip: 'Looks fine',
          inspectDoesntMatchChip: inspectDoesntMatchChip,
        },
      ),
    );
    expect(remappedChip, isNull);

    final chromeTitle = acceptGroqPhrasing(
      request: _questionRequest(),
      parsed: const GroqPhrasingJson(title: 'Call a pro'),
    );
    expect(chromeTitle, isNull);
  });

  test('runtime enrichment stays stubbed and llm is not diagnosis', () {
    expect(kRuntimeEnrichmentCallsEnabled, isFalse);
    expect(const StubEnrichmentProvider(), isA<StubEnrichmentProvider>());
    expect(EnrichmentSource.llm.name, 'llm');
    expect(EnrichmentSource.llm, isNot(EnrichmentSource.household));
  });
}
