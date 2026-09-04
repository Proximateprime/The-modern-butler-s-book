import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/clue_copy.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/phrasing_request.dart';
import 'package:modern_butlers_book/helpers/phrasing_service.dart';
import 'package:modern_butlers_book/helpers/resume_open_observation.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/hypothesis.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_ui_resume_state.dart';
import 'package:modern_butlers_book/services/diagnostic_reasoning.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/session_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

String _read(String path) => File(path).readAsStringSync();

Finder _openQuestion(String templateId) {
  return find.descendant(
    of: find.byKey(const Key('answer-choice-panel')),
    matching: find.byKey(Key('observation-prompt-$templateId')),
  );
}

bool _lintFilterQuestionIsOpen() {
  return _openQuestion('lint-filter-condition').evaluate().isNotEmpty ||
      find
          .byKey(const Key('inspect-step-card-inspect-lint-filter'))
          .evaluate()
          .isNotEmpty;
}

bool _motorHummingQuestionIsOpen() {
  return _openQuestion('motor-audible').evaluate().isNotEmpty;
}

void _expectLintFilterRestored({required int clueCount}) {
  expect(find.byType(SessionScreen), findsOneWidget);
  expect(_lintFilterQuestionIsOpen(), isTrue);
  expect(_motorHummingQuestionIsOpen(), isFalse);
  expect(find.textContaining('motor humming'), findsNothing);
  expect(find.text(UserFacingCopy.emptyFurtherQuestionsTitle), findsNothing);
  expect(find.textContaining('No more questions for now'), findsNothing);
  expect(find.byKey(const Key('suggested-next-empty')), findsNothing);
  expect(find.byKey(const Key('observation-paused-message')), findsNothing);
  expect(find.textContaining('Following safe steps'), findsNothing);
  expect(find.textContaining('we were on the safe steps'), findsNothing);
  expect(find.text(householdClueSummary(clueCount)), findsWidgets);
}

void _addInterviewClue({
  required AppDependencies deps,
  required String sessionId,
  required String applianceId,
  required String templateId,
  required String observation,
  required String answer,
}) {
  deps.sessionCoordinator.addEvidence(
    evidence: Evidence(
      id: deps.nextId('evidence'),
      sessionId: sessionId,
      applianceId: applianceId,
      type: EvidenceType.structuredAnswer,
      observation: observation,
      answer: answer,
      templateId: templateId,
      collectedAt: deps.nextTimestamp(),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    ),
    evidenceLinkId: deps.nextId('evidence-link'),
  );
}

void _seedStarter({
  required AppDependencies deps,
  required String sessionId,
  required String applianceId,
  required String symptomId,
}) {
  final resolution = resolveDryerStarter(
    selectedSymptomIds: {symptomId},
  );
  deps.sessionCoordinator.addEvidence(
    evidence: Evidence(
      id: deps.nextId('evidence'),
      sessionId: sessionId,
      applianceId: applianceId,
      type: EvidenceType.textObservation,
      observation: "What's going on with the dryer?",
      answer: buildStarterComplaintAnswer(resolution: resolution),
      templateId: problemStarterComplaintTemplateId,
      collectedAt: deps.nextTimestamp(),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    ),
    evidenceLinkId: deps.nextId('evidence-link'),
  );
}

/// Six won't-start clues that leave lint-filter unanswered while ranking's
/// next template is motor humming.
void _seedSixCluesWontStartPath({
  required AppDependencies deps,
  required String sessionId,
  required String applianceId,
}) {
  _seedStarter(
    deps: deps,
    sessionId: sessionId,
    applianceId: applianceId,
    symptomId: 'will-not-start',
  );
  _addInterviewClue(
    deps: deps,
    sessionId: sessionId,
    applianceId: applianceId,
    templateId: 'door-closed-firmly',
    observation: 'Does the door click firmly shut and stay closed?',
    answer: 'Clicks shut firmly',
  );
  _addInterviewClue(
    deps: deps,
    sessionId: sessionId,
    applianceId: applianceId,
    templateId: 'panel-lights',
    observation: 'Do any lights, display, or control-panel indicators respond '
        'when you try to start?',
    answer: 'Yes, panel responds',
  );
  _addInterviewClue(
    deps: deps,
    sessionId: sessionId,
    applianceId: applianceId,
    templateId: 'drum-turns',
    observation: 'Does the drum turn during the cycle?',
    answer: 'Does not turn',
  );
  _addInterviewClue(
    deps: deps,
    sessionId: sessionId,
    applianceId: applianceId,
    templateId: 'door-held-closed-start',
    observation:
        'If you hold the door firmly closed and press Start, what happens?',
    answer: 'Still does nothing',
  );
  _addInterviewClue(
    deps: deps,
    sessionId: sessionId,
    applianceId: applianceId,
    templateId: 'control-lock-status',
    observation:
        'Look at the control panel: do you see a lock icon or Control Lock / Child Lock light?',
    answer: 'Lock off / not shown',
  );
  _addInterviewClue(
    deps: deps,
    sessionId: sessionId,
    applianceId: applianceId,
    templateId: 'outlet-power-check',
    observation:
        'What do you observe about power at the dryer outlet / breaker (no outlet dismantling)?',
    answer: 'Not sure',
  );
}

void _seedTwoCluesNoHeatPath({
  required AppDependencies deps,
  required String sessionId,
  required String applianceId,
}) {
  _seedStarter(
    deps: deps,
    sessionId: sessionId,
    applianceId: applianceId,
    symptomId: 'no-heat',
  );
  _addInterviewClue(
    deps: deps,
    sessionId: sessionId,
    applianceId: applianceId,
    templateId: 'drum-turns',
    observation: 'Does the drum turn during the cycle?',
    answer: 'Turns normally',
  );
}

/// Three no-heat clues with lint-filter still unanswered (Rex +18 Path A).
void _seedThreeCluesNoHeatPath({
  required AppDependencies deps,
  required String sessionId,
  required String applianceId,
}) {
  _seedTwoCluesNoHeatPath(
    deps: deps,
    sessionId: sessionId,
    applianceId: applianceId,
  );
  _addInterviewClue(
    deps: deps,
    sessionId: sessionId,
    applianceId: applianceId,
    templateId: 'vent-hose-condition',
    observation: 'vent hose',
    answer: 'Looks clear',
  );
}

void _confirmThermalFusePrimary({
  required AppDependencies deps,
  required String sessionId,
}) {
  deps.sessionCoordinator.attachHypothesis(
    Hypothesis(
      id: deps.nextId('hypothesis'),
      sessionId: sessionId,
      failureModeId: 'thermal-fuse-open',
      label: 'Thermal fuse open',
      currentConfidence: 0.8,
      status: HypothesisStatus.confirmed,
      schemaVersion: '1.0',
    ),
  );
}

Future<void> _continueAfterColdReload({
  required WidgetTester tester,
  required LocalDomainStore store,
  required DateTime clock,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  final second = AppDependencies(clock: () => clock, store: store);
  await second.restore();
  await prepareTallSurface(tester);
  await tester.pumpWidget(ModernButlerApp(dependencies: second));
  await tester.pumpAndSettle();

  expect(find.byType(SessionScreen), findsNothing);
  expect(find.text('Continue repair'), findsOneWidget);
  final restoredDryer = second.appliancesForCurrentHousehold().single;
  await tester.tap(find.byKey(Key('continue-repair-${restoredDryer.id}')));
  await tester.pumpAndSettle();
  await dismissProblemStarterIfPresent(tester);
}

void main() {
  test('version is 0.1.4+26', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+26');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+26'));
  });

  test('resume pack does not introduce Transform', () {
    for (final path in [
      'lib/main.dart',
      'lib/ui/home_screen.dart',
      'lib/ui/session_screen.dart',
      'lib/ui/app_dependencies.dart',
      'lib/services/local_domain_store.dart',
      'lib/helpers/phrasing_service.dart',
      'lib/helpers/resume_open_observation.dart',
    ]) {
      final source = _read(path);
      expect(source, isNot(contains('Transform(')));
      expect(source, isNot(contains('Transform.')));
    }
  });

  test('named primary does not block unanswered open observation hold', () {
    expect(
      shouldHoldUnansweredOpenInterviewOnResume(
        onScreenTemplateId: 'lint-filter-condition',
        onScreenStillOpen: true,
        hasRealClosePathProgress: false,
      ),
      isTrue,
    );
    expect(
      shouldHoldUnansweredOpenInterviewOnResume(
        onScreenTemplateId: 'lint-filter-condition',
        onScreenStillOpen: true,
        hasRealClosePathProgress: true,
      ),
      isFalse,
    );
    final restoreSource = _read('lib/ui/session_screen.dart');
    expect(
      restoreSource,
      contains('shouldHoldUnansweredOpenInterviewOnResume'),
    );
    expect(
      restoreSource.contains(
        'unansweredOpenObservationShouldStayOnScreen(\n'
        '            onScreenTemplateId: pendingTemplateId,\n'
        '            onScreenStillOpen: storedOpenStillOpen,\n'
        '          ) &&\n'
        '          decisionContext.primaryFailureModeId == null',
      ),
      isFalse,
    );
  });

  test('V2 A/B/C helper gates still hold', () {
    expect(
      preferOnScreenOpenObservationId(
        onScreenTemplateId: 'lint-filter-condition',
        rankingSuggestedNextTemplateId: 'motor-audible',
        onScreenStillOpen: true,
      ),
      'lint-filter-condition',
    );
    expect(
      preferOnScreenOpenObservationId(
        onScreenTemplateId: 'lint-filter-condition',
        rankingSuggestedNextTemplateId: null,
        onScreenStillOpen: true,
      ),
      'lint-filter-condition',
    );
    expect(
      resumeClosePathPhaseHonoringOpenObservation(
        computed: ClosePathPhase.guidance,
        unansweredOpenObservation: true,
      ),
      ClosePathPhase.conclusion,
    );
  });

  testWidgets(
    'primary named + unanswered lint-filter: Continue restores the question',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = DateTime.utc(2026, 9, 4, 20);
      final first = AppDependencies(clock: () => clock, store: store);
      first.createHousehold('V3 Primary Named House');
      final dryer = first.addDryer(energySource: ApplianceEnergySource.electric);
      final sessionId = first.startOrResumeSession(dryer);
      _seedThreeCluesNoHeatPath(
        deps: first,
        sessionId: sessionId,
        applianceId: dryer.id,
      );
      _confirmThermalFusePrimary(deps: first, sessionId: sessionId);
      first.saveSessionUiResume(
        sessionId,
        const SessionUiResumeState(
          pendingObservationTemplateId: 'lint-filter-condition',
          starterConfirmed: true,
          starterSymptomIds: ['no-heat'],
          closePathPhase: ClosePathPhase.conclusion,
        ),
      );
      await first.flushPersist();

      expect(
        first.buildDecisionContext(sessionId).primaryFailureModeId,
        'thermal-fuse-open',
      );

      await _continueAfterColdReload(
        tester: tester,
        store: store,
        clock: clock,
      );

      final restored = AppDependencies(clock: () => clock, store: store);
      await restored.restore();
      expect(
        restored.buildDecisionContext(sessionId).primaryFailureModeId,
        'thermal-fuse-open',
      );
      _expectLintFilterRestored(clueCount: 3);
      final onlyMostLikelyChrome = !_lintFilterQuestionIsOpen() &&
          (find.textContaining('Most likely').evaluate().isNotEmpty ||
              find
                  .textContaining('Reviewing the likely cause')
                  .evaluate()
                  .isNotEmpty);
      expect(onlyMostLikelyChrome, isFalse);
    },
  );

  testWidgets(
    'A: Continue restores lint-filter under conclusion, not motor humming',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = DateTime.utc(2026, 9, 4, 21);
      final first = AppDependencies(clock: () => clock, store: store);
      first.createHousehold('V3 Conclusion House');
      final dryer = first.addDryer(energySource: ApplianceEnergySource.electric);
      final sessionId = first.startOrResumeSession(dryer);
      _seedSixCluesWontStartPath(
        deps: first,
        sessionId: sessionId,
        applianceId: dryer.id,
      );
      first.saveSessionUiResume(
        sessionId,
        const SessionUiResumeState(
          pendingObservationTemplateId: 'lint-filter-condition',
          starterConfirmed: true,
          starterSymptomIds: ['will-not-start'],
          closePathPhase: ClosePathPhase.conclusion,
        ),
      );
      await first.flushPersist();

      final ranking = const DiagnosticReasoning().evaluateContext(
        first.buildDecisionContext(sessionId),
        starterMatchedSymptomIds: {'will-not-start'},
        energySource: dryer.energySource,
      );
      expect(ranking?.suggestedNextTemplateId, 'motor-audible');

      await _continueAfterColdReload(
        tester: tester,
        store: store,
        clock: clock,
      );

      final clueCount = interviewObservationsInOrder(
        first.repairSessionRepository.evidenceForSession(sessionId),
      ).length;
      _expectLintFilterRestored(clueCount: clueCount);
      expect(clueCount, greaterThanOrEqualTo(6));
    },
  );

  testWidgets(
    'B: Continue never paints No more questions while lint-filter is unanswered',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = DateTime.utc(2026, 9, 4, 22);
      final first = AppDependencies(clock: () => clock, store: store);
      first.createHousehold('V3 Blank Panel House');
      final dryer = first.addDryer(energySource: ApplianceEnergySource.electric);
      final sessionId = first.startOrResumeSession(dryer);
      _seedTwoCluesNoHeatPath(
        deps: first,
        sessionId: sessionId,
        applianceId: dryer.id,
      );
      first.saveSessionUiResume(
        sessionId,
        const SessionUiResumeState(
          pendingObservationTemplateId: 'lint-filter-condition',
          starterConfirmed: true,
          starterSymptomIds: ['no-heat'],
          closePathPhase: ClosePathPhase.conclusion,
          skipToBestGuess: true,
        ),
      );
      await first.flushPersist();

      await _continueAfterColdReload(
        tester: tester,
        store: store,
        clock: clock,
      );

      _expectLintFilterRestored(clueCount: 2);
      final banner = find.byKey(const Key('resume-knew-banner'));
      if (banner.evaluate().isNotEmpty) {
        final text = banner.evaluate().single.widget as Text;
        final spoken = text.data ?? '';
        expect(spoken, startsWith(kResumeKnewLead));
        expect(spoken.toLowerCase(), contains('question'));
        expect(resumeLineLeaksEngineeringPhase(spoken), isFalse);
      }
    },
  );

  testWidgets(
    'C: Continue never jumps unanswered lint-filter into guidance / safe-steps',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = DateTime.utc(2026, 9, 4, 23);
      final first = AppDependencies(clock: () => clock, store: store);
      first.createHousehold('V3 Guidance Steal House');
      final dryer = first.addDryer(energySource: ApplianceEnergySource.electric);
      final sessionId = first.startOrResumeSession(dryer);
      _seedStarter(
        deps: first,
        sessionId: sessionId,
        applianceId: dryer.id,
        symptomId: 'no-heat',
      );
      _addInterviewClue(
        deps: first,
        sessionId: sessionId,
        applianceId: dryer.id,
        templateId: 'vent-hose-condition',
        observation: 'vent hose',
        answer: 'Yes, restricted',
      );
      first.saveSessionUiResume(
        sessionId,
        const SessionUiResumeState(
          pendingObservationTemplateId: 'lint-filter-condition',
          starterConfirmed: true,
          starterSymptomIds: ['no-heat'],
          closePathPhase: ClosePathPhase.guidance,
        ),
      );
      await first.flushPersist();

      await _continueAfterColdReload(
        tester: tester,
        store: store,
        clock: clock,
      );

      _expectLintFilterRestored(clueCount: 2);
      expect(find.text('Now: Answering questions'), findsOneWidget);
      expect(find.text('Now: Following safe steps'), findsNothing);
      final banner = find.byKey(const Key('resume-knew-banner'));
      expect(banner, findsOneWidget);
      final spoken = (banner.evaluate().single.widget as Text).data ?? '';
      expect(spoken, startsWith(kResumeKnewLead));
      expect(spoken.toLowerCase(), isNot(contains('safe steps')));
      expect(spoken, contains('vent hose'));
      expect(spoken, contains('Yes, restricted'));
      expect(resumeLineLeaksEngineeringPhase(spoken), isFalse);
      expect(find.textContaining('I did this'), findsNothing);
    },
  );
}
