import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/observation_prompt_quality.dart';
import 'package:modern_butlers_book/helpers/package_resolve.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/helpers/unmatched_starter.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/helpers/why_ask_this.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/question_selection_service.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

const _basementSmell = 'the clothes smell like the basement';

bool _starterChipSelected(WidgetTester tester, String id) {
  return find
      .descendant(
        of: find.byKey(Key('starter-chip-$id')),
        matching: find.byIcon(Icons.check_box),
      )
      .evaluate()
      .isNotEmpty;
}

Evidence _unmatchedOtherEvidence(String note) {
  return Evidence(
    id: 'e-other',
    sessionId: 's1',
    applianceId: 'a1',
    type: EvidenceType.textObservation,
    observation: unmatchedOtherObservation,
    answer: note,
    templateId: problemStarterComplaintTemplateId,
    collectedAt: DateTime.utc(2026, 8, 29),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1',
  );
}

void main() {
  test('version is 0.1.4+9', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+9');
    expect(File('pubspec.yaml').readAsStringSync(), contains('version: 0.1.4+9'));
  });

  test('KEEP 1: unmatched Other stores as Other / free-text evidence', () {
    final evidence = _unmatchedOtherEvidence(_basementSmell);
    expect(isUnmatchedOtherEvidence(evidence), isTrue);
    expect(evidence.observation, unmatchedOtherObservation);
    expect(evidence.answer, _basementSmell);
    expect(evidence.templateId, problemStarterComplaintTemplateId);
    expect(isNoHeatEstablishedFromStarter(recordedEvidence: [evidence]), isFalse);
    expect(
      isExcessHeatEstablishedFromStarter(recordedEvidence: [evidence]),
      isFalse,
    );
  });

  test('KEEP 2: unmatched path is the bounded universal set, not ranked heat/noise', () {
    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    final evidence = [_unmatchedOtherEvidence(_basementSmell)];
    expect(
      nextUnmatchedUniversalTemplate(
        templates: package.evidenceTemplates,
        recordedEvidence: evidence,
      )?.id,
      'dryer-response',
    );
    expect(
      unmatchedUniversalTemplateIds,
      ['dryer-response', 'heat-observed', 'drum-turns', 'panel-lights'],
    );
    for (final id in unmatchedUniversalTemplateIds) {
      expect(isRankedHeatOrNoiseInterviewTemplate(id), isFalse);
    }
    expect(isRankedHeatOrNoiseInterviewTemplate('cycle-heat-setting'), isTrue);
    expect(isRankedHeatOrNoiseInterviewTemplate('lint-filter-condition'), isTrue);
    expect(isRankedHeatOrNoiseInterviewTemplate('running-noise'), isTrue);
    expect(
      unmatchedUniversalSetComplete(
        templates: package.evidenceTemplates,
        recordedEvidence: evidence,
      ),
      isFalse,
    );
  });

  test('KEEP 3: why-ask is observation-only, not a diagnosis they never gave', () {
    for (final id in unmatchedUniversalTemplateIds) {
      final body = unmatchedWhyAskBody(templateId: id);
      expect(unmatchedWhyAskIsObservationOnly(body), isTrue, reason: id);
      for (final term in unmatchedWhyAskForbiddenDiagnosisTerms) {
        expect(body.toLowerCase(), isNot(contains(term)), reason: '$id $term');
      }
    }
    expect(
      unmatchedWhyAskIsObservationOnly(
        whyAskAuthoredByTemplateId['drum-turns'] ?? '',
      ),
      isFalse,
    );
  });

  test('KEEP 4: no squeal / worn-rollers swap without a noise observation', () {
    final evidence = [_unmatchedOtherEvidence(_basementSmell)];
    expect(
      hasNoiseObservation(recordedEvidence: evidence),
      isFalse,
    );
    expect(
      shouldSuppressNoiseCandidateSwap(
        recordedEvidence: evidence,
        candidateFailureModeIds: const ['worn-drum-rollers', 'thermal-fuse-open'],
      ),
      isTrue,
    );
    expect(
      shouldSuppressNoiseCandidateSwap(
        recordedEvidence: [
          ...evidence,
          Evidence(
            id: 'e-noise',
            sessionId: 's1',
            applianceId: 'a1',
            type: EvidenceType.structuredAnswer,
            observation: 'Do you hear an unusual noise?',
            answer: 'Squeal',
            templateId: 'running-noise',
            collectedAt: DateTime.utc(2026, 8, 29),
            collectedInState: RepairSessionState.evidenceCollection,
            source: EvidenceSource.user,
            schemaVersion: '1',
          ),
        ],
        candidateFailureModeIds: const ['worn-drum-rollers'],
      ),
      isFalse,
    );
  });

  test('KEEP 5: echo the note; basement smell is not an odor FM or fire-stop', () {
    expect(
      unmatchedNoteEcho(_basementSmell),
      'Heard: “$_basementSmell”.',
    );
    final evidence = [_unmatchedOtherEvidence(_basementSmell)];
    expect(evaluateSafetyStop(evidence: evidence), isNull);
    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    final standings = evaluateFailureModeStandings(
      package: package,
      evidence: evidence,
    );
    expect(standings['dusty-lint-smell']?.supportCount ?? 0, 0);
    expect(standings['electrical-burning-smell-hazard']?.supportCount ?? 0, 0);
    expect(standings['worn-drum-rollers']?.supportCount ?? 0, 0);
    expect(
      inferActiveObservationFamilies(
        recordedEvidence: evidence,
        templates: package.evidenceTemplates,
      ).contains(ObservationFamily.hazard),
      isFalse,
    );
    expect(
      inferActiveObservationFamilies(
        recordedEvidence: evidence,
        templates: package.evidenceTemplates,
      ).contains(ObservationFamily.smell),
      isFalse,
    );
  });

  test('KEEP 6: placeholder plate is missing-plate, not general dryer guide', () {
    expect(dryerHasMachinePlate('Demo Manufacturer', 'DEMO-DRYER-1'), isFalse);
    expect(dryerHasMachinePlate('', ''), isFalse);
    expect(dryerHasMachinePlate('Whirlpool', 'WED5000DW'), isTrue);
    expect(
      dryerCoverageNotice(
        manufacturer: 'Demo Manufacturer',
        modelNumber: 'DEMO-DRYER-1',
        usingGeneralGuide: true,
        category: 'dryer',
      ),
      UserFacingCopy.missingMachinePlateNotice,
    );
    expect(
      dryerCoverageNotice(
        manufacturer: 'Acme',
        modelNumber: 'X-1',
        usingGeneralGuide: true,
        category: 'dryer',
      ),
      generalDryerGuideNotice,
    );
  });

  test('KEEP 7: matcher must not auto-check heat/noise while they type Other', () {
    expect(
      starterKeywordMatcherChipIds(freeText: _basementSmell),
      isEmpty,
    );
    expect(
      starterKeywordMatcherChipIds(freeText: 'no heat and too hot unusual noise'),
      isNot(contains('no-heat')),
    );
    expect(
      starterKeywordMatcherChipIds(freeText: 'no heat and too hot unusual noise'),
      isNot(contains('dryer-very-hot')),
    );
    expect(
      starterKeywordMatcherChipIds(freeText: 'no heat and too hot unusual noise'),
      isNot(contains(dryerStarterNoiseOrSmellId)),
    );

    final afterType = applyStarterKeywordMatcher(
      selectedIds: {dryerStarterOtherDescribeId},
      freeText: _basementSmell,
    );
    expect(afterType, {dryerStarterOtherDescribeId});

    final afterUncheck = applyStarterKeywordMatcher(
      selectedIds: {dryerStarterOtherDescribeId},
      freeText: 'no heat, too hot, unusual noise, $_basementSmell',
      dismissedIds: {'no-heat', 'dryer-very-hot', dryerStarterNoiseOrSmellId},
    );
    expect(afterUncheck, {dryerStarterOtherDescribeId});

    final raw = resolveDryerStarter(
      selectedSymptomIds: const {},
      freeText: 'no heat and the clothes smell like the basement',
    );
    expect(raw.matchedSymptomIds, contains('no-heat'));
    final honest = resolutionWithoutHeatNoiseUnlessChecked(
      resolution: raw,
      selectedSymptomIds: const {},
    );
    expect(honest.matchedSymptomIds, isNot(contains('no-heat')));
    expect(honest.hasMatch, isFalse);
    expect(honest.unmatchedFreeText, isTrue);
  });

  test('Groq does not pick chips or next question id on unmatched path', () {
    final helper = File('lib/helpers/unmatched_starter.dart').readAsStringSync();
    final imports = helper
        .split('\n')
        .where((line) => line.startsWith('import '));
    expect(imports, isNot(anyElement(contains('groq'))));
    expect(imports, isNot(anyElement(contains('question_selection'))));
    expect(helper, isNot(contains('QuestionSelectionService')));
    const QuestionSelectionService().suggestNext(
      templates: const [],
      recordedEvidence: const [],
    );
    expect(
      File('lib/services/question_selection_service.dart').readAsStringSync(),
      contains('Groq phrasing must not be called from here'),
    );
  });

  test('Other won’t-start and burning/smoke mapping still resolve on confirm', () {
    final wontStart = resolveDryerStarter(
      selectedSymptomIds: const {},
      freeText: "won't start",
    );
    expect(
      resolutionWithoutHeatNoiseUnlessChecked(
        resolution: wontStart,
        selectedSymptomIds: const {},
      ).matchedSymptomIds,
      ['will-not-start'],
    );

    final hazard = resolveDryerStarter(
      selectedSymptomIds: const {},
      freeText: 'burning smell and smoke',
    );
    expect(hazard.isHazard, isTrue);
    expect(
      resolutionWithoutHeatNoiseUnlessChecked(
        resolution: hazard,
        selectedSymptomIds: const {},
      ).isHazard,
      isTrue,
    );
  });

  testWidgets(
    'KEEP 6: add-dryer placeholder plate shows missing-plate notice',
    (tester) async {
      final dependencies = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 29, 23, 40),
      );
      await openDryerSession(
        tester,
        dependencies,
        'Plate House',
        skipProblemStarter: false,
      );
      expect(find.byKey(const Key('missing-plate-notice')), findsOneWidget);
      expect(find.byKey(const Key('general-dryer-guide-notice')), findsNothing);
      expect(find.text(UserFacingCopy.missingMachinePlateNotice), findsOneWidget);
      expect(find.text(generalDryerGuideNotice), findsNothing);
    },
  );

  testWidgets(
    'basement smell Other stays Evidence, then universal set, then Call a pro',
    (tester) async {
      final dependencies = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 29, 23, 45),
      );
      await openDryerSession(
        tester,
        dependencies,
        'Basement House',
        skipProblemStarter: false,
      );

      await tester.tap(find.byKey(const Key('starter-chip-other-describe')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('problem-starter-freetext')),
        _basementSmell,
      );
      await tester.pump();

      expect(_starterChipSelected(tester, 'no-heat'), isFalse);
      expect(_starterChipSelected(tester, 'dryer-very-hot'), isFalse);
      expect(_starterChipSelected(tester, dryerStarterNoiseOrSmellId), isFalse);
      expect(find.text('Confirm with what I typed'), findsOneWidget);

      await tester.tap(find.byKey(const Key('starter-chip-no-heat')));
      await tester.pump();
      expect(_starterChipSelected(tester, 'no-heat'), isTrue);
      await tester.tap(find.byKey(const Key('starter-chip-no-heat')));
      await tester.pump();
      expect(_starterChipSelected(tester, 'no-heat'), isFalse);
      await tester.enterText(
        find.byKey(const Key('problem-starter-freetext')),
        '$_basementSmell after a long cycle',
      );
      await tester.pump();
      expect(_starterChipSelected(tester, 'no-heat'), isFalse);
      expect(_starterChipSelected(tester, 'dryer-very-hot'), isFalse);
      expect(_starterChipSelected(tester, dryerStarterNoiseOrSmellId), isFalse);
      expect(find.text('Confirm with what I typed'), findsOneWidget);

      await tester.tap(find.byKey(const Key('problem-starter-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('problem-starter-panel')), findsNothing);
      expect(find.byKey(const Key('starter-limited-guidance')), findsOneWidget);
      expect(find.byKey(const Key('unmatched-note-echo')), findsOneWidget);
      expect(
        find.textContaining(_basementSmell),
        findsWidgets,
      );
      expect(find.byKey(const Key('skip-to-best-guess')), findsNothing);
      expect(find.byKey(const Key('recommended-primary-card')), findsNothing);
      expect(find.textContaining('Best guess'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('answer-choice-panel')),
          matching: find.byKey(const Key('observation-prompt-dryer-response')),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('observation-prompt-cycle-heat-setting')), findsNothing);
      expect(find.byKey(const Key('observation-prompt-lint-filter-condition')), findsNothing);
      expect(find.byKey(const Key('observation-prompt-running-noise')), findsNothing);

      await tester.tap(find.byKey(const Key('why-ask-this-tile')));
      await tester.pumpAndSettle();
      final why = tester.widget<Text>(find.byKey(const Key('why-ask-this-body')));
      expect(unmatchedWhyAskIsObservationOnly(why.data ?? ''), isTrue);
      expect(why.data!.toLowerCase(), isNot(contains('heating-element')));
      expect(why.data!.toLowerCase(), isNot(contains('heat-relay')));
      expect(why.data!.toLowerCase(), isNot(contains('broken drive belt')));
      expect(why.data!.toLowerCase(), isNot(contains('belt')));

      final session =
          dependencies.repairSessionRepository.listAllSessions().single;
      final starter = dependencies.repairSessionRepository
          .evidenceForSession(session.id)
          .singleWhere(
            (item) => item.templateId == problemStarterComplaintTemplateId,
          );
      expect(starter.observation, unmatchedOtherObservation);
      expect(starter.answer, '$_basementSmell after a long cycle');
      expect(evaluateSafetyStop(evidence: [starter]), isNull);

      await answerObservation(tester, 'dryer-response', 'starts-normally');
      expect(find.byKey(const Key('observation-prompt-cycle-heat-setting')), findsNothing);
      expect(find.byKey(const Key('observation-prompt-lint-filter-condition')), findsNothing);
      expect(find.byKey(const Key('observation-prompt-running-noise')), findsNothing);
      await answerObservation(tester, 'heat-observed', 'not-sure');
      await answerObservation(tester, 'drum-turns', 'turns-normally');
      await answerObservation(tester, 'panel-lights', 'yes-panel-responds');

      expect(find.byKey(const Key('unmatched-no-match-title')), findsOneWidget);
      expect(find.byKey(const Key('unmatched-no-match-call-pro')), findsOneWidget);
      expect(find.text('Call a pro'), findsWidgets);
      expect(find.byKey(const Key('skip-to-best-guess')), findsNothing);

      await tapVisible(tester, find.byKey(const Key('unmatched-no-match-call-pro')));
      expect(find.byKey(const Key('outcome-needs-professional')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('outcome-save-button')));
      await tester.tap(find.byKey(const Key('outcome-save-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pro-handoff-screen')), findsOneWidget);
    },
  );
}
