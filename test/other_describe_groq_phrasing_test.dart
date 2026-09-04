import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/groq_phrasing.dart';
import 'package:modern_butlers_book/helpers/phrasing_safety_gate.dart';
import 'package:modern_butlers_book/helpers/voice_answer.dart';
import 'package:modern_butlers_book/helpers/why_ask_this.dart';
import 'package:modern_butlers_book/models/enrichment_note.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/inspect_step.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/enrichment_provider.dart';
import 'package:modern_butlers_book/services/groq_phrasing_client.dart';
import 'package:modern_butlers_book/services/groq_phrasing_service.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/question_selection_service.dart';
import 'package:modern_butlers_book/services/ranking_service.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

const _dryerStartOptions = [
  'Nothing happens',
  'Starts normally',
  'Hums but does not start',
  'Starts then stops',
  'Not sure',
  kOtherDescribeChoiceId,
];

GroqPhrasingRequest _questionRequest({
  List<String> options = _dryerStartOptions,
}) {
  return GroqPhrasingRequest(
    hook: GroqPhrasingHook.questionCard,
    family: 'dryer',
    energy: 'electric',
    state: 'evidence',
    comfort: 'normal',
    evidenceNeeded: 'dryer-response',
    options: options,
    lastObs: '',
    whyEngine: whyAskAuthoredByTemplateId['dryer-response'] ??
        'Start versus no start splits power from a running drum.',
    safety: 'none',
    packagedTitle: 'What happens when you press Start?',
    packagedWhyOneLine: whyAskAuthoredByTemplateId['dryer-response'] ??
        'Start versus no start splits power from a running drum.',
    packagedOptionLabels: {for (final id in options) id: id},
  );
}

const _safeWhy = 'Start versus no start splits power from a running drum.';

const _relabeledOther = GroqPhrasingJson(
  title: 'What happens when you press Start?',
  whyOneLine: _safeWhy,
  optionLabelsOnly: {
    'Nothing happens': 'Nothing happens',
    'Starts normally': 'Starts normally',
    'Hums but does not start': 'Hums but does not start',
    'Starts then stops': 'Starts then stops',
    'Not sure': 'Not sure',
    kOtherDescribeChoiceId: 'Something else I noticed',
  },
  describeTitle: 'What else did you notice?',
  describeHint: 'a sound, a smell, or a feel',
);

Evidence _dryerResponseEvidence(String answer) {
  return Evidence(
    id: 'e-$answer',
    sessionId: 's1',
    applianceId: 'a1',
    type: EvidenceType.structuredAnswer,
    observation: 'What happens when you press Start?',
    answer: answer,
    templateId: 'dryer-response',
    collectedAt: DateTime.utc(2026, 8, 29),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1',
  );
}

void main() {
  test('version is 0.1.4+24', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+24');
  });

  test('optional describe extras ride the same payload and missing extras stay packaged',
      () {
    final missing = parseGroqPhrasingJson(
      '{"title":"What happens when you press Start?",'
      '"why_one_line":"$_safeWhy",'
      '"option_labels_only":{"Other / describe":"Something else I noticed"},'
      '"next_question":"thermal-fuse-open",'
      '"next_template_id":"invented-id"}',
    );
    expect(missing, isNotNull);
    expect(missing!.title, 'What happens when you press Start?');
    expect(missing.describeTitle, isNull);
    expect(missing.describeHint, isNull);
    expect(missing.optionLabelsOnly[kOtherDescribeChoiceId],
        'Something else I noticed');

    final accepted = acceptGroqPhrasing(
      request: _questionRequest(),
      parsed: missing,
    );
    expect(accepted, isNotNull);
    expect(accepted!.fromGroq, isTrue);
    expect(accepted.describeTitle, kPackagedDescribeDialogTitle);
    expect(accepted.describeHint, kPackagedDescribeDialogHint);
    expect(
      accepted.displayLabelFor(kOtherDescribeChoiceId),
      'Something else I noticed',
    );

    final withExtras = acceptGroqPhrasing(
      request: _questionRequest(),
      parsed: _relabeledOther,
    );
    expect(withExtras, isNotNull);
    expect(withExtras!.describeTitle, 'What else did you notice?');
    expect(withExtras.describeHint, 'a sound, a smell, or a feel');
  });

  test('extra chip ids are still rejected', () {
    final extra = acceptGroqPhrasing(
      request: _questionRequest(),
      parsed: const GroqPhrasingJson(
        title: 'What happens when you press Start?',
        whyOneLine: _safeWhy,
        optionLabelsOnly: {
          kOtherDescribeChoiceId: 'Something else I noticed',
          'invented-chip': 'Fourth option',
        },
      ),
    );
    expect(extra, isNull);
  });

  test('unsafe describe extras fail the safety gate and stay packaged',
      () async {
    final banned = acceptGroqPhrasing(
      request: _questionRequest(),
      parsed: const GroqPhrasingJson(
        title: 'What happens when you press Start?',
        whyOneLine: _safeWhy,
        describeTitle: 'Bypass the thermal fuse with a jumper.',
      ),
    );
    expect(banned, isNull);

    final service = GroqPhrasingService(
      client: FakeGroqPhrasingClient(
        response: const GroqPhrasingJson(
          title: 'What happens when you press Start?',
          whyOneLine: _safeWhy,
          describeHint: 'Check the gas_train next',
        ),
      ),
    );
    final accepted = await service.phrase(_questionRequest());
    expect(accepted.fromGroq, isFalse);
    expect(accepted.describeTitle, kPackagedDescribeDialogTitle);
    expect(accepted.describeHint, kPackagedDescribeDialogHint);
    expect(service.liveNetworkCalls, 0);
  });

  test('voice and engine-id match stay on Other / describe, not Groq display',
      () {
    expect(isOtherDescribeChoice(kOtherDescribeChoiceId), isTrue);
    expect(isOtherDescribeEngineId(kOtherDescribeChoiceId), isTrue);
    expect(isOtherDescribeChoice('Something else I noticed'), isFalse);
    expect(isOtherDescribeEngineId('Something else I noticed'), isFalse);
    expect(
      matchVoiceToAnswerChoice('something else I noticed', _dryerStartOptions),
      isNull,
    );
    expect(
      matchVoiceToAnswerChoice('nothing happens', _dryerStartOptions),
      'Nothing happens',
    );
    expect(
      recordedOtherDescribeAnswer('Nothing happens'),
      'Other / describe: Nothing happens',
    );
    expect(
      normalizeObservationAnswer('Other / describe: Nothing happens'),
      kOtherDescribeChoiceId,
    );
  });

  test('typed Other note does not change ranking or next template id', () {
    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    const ranking = RankingService();
    const picker = QuestionSelectionService();

    final otherNote = [_dryerResponseEvidence('Other / describe: Nothing happens')];
    final otherBare = [_dryerResponseEvidence(kOtherDescribeChoiceId)];
    final nothingChip = [_dryerResponseEvidence('Nothing happens')];

    final standNote = ranking.evaluate(package: package, evidence: otherNote);
    final standBare = ranking.evaluate(package: package, evidence: otherBare);
    final standChip = ranking.evaluate(package: package, evidence: nothingChip);

    expect(
      standNote.standings['door-switch-failure']?.supportCount,
      standBare.standings['door-switch-failure']?.supportCount,
    );
    expect(
      standChip.standings['door-switch-failure']!.supportCount,
      greaterThan(standNote.standings['door-switch-failure']!.supportCount),
    );
    expect(otherNote.single.templateId, 'dryer-response');
    expect(
      normalizeObservationAnswer(otherNote.single.answer),
      kOtherDescribeChoiceId,
    );

    final nextNote = picker.suggestNext(
      templates: package.evidenceTemplates,
      recordedEvidence: otherNote,
    );
    final nextBare = picker.suggestNext(
      templates: package.evidenceTemplates,
      recordedEvidence: otherBare,
    );
    expect(nextNote?.id, nextBare?.id);
    expect(nextNote?.id, isNot('thermal-fuse-open'));
    expect(picker, isA<QuestionSelectionService>());
  });

  test('QuestionSelectionService still does not call Groq', () {
    final fake = FakeGroqPhrasingClient(response: _relabeledOther);
    const QuestionSelectionService().suggestNext(
      templates: KnowledgePackageRepository().loadById('dryer-core')!.evidenceTemplates,
      recordedEvidence: [_dryerResponseEvidence('Other / describe: a rattle')],
    );
    expect(fake.completeCalls, 0);
    expect(fake.liveNetworkCalls, 0);
  });

  test('REJECT: Groq cannot choose the next question or rewrite chip ids',
      () async {
    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    const picker = QuestionSelectionService();
    final recorded = [
      _dryerResponseEvidence('Other / describe: brand new smell no chip'),
    ];
    final engineNext = picker.suggestNext(
      templates: package.evidenceTemplates,
      recordedEvidence: recorded,
    );
    expect(engineNext?.id, isNot('thermal-fuse-open'));

    final parsed = parseGroqPhrasingJson(
      '{"title":"What happens when you press Start?",'
      '"why_one_line":"$_safeWhy",'
      '"option_labels_only":{"Other / describe":"Something else I noticed"},'
      '"next_question":"thermal-fuse-open",'
      '"new_chip":"Brand new smell"}',
    );
    expect(parsed, isNotNull);
    expect(parsed!.optionLabelsOnly.keys, [kOtherDescribeChoiceId]);
    expect(parsed.optionLabelsOnly.containsKey('Brand new smell'), isFalse);

    final rewrittenId = acceptGroqPhrasing(
      request: _questionRequest(),
      parsed: const GroqPhrasingJson(
        title: 'What happens when you press Start?',
        whyOneLine: _safeWhy,
        optionLabelsOnly: {
          'Brand new smell': 'Brand new smell',
        },
      ),
    );
    expect(rewrittenId, isNull);

    final fake = FakeGroqPhrasingClient(
      handler: (request) {
        expect(request.options, isNot(contains('Brand new smell')));
        expect(request.options, contains(kOtherDescribeChoiceId));
        expect(request.evidenceNeeded, isNot('thermal-fuse-open'));
        return _relabeledOther;
      },
    );
    final accepted =
        await GroqPhrasingService(client: fake).phrase(_questionRequest());
    expect(accepted.fromGroq, isTrue);
    expect(accepted.optionLabels.containsKey('Brand new smell'), isFalse);
    expect(
      picker.suggestNext(
        templates: package.evidenceTemplates,
        recordedEvidence: recorded,
      )?.id,
      engineNext?.id,
    );
    expect(kRuntimeEnrichmentCallsEnabled, isFalse);
    expect(fake.completeCalls, 1);
    expect(fake.liveNetworkCalls, 0);
  });

  test('inspect GOLDEN chips stay frozen', () {
    expect(kGoldenChromeFrozenLabels, contains(inspectMatchesOkChip));
    expect(kGoldenChromeFrozenLabels, contains(inspectDoesntMatchChip));
    final remapped = acceptGroqPhrasing(
      request: _questionRequest(
        options: [inspectMatchesOkChip, inspectDoesntMatchChip],
      ),
      parsed: GroqPhrasingJson(
        title: 'Look here',
        whyOneLine: _safeWhy,
        optionLabelsOnly: {
          inspectMatchesOkChip: 'Looks fine',
          inspectDoesntMatchChip: inspectDoesntMatchChip,
        },
      ),
    );
    expect(remapped, isNull);
  });

  test('runtime enrichment stays off', () {
    expect(kRuntimeEnrichmentCallsEnabled, isFalse);
    expect(const StubEnrichmentProvider(), isA<StubEnrichmentProvider>());
  });

  testWidgets('Other chip records original id when Groq relabels it',
      (tester) async {
    final fake = FakeGroqPhrasingClient(response: _relabeledOther);
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 29, 19),
      groqPhrasing: GroqPhrasingService(client: fake),
    );
    await openDryerSession(tester, deps, 'Other Relabel Household');
    await tester.pumpAndSettle();

    final otherChip = find.byKey(const Key('answer-choice-other-describe'));
    expect(otherChip, findsOneWidget);
    expect(
      find.descendant(
        of: otherChip,
        matching: find.text('Something else I noticed'),
      ),
      findsOneWidget,
    );
    expect(fake.completeCalls, 1);
    expect(fake.liveNetworkCalls, 0);
    expect(fake.requests.single.options, contains(kOtherDescribeChoiceId));
    expect(fake.requests.single.hook, GroqPhrasingHook.questionCard);

    await tapVisible(tester, find.byKey(const Key('answer-choice-other-describe')));
    expect(find.byKey(const Key('answer-other-note-field')), findsOneWidget);
    expect(find.text('What else did you notice?'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('answer-other-note-field')),
      'Nothing happens',
    );
    await tester.enterText(
      find.byKey(const Key('answer-other-note-field')),
      'Nothing happens at all',
    );
    expect(fake.completeCalls, 1, reason: 'no every-keystroke Groq');
    await tester.tap(find.byKey(const Key('answer-other-confirm')));
    await tester.pumpAndSettle();

    await expandEvidenceHistory(tester);
    expect(
      find.textContaining('Answer: Other / describe: Nothing happens at all'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Answer: Nothing happens at all'),
      findsNothing,
    );
    expect(fake.completeCalls, greaterThanOrEqualTo(1));
    expect(
      fake.requests.every((request) => request.hook != GroqPhrasingHook.questionCard ||
          request.options.contains(kOtherDescribeChoiceId)),
      isTrue,
    );
  });

  testWidgets('describe dialog paints packaged then overlay; typing is not a Groq call',
      (tester) async {
    final gate = Completer<void>();
    final fake = FakeGroqPhrasingClient(
      holdUntil: gate,
      response: _relabeledOther,
    );
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 29, 19, 10),
      groqPhrasing: GroqPhrasingService(client: fake),
    );
    await openDryerSession(tester, deps, 'Other Overlay Household');
    final otherChip = find.byKey(const Key('answer-choice-other-describe'));
    expect(otherChip, findsOneWidget);
    expect(
      find.descendant(
        of: otherChip,
        matching: find.text(kOtherDescribeChoiceId),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: otherChip,
        matching: find.text('Something else I noticed'),
      ),
      findsNothing,
    );
    expect(fake.completeCalls, 1);

    await tapVisible(tester, find.byKey(const Key('answer-choice-other-describe')));
    final dialogTitle = find.byKey(const Key('answer-other-note-title'));
    expect(dialogTitle, findsOneWidget);
    expect(
      tester.widget<Text>(dialogTitle).data,
      kPackagedDescribeDialogTitle,
    );

    gate.complete();
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('answer-other-note-title'))).data,
      'What else did you notice?',
    );
    expect(fake.completeCalls, 1);

    await tester.enterText(
      find.byKey(const Key('answer-other-note-field')),
      'r',
    );
    await tester.enterText(
      find.byKey(const Key('answer-other-note-field')),
      'ra',
    );
    await tester.enterText(
      find.byKey(const Key('answer-other-note-field')),
      'rattle in the back',
    );
    expect(fake.completeCalls, 1);
    expect(fake.liveNetworkCalls, 0);

    await tester.tap(find.byKey(const Key('answer-other-confirm')));
    await tester.pumpAndSettle();
    await expandEvidenceHistory(tester);
    expect(
      find.textContaining('Answer: Other / describe: rattle in the back'),
      findsOneWidget,
    );
  });
}
