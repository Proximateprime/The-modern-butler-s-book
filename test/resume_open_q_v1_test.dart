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
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/appliance.dart';
import 'package:modern_butlers_book/models/evidence.dart';
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

/// Six won't-start clues that leave lint-filter unanswered while ranking's
/// next template is motor humming.
void _seedSixCluesWontStartPath({
  required AppDependencies deps,
  required String sessionId,
  required String applianceId,
}) {
  final resolution = resolveDryerStarter(
    selectedSymptomIds: const {'will-not-start'},
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

const _lintFilterResume = SessionUiResumeState(
  pendingObservationTemplateId: 'lint-filter-condition',
  starterConfirmed: true,
  starterSymptomIds: ['will-not-start'],
  closePathPhase: ClosePathPhase.conclusion,
);

void main() {
  test('version is 0.1.4+22', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+22');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+22'));
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

  test('on-screen open observation wins over ranking next', () {
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
        rankingSuggestedNextTemplateId: 'motor-audible',
        onScreenStillOpen: false,
      ),
      'motor-audible',
    );
  });

  test(
    'six wont-start clues rank motor humming next while lint-filter is still open',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 9, 4, 18),
        store: store,
      );
      deps.createHousehold('Rank Next House');
      final dryer = deps.addDryer(energySource: ApplianceEnergySource.electric);
      final sessionId = deps.startOrResumeSession(dryer);
      _seedSixCluesWontStartPath(
        deps: deps,
        sessionId: sessionId,
        applianceId: dryer.id,
      );
      final context = deps.buildDecisionContext(sessionId);
      final clues = interviewObservationsInOrder(context.evidence);
      final ids = clues.map((item) => item.templateId).toList();
      expect(ids, isNot(contains('lint-filter-condition')));
      expect(ids, isNot(contains('motor-audible')));
      expect(ids.length, greaterThanOrEqualTo(6));
      expect(
        interviewTemplateIsStillOpen(
          templateId: 'lint-filter-condition',
          templates: context.package!.evidenceTemplates,
          recordedEvidence: context.evidence,
        ),
        isTrue,
      );
      final ranking = const DiagnosticReasoning().evaluateContext(
        context,
        starterMatchedSymptomIds: {'will-not-start'},
        energySource: dryer.energySource,
      );
      expect(ranking?.suggestedNextTemplateId, 'motor-audible');
      expect(ranking?.suggestedNextTemplateId, isNot('lint-filter-condition'));
    },
  );

  testWidgets(
    'Continue repair keeps lint-filter when conclusion chrome and ranking next is motor humming',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = DateTime.utc(2026, 9, 4, 19);
      final first = AppDependencies(clock: () => clock, store: store);
      first.createHousehold('Open Q House');
      final dryer = first.addDryer(energySource: ApplianceEnergySource.electric);
      final sessionId = first.startOrResumeSession(dryer);
      _seedSixCluesWontStartPath(
        deps: first,
        sessionId: sessionId,
        applianceId: dryer.id,
      );
      first.saveSessionUiResume(sessionId, _lintFilterResume);
      await first.flushPersist();

      final ranking = const DiagnosticReasoning().evaluateContext(
        first.buildDecisionContext(sessionId),
        starterMatchedSymptomIds: {'will-not-start'},
        energySource: dryer.energySource,
      );
      expect(ranking?.suggestedNextTemplateId, 'motor-audible');

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

      expect(find.byType(SessionScreen), findsOneWidget);
      expect(_lintFilterQuestionIsOpen(), isTrue);
      expect(_motorHummingQuestionIsOpen(), isFalse);
      expect(find.textContaining('motor humming'), findsNothing);
      final banner = find.byKey(const Key('resume-knew-banner'));
      if (banner.evaluate().isNotEmpty) {
        final text = banner.evaluate().single.widget as Text;
        final spoken = text.data ?? '';
        expect(spoken, startsWith(kResumeKnewLead));
        expect(resumeLineLeaksEngineeringPhase(spoken), isFalse);
      }
      final afterIds = interviewObservationsInOrder(
        second.repairSessionRepository.evidenceForSession(
          second.repairSessionRepository.listAllSessions().single.id,
        ),
      ).map((item) => item.templateId).toList();
      expect(afterIds.length, greaterThanOrEqualTo(6));
      expect(afterIds, isNot(contains('lint-filter-condition')));
      expect(
        second
            .uiResumeForSession(
              second.repairSessionRepository.listAllSessions().single.id,
            )
            ?.pendingObservationTemplateId,
        'lint-filter-condition',
      );
      expect(find.text(householdClueSummary(afterIds.length)), findsWidgets);
    },
  );

  testWidgets(
    'Given lint-filter open and six clues, tap Continue after cold reload stays on lint-filter',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = DateTime.utc(2026, 9, 4, 20);
      final first = AppDependencies(clock: () => clock, store: store);
      first.createHousehold('Open Q Tap House');
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
          starterConfirmed: true,
          starterSymptomIds: ['will-not-start'],
          closePathPhase: ClosePathPhase.conclusion,
        ),
      );
      await first.flushPersist();

      await prepareTallSurface(tester);
      await tester.pumpWidget(ModernButlerApp(dependencies: first));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('continue-repair-${dryer.id}')));
      await tester.pumpAndSettle();
      await dismissProblemStarterIfPresent(tester);

      final beforeIds = interviewObservationsInOrder(
        first.repairSessionRepository.evidenceForSession(sessionId),
      ).map((item) => item.templateId).toList();
      expect(beforeIds.length, greaterThanOrEqualTo(6));
      expect(find.text(householdClueSummary(beforeIds.length)), findsWidgets);
      if (!_lintFilterQuestionIsOpen()) {
        await selectObservation(tester, 'lint-filter-condition');
      }
      expect(_lintFilterQuestionIsOpen(), isTrue);
      expect(_motorHummingQuestionIsOpen(), isFalse);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await first.flushPersist();

      final second = AppDependencies(clock: () => clock, store: store);
      await second.restore();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await prepareTallSurface(tester);
      await tester.pumpWidget(ModernButlerApp(dependencies: second));
      await tester.pumpAndSettle();

      final restoredDryer = second.appliancesForCurrentHousehold().single;
      await tester.tap(find.byKey(Key('continue-repair-${restoredDryer.id}')));
      await tester.pumpAndSettle();
      await dismissProblemStarterIfPresent(tester);

      expect(_lintFilterQuestionIsOpen(), isTrue);
      expect(_motorHummingQuestionIsOpen(), isFalse);
      expect(find.text(householdClueSummary(beforeIds.length)), findsWidgets);
      expect(find.textContaining('motor humming'), findsNothing);
      final afterIds = interviewObservationsInOrder(
        second.repairSessionRepository.evidenceForSession(
          second.repairSessionRepository.listAllSessions().single.id,
        ),
      ).map((item) => item.templateId).toList();
      expect(afterIds, beforeIds);
    },
  );
}
