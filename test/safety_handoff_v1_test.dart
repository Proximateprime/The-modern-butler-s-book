import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/helpers/groq_phrasing.dart';
import 'package:modern_butlers_book/helpers/guidance_display.dart';
import 'package:modern_butlers_book/helpers/phrasing_safety_gate.dart';
import 'package:modern_butlers_book/helpers/pro_handoff.dart';
import 'package:modern_butlers_book/helpers/pro_scope.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('version is 0.1.4+26', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+26');
  });

  test(
    'burning-smell-only session does not copy unused vent checklist or why',
    () {
      final evidence = [_burningSmellEvidence()];
      final outcome = _ventLeaderOutcome();

      expect(
        alreadyTriedStepsForLeader('restricted-exhaust-airflow'),
        isNotEmpty,
        reason: 'canned checklist still exists for formatter/tests',
      );

      final tried = alreadyTriedFromSession(
        evidence: evidence,
        leaderFailureModeId: 'restricted-exhaust-airflow',
      );
      expect(tried, isEmpty);

      final text = formatProHandoffForSession(
        evidence: evidence,
        applianceName: 'Laundry Room Dryer',
        outcome: outcome,
      );
      final lower = text.toLowerCase();

      expect(text, contains('What was already tried'));
      expect(text, contains('• None recorded'));
      expect(lower, isNot(contains('lint filter')));
      expect(lower, isNot(contains('vent hood')));
      expect(lower, isNot(contains('visible vent hose')));
      expect(text, isNot(contains('exhaust restriction')));
      expect(lower, isNot(contains('checks were done')));
      expect(lower, contains('needs a professional'));
      expect(lower, contains('fire or smoke'));
      expect(text, contains(leftoverLeaderPrefix));
      expect(text, contains('Restricted vent'));
      expect(text, contains('not why we stopped'));
      expect(text, isNot(contains('not a confirmed diagnosis')));

      final spoken = formatProHandoffSpokenForSession(
        evidence: evidence,
        applianceName: 'Laundry Room Dryer',
        outcome: outcome,
      );
      expect(spoken.toLowerCase(), contains('none recorded'));
      expect(spoken.toLowerCase(), contains('needs a professional'));
      expect(spoken.toLowerCase(), contains('fire or smoke'));
      expect(spoken.toLowerCase(), isNot(contains('lint filter')));
      expect(spoken.toLowerCase(), isNot(contains('vent hood')));
      expect(spoken, isNot(contains('exhaust restriction')));
      expect(spoken, contains('not a diagnosis'));
    },
  );

  test(
    'burning-smell spoken paragraph includes safety why, not unused vent checks',
    () {
      final spoken = formatProHandoffSpokenForSession(
        evidence: [_burningSmellEvidence()],
        applianceName: 'Laundry Room Dryer',
        outcome: _ventLeaderOutcome(),
      );
      final lower = spoken.toLowerCase();
      expect(lower, contains('needs a professional'));
      expect(lower, contains('fire or smoke'));
      expect(lower, contains('none recorded'));
      expect(lower, isNot(contains('lint filter')));
      expect(lower, isNot(contains('vent hood')));
      expect(spoken, isNot(contains('exhaust restriction')));
      expect(spoken, contains('Restricted vent'));
      expect(spoken, contains('not a diagnosis'));
    },
  );

  test('completed guidance ids become alreadyTried; unused steps do not', () {
    final path = closePathForFailureMode('heating-element-failed')!;
    final steps = safeCheckGuidanceSteps(path.safeGuidanceSteps);
    final index = steps.indexWhere(
      (step) => step.toLowerCase().contains('heat cycle is selected'),
    );
    expect(index, greaterThanOrEqualTo(0));
    final completedWhat = guidanceForSafeStep(steps[index]).what;

    final text = formatProHandoffForSession(
      evidence: const [],
      applianceName: 'Dryer',
      outcome: SessionOutcome(
        sessionId: 's-heat',
        resolutionStatus: SessionResolutionStatus.partiallyResolved,
        closeKind: SessionCloseKind.calledProfessional,
        immediateCause: 'Heating element',
        contributingFactors: const [],
        preventiveActions: const [],
        verified: false,
        schemaVersion: '1.0',
        rankingLeaderFailureModeId: 'heating-element-failed',
        rankingLeaderLabel: 'Heating element open or failed',
      ),
      completedGuidanceStepIds: [guidanceStepId(index, steps[index])],
    );

    expect(text, contains(completedWhat));
    expect(text.toLowerCase(), isNot(contains('lint filter')));
    expect(text.toLowerCase(), isNot(contains('vent hood')));
  });

  test('Groq may phrase but must not invent unused lint/vent tried steps', () {
    final packaged = packagedProHandoffSpokenParagraph(
      applianceName: 'Dryer',
      symptom: 'Burning smell / smoke',
      observations: const [],
      alreadyTried: const [],
      leaderHypothesis: 'Restricted vent',
      whyStopping: 'Needs a professional. Possible fire or smoke hazard.',
    );
    expect(packaged.toLowerCase(), contains('none recorded'));
    expect(packaged.toLowerCase(), contains('needs a professional'));
    expect(packaged.toLowerCase(), contains('fire or smoke'));

    final invented = acceptGroqPhrasing(
      request: PhrasingRequest.proHandoff(
        family: 'dryer',
        energy: 'unknown',
        comfort: 'normal',
        packagedParagraph: packaged,
      ),
      parsed: const GroqPhrasingJson(
        whyOneLine:
            'Please look at this dryer. We already tried the lint filter '
            'and vent hood. Exhaust restriction was why we stopped.',
      ),
    );
    expect(invented, isNull);

    final droppedWhy = acceptGroqPhrasing(
      request: PhrasingRequest.proHandoff(
        family: 'dryer',
        energy: 'unknown',
        comfort: 'normal',
        packagedParagraph: packaged,
      ),
      parsed: const GroqPhrasingJson(
        whyOneLine:
            'Please look at this dryer. Already tried: none recorded. '
            'Leading match is Restricted vent — not a diagnosis.',
      ),
    );
    expect(droppedWhy, isNull);

    final phrasedWhy = acceptGroqPhrasing(
      request: PhrasingRequest.proHandoff(
        family: 'dryer',
        energy: 'unknown',
        comfort: 'normal',
        packagedParagraph: packaged,
      ),
      parsed: const GroqPhrasingJson(
        whyOneLine:
            'Please look at this dryer. Already tried: none recorded. '
            'Why we stopped: Needs a professional because of a possible '
            'fire or smoke hazard. Leading match is Restricted vent — '
            'not a diagnosis.',
      ),
    );
    expect(phrasedWhy, isNotNull);
    expect(phrasedWhy!.whyOneLine.toLowerCase(), contains('needs a professional'));
    expect(phrasedWhy.whyOneLine.toLowerCase(), contains('fire or smoke'));

    final spoken = formatProHandoffSpokenForSession(
      evidence: [_burningSmellEvidence()],
      applianceName: 'Dryer',
      outcome: _ventLeaderOutcome(),
      groqParagraph:
          'We already tried the lint filter and checked the vent hood.',
    );
    expect(spoken.toLowerCase(), contains('none recorded'));
    expect(spoken.toLowerCase(), contains('needs a professional'));
    expect(spoken.toLowerCase(), contains('fire or smoke'));
    expect(spoken.toLowerCase(), isNot(contains('lint filter')));
    expect(spoken.toLowerCase(), isNot(contains('vent hood')));
  });

  testWidgets(
    'burning-smell chip only: stop chrome uses one clue count',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 22));
      await openDryerSession(
        tester,
        deps,
        'Handoff Honesty House',
        skipProblemStarter: false,
      );
      await tester.tap(find.byKey(const Key('starter-chip-hazard-signs')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem-starter-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
      expect(find.text('No clues yet'), findsWidgets);
      expect(find.text('Evidence count: 1'), findsNothing);
      final count = tester.widget<Text>(
        find.byKey(const Key('context-evidence-count')),
      );
      expect(count.data, 'No clues yet');
    },
  );

  testWidgets(
    'burning-smell chip only: handoff is empty tried and safety why',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 29, 22, 5));
      await openDryerSession(
        tester,
        deps,
        'Smell Handoff House',
        skipProblemStarter: false,
      );
      await tester.tap(find.byKey(const Key('starter-chip-hazard-signs')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem-starter-confirm')));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const Key('end-session-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('outcome-needs-professional')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('outcome-save-button')));
      await tester.tap(find.byKey(const Key('outcome-save-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pro-handoff-screen')), findsOneWidget);
      final preview = tester.widget<SelectableText>(
        find.byKey(const Key('pro-handoff-preview')),
      );
      final body = preview.data ?? '';
      final lower = body.toLowerCase();
      expect(body, contains('Technician handoff'));
      expect(body, contains('• None recorded'));
      expect(lower, isNot(contains('lint filter')));
      expect(lower, isNot(contains('vent hood')));
      expect(body, isNot(contains('exhaust restriction')));
      expect(lower, contains('needs a professional'));
      expect(lower, contains('fire or smoke'));
      expect(body, contains('not why we stopped'));
      expect(body, isNot(contains('not a confirmed diagnosis')));

      final spoken = tester.widget<SelectableText>(
        find.byKey(const Key('pro-handoff-spoken')),
      );
      final spokenBody = spoken.data ?? '';
      expect(spokenBody.toLowerCase(), contains('none recorded'));
      expect(spokenBody.toLowerCase(), contains('needs a professional'));
      expect(spokenBody.toLowerCase(), contains('fire or smoke'));
      expect(spokenBody.toLowerCase(), isNot(contains('lint filter')));
      expect(spokenBody.toLowerCase(), isNot(contains('vent hood')));
      expect(spokenBody, isNot(contains('exhaust restriction')));
      expect(spokenBody, contains('not a diagnosis'));
    },
  );
}

Evidence _burningSmellEvidence() {
  return Evidence(
    id: 'e-smell',
    sessionId: 's-smell',
    applianceId: 'a-1',
    type: EvidenceType.textObservation,
    observation: "What's going on with the dryer?",
    answer: 'Burning smell / smoke',
    templateId: problemStarterComplaintTemplateId,
    collectedAt: DateTime.utc(2026, 8, 29, 22),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1.0',
  );
}

SessionOutcome _ventLeaderOutcome() {
  return SessionOutcome(
    sessionId: 's-smell',
    resolutionStatus: SessionResolutionStatus.partiallyResolved,
    closeKind: SessionCloseKind.calledProfessional,
    immediateCause: 'Restricted vent',
    contributingFactors: const [],
    preventiveActions: const [],
    verified: false,
    schemaVersion: '1.0',
    rankingLeaderFailureModeId: 'restricted-exhaust-airflow',
    rankingLeaderLabel: 'Restricted vent',
    startSymptom: 'Burning smell / smoke',
  );
}
