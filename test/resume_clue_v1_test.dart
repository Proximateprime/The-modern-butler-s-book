import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/clue_copy.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/phrasing_request.dart';
import 'package:modern_butlers_book/helpers/phrasing_service.dart';
import 'package:modern_butlers_book/main.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/models/session_ui_resume_state.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/session_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

String _read(String path) => File(path).readAsStringSync();

class _GatedDomainStore extends LocalDomainStore {
  _GatedDomainStore({
    required SharedPreferences preferences,
    required this.firstSave,
  }) : super(preferences: preferences);

  final Completer<void> firstSave;
  int saveCalls = 0;

  @override
  Future<void> save(DomainSnapshot snapshot) async {
    saveCalls += 1;
    if (saveCalls == 1) {
      await firstSave.future;
    }
    await super.save(snapshot);
  }
}

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

void _expectNoEngineeringPhaseChrome() {
  final banner = find.byKey(const Key('resume-knew-banner'));
  if (banner.evaluate().isEmpty) {
    return;
  }
  final text = banner.evaluate().single.widget as Text;
  final spoken = text.data ?? '';
  expect(spoken, startsWith(kResumeKnewLead));
  expect(resumeLineLeaksEngineeringPhase(spoken), isFalse);
}

void main() {
  test('version is 0.1.4+16', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+16');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+16'));
  });

  test('resume pack does not introduce Transform', () {
    for (final path in [
      'lib/main.dart',
      'lib/ui/home_screen.dart',
      'lib/ui/session_screen.dart',
      'lib/ui/app_dependencies.dart',
      'lib/services/local_domain_store.dart',
      'lib/helpers/phrasing_service.dart',
    ]) {
      final source = _read(path);
      expect(source, isNot(contains('Transform(')));
      expect(source, isNot(contains('Transform.')));
    }
  });

  test('resume chrome uses household voice, not tools/guidance phase names', () {
    const tools = SessionUiResumeState(closePathPhase: ClosePathPhase.tools);
    const guidance = SessionUiResumeState(
      closePathPhase: ClosePathPhase.guidance,
    );
    final toolsLine = packagedResumeKnewLine(state: tools, evidence: const []);
    final guidanceLine = packagedResumeKnewLine(
      state: guidance,
      evidence: const [],
    );
    expect(toolsLine, startsWith(kResumeKnewLead));
    expect(guidanceLine, startsWith(kResumeKnewLead));
    expect(resumeLineLeaksEngineeringPhase(toolsLine), isFalse);
    expect(resumeLineLeaksEngineeringPhase(guidanceLine), isFalse);
    expect(toolsLine.toLowerCase(), isNot(contains('we were in tools')));
    expect(guidanceLine.toLowerCase(), isNot(contains('we were in guidance')));
  });

  test(
    'in-flight snapshot write recaptures later clues and the open question',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final firstSave = Completer<void>();
      final store = _GatedDomainStore(preferences: prefs, firstSave: firstSave);
      final clock = DateTime.utc(2026, 9, 4, 16);
      final first = AppDependencies(clock: () => clock, store: store);

      first.createHousehold('Gated Clues');
      final dryer = first.addDryer();
      final sessionId = first.startOrResumeSession(dryer);
      first.saveSessionUiResume(
        sessionId,
        const SessionUiResumeState(
          pendingObservationTemplateId: 'drum-turns',
          starterConfirmed: true,
          starterSymptomIds: ['no-heat'],
        ),
      );

      await Future<void>.delayed(Duration.zero);
      expect(store.saveCalls, 1);

      void addClue({
        required String templateId,
        required String observation,
        required String answer,
      }) {
        first.sessionCoordinator.addEvidence(
          evidence: Evidence(
            id: first.nextId('evidence'),
            sessionId: sessionId,
            applianceId: dryer.id,
            type: EvidenceType.structuredAnswer,
            observation: observation,
            answer: answer,
            templateId: templateId,
            collectedAt: first.nextTimestamp(),
            collectedInState: RepairSessionState.evidenceCollection,
            source: EvidenceSource.user,
            schemaVersion: '1.0',
          ),
          evidenceLinkId: first.nextId('evidence-link'),
        );
      }

      addClue(
        templateId: 'heat-observed',
        observation: 'Did you notice warmth during the cycle?',
        answer: 'No warmth',
      );
      addClue(
        templateId: 'drum-turns',
        observation: 'Does the drum turn during the cycle?',
        answer: 'Turns normally',
      );
      first.saveSessionUiResume(
        sessionId,
        const SessionUiResumeState(
          pendingObservationTemplateId: 'lint-filter-condition',
          starterConfirmed: true,
          starterSymptomIds: ['no-heat'],
        ),
      );

      firstSave.complete();
      await first.flushPersist();

      final second = AppDependencies(clock: () => clock, store: store);
      await second.restore();
      final clues = interviewObservationsInOrder(
        second.repairSessionRepository.evidenceForSession(sessionId),
      );
      expect(clues, hasLength(2));
      expect(
        second.uiResumeForSession(sessionId)?.pendingObservationTemplateId,
        'lint-filter-condition',
      );
      expect(second.hasInProgressSession(second.appliancesForCurrentHousehold().single), isTrue);
    },
  );

  testWidgets(
    'cold reload Continue repair keeps lint-filter question and both clues',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalDomainStore(preferences: prefs);
      final clock = DateTime.utc(2026, 9, 4, 17);
      final first = AppDependencies(clock: () => clock, store: store);

      await openDryerSession(
        tester,
        first,
        'Resume Clue House',
        skipProblemStarter: false,
      );
      await confirmNoHeatStarter(tester);
      await answerObservation(tester, 'drum-turns', 'turns-normally');
      if (!_lintFilterQuestionIsOpen()) {
        await selectObservation(tester, 'lint-filter-condition');
      }

      expect(find.byType(SessionScreen), findsOneWidget);
      expect(_lintFilterQuestionIsOpen(), isTrue);
      expect(find.text(householdClueSummary(2)), findsWidgets);
      expect(_openQuestion('drum-turns'), findsNothing);
      final beforeIds = interviewObservationsInOrder(
        first.repairSessionRepository
            .evidenceForSession(
              first.repairSessionRepository.listAllSessions().single.id,
            ),
      ).map((item) => item.templateId).toList();
      expect(beforeIds, hasLength(2));

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

      expect(find.byType(SessionScreen), findsNothing);
      expect(find.text('Continue repair'), findsOneWidget);
      final dryer = second.appliancesForCurrentHousehold().single;
      expect(second.hasInProgressSession(dryer), isTrue);

      await tester.tap(find.byKey(Key('continue-repair-${dryer.id}')));
      await tester.pumpAndSettle();
      await dismissProblemStarterIfPresent(tester);

      expect(find.byType(SessionScreen), findsOneWidget);
      expect(_lintFilterQuestionIsOpen(), isTrue);
      expect(find.text(householdClueSummary(2)), findsWidgets);
      expect(_openQuestion('drum-turns'), findsNothing);
      expect(find.text('Evidence count: 2'), findsNothing);
      _expectNoEngineeringPhaseChrome();

      final afterIds = interviewObservationsInOrder(
        second.repairSessionRepository
            .evidenceForSession(
              second.repairSessionRepository.listAllSessions().single.id,
            ),
      ).map((item) => item.templateId).toList();
      expect(afterIds, beforeIds);
      expect(
        second.uiResumeForSession(
          second.repairSessionRepository.listAllSessions().single.id,
        )?.pendingObservationTemplateId,
        'lint-filter-condition',
      );
      expect(find.byKey(const Key('current-conclusion-card')), findsNothing);
      expect(second.repairSessionRepository.listAllSessions(), hasLength(1));
    },
  );
}
