import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/dryer_problem_starter.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/hazard_language.dart';
import 'package:modern_butlers_book/helpers/phrasing_request.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/ranking_service.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

String _read(String path) => File(path).readAsStringSync();

Future<void> _expectHazardStopYes(WidgetTester tester, AppDependencies deps) async {
  expect(find.byKey(const Key('voice-hazard-confirm-banner')), findsOneWidget);
  expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
  expect(find.byKey(const Key('answer-choice-panel')), findsNothing);
  expect(find.text('Safe to continue'), findsNothing);

  final session = deps.repairSessionRepository.listAllSessions().single;
  final recorded = deps.repairSessionRepository.evidenceForSession(session.id);
  expect(
    recorded
        .where((item) => item.templateId == 'hazard-observation')
        .map((item) => item.answer),
    contains('Yes'),
  );
  expect(
    evaluateSafetyStop(evidence: recorded),
    isNotNull,
  );
}

void main() {
  test('version is 0.1.4+27', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppBuildNumber, '27');
    expect(kAppVersionLabel, '0.1.4+27');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+27'));
  });

  test('GOLDEN Call a pro stays frozen', () {
    expect(kGoldenChromeFrozenLabels, contains('Call a pro'));
  });

  test('burning smell / bare burning share the unified lexicon', () {
    expect(kBareBurningHazardMarkers, contains('burning smell'));
    expect(kBareBurningHazardMarkers, contains('burning'));
    expect(kSharedHazardLanguageMarkers, containsAll(kBareBurningHazardMarkers));
    expect(textSuggestsHazard('burning smell'), isTrue);
    expect(classifyHazardLanguage('burning smell'), HazardLanguageKind.fireSmoke);
    expect(classifyHazardLanguage('burning plastic'), HazardLanguageKind.fireSmoke);
    expect(textSuggestsHazard('purple zebra waffle 123'), isFalse);
    expect(classifyHazardLanguage('purple zebra waffle 123'), isNull);

    final typed = resolveDryerStarter(
      selectedSymptomIds: const {},
      freeText: 'burning smell',
    );
    expect(typed.isHazard, isTrue);

    expect(
      _read('lib/ui/session_screen.dart'),
      contains('_tryRecordHazardFromTranscript(trimmedFree)'),
    );
    expect(
      _read('lib/helpers/dryer_problem_starter.dart'),
      contains('textSuggestsHazard(trimmed)'),
    );
  });

  testWidgets(
    'starter Other typed burning smell writes hazard Yes and lock/stop',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 22));
      await openDryerSession(
        tester,
        deps,
        'Typed Hazard Starter Other',
        skipProblemStarter: false,
      );

      await tester.tap(find.byKey(const Key('starter-chip-other-describe')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('problem-starter-freetext')),
        'burning smell',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem-starter-confirm')));
      await tester.pump();
      await tester.pump();

      await _expectHazardStopYes(tester, deps);
      expect(find.byKey(const Key('problem-starter-panel')), findsNothing);
    },
  );

  testWidgets(
    'interview Other typed burning smell writes hazard Yes and lock/stop',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 22, 10));
      await openDryerSession(tester, deps, 'Typed Hazard Interview Other');
      expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);

      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-other-describe')),
      );
      expect(find.byKey(const Key('answer-other-note-field')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('answer-other-note-field')),
        'burning smell',
      );
      await tester.tap(find.byKey(const Key('answer-other-confirm')));
      await tester.pump();
      await tester.pump();

      await _expectHazardStopYes(tester, deps);
      final session = deps.repairSessionRepository.listAllSessions().single;
      expect(
        deps.repairSessionRepository
            .evidenceForSession(session.id)
            .any(
              (item) => (item.answer ?? '').startsWith('$kOtherDescribeChoiceId:'),
            ),
        isFalse,
      );
    },
  );

  testWidgets(
    'free-note burning smell writes hazard Yes and lock/stop',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 22, 20));
      await openDryerSession(tester, deps, 'Typed Hazard Free Note Burning');
      await tapVisible(tester, find.byKey(const Key('free-observation-field')));
      await tester.enterText(
        find.byKey(const Key('free-observation-field')),
        'burning smell',
      );
      await tapVisible(tester, find.byKey(const Key('free-observation-save')));

      await _expectHazardStopYes(tester, deps);
      expect(find.byKey(const Key('free-observation-intake')), findsNothing);
      final session = deps.repairSessionRepository.listAllSessions().single;
      expect(
        deps.repairSessionRepository
            .evidenceForSession(session.id)
            .where((item) => item.templateId == 'free-observation-note'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'nonsense typed Other does not invent a failure mode',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 22, 30));
      await openDryerSession(tester, deps, 'Typed Hazard Nonsense Other');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-other-describe')),
      );
      await tester.enterText(
        find.byKey(const Key('answer-other-note-field')),
        'purple zebra waffle 123',
      );
      await tester.tap(find.byKey(const Key('answer-other-confirm')));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
      expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
      expect(find.text('Safe to continue'), findsWidgets);

      final session = deps.repairSessionRepository.listAllSessions().single;
      final recorded =
          deps.repairSessionRepository.evidenceForSession(session.id);
      expect(
        recorded.where((item) => item.templateId == 'hazard-observation'),
        isEmpty,
      );

      final package = KnowledgePackageRepository().loadById('dryer-core')!;
      final knownIds = {for (final mode in package.failureModes) mode.id};
      final context = deps.buildDecisionContext(session.id);
      final snapshot = const RankingService().evaluateContext(context);
      for (final mode in snapshot.orderedFailureModes) {
        expect(knownIds.contains(mode.id), isTrue);
      }
      expect(
        deps.repairSessionRepository.hypothesesForSession(session.id),
        isEmpty,
      );
      expect(
        recorded.any((item) => item.templateId == 'electrical-burning-smell-hazard'),
        isFalse,
      );
    },
  );

  testWidgets(
    'chip hazard path still stops',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 9, 4, 22, 40));
      await openDryerSession(
        tester,
        deps,
        'Chip Hazard Still Stops',
        skipProblemStarter: false,
      );
      await tester.tap(find.byKey(const Key('starter-chip-hazard-signs')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('problem-starter-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
      expect(find.byKey(const Key('answer-choice-panel')), findsNothing);
      expect(find.text('Safe to continue'), findsNothing);
      final session = deps.repairSessionRepository.listAllSessions().single;
      expect(
        evaluateSafetyStop(
          evidence: deps.repairSessionRepository.evidenceForSession(session.id),
        ),
        isNotNull,
      );
    },
  );
}
