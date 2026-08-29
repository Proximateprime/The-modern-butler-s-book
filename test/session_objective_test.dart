import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/models/session_objective.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/services/local_domain_store.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('chip labels match the mission copy', () {
    expect(
      SessionObjective.values.map(sessionObjectiveChipLabel).toList(),
      [
        'Fix it',
        "Figure out what's wrong",
        'Decide repair vs replace',
        'Prepare to call a pro',
      ],
    );
  });

  test('legacy userGoal strings are not treated as an objective', () {
    expect(
      sessionObjectiveFromName('Record what the dryer is doing.'),
      isNull,
    );
    expect(sessionObjectiveFromName('fixIt'), SessionObjective.fixIt);
  });

  test('cost and pro handoff timing depends on objective, not a score', () {
    expect(showPartsCostOnClosePath(null), isTrue);
    expect(showPartsCostOnClosePath(SessionObjective.fixIt), isTrue);
    expect(
      showPartsCostOnClosePath(SessionObjective.figureOutWhatsWrong),
      isFalse,
    );
    expect(showPartsCostOnRecommendedPrimary(null), isFalse);
    expect(
      showPartsCostOnRecommendedPrimary(SessionObjective.decideRepairVsReplace),
      isTrue,
    );
    expect(showIllRepairOnPartsCard(SessionObjective.prepareToCallAPro), isFalse);
    expect(
      showCallProOnPartsCard(SessionObjective.figureOutWhatsWrong),
      isFalse,
    );
    expect(showEarlyProHandoffOnRecommended(null), isFalse);
    expect(
      showEarlyProHandoffOnRecommended(SessionObjective.prepareToCallAPro),
      isTrue,
    );
  });

  test('unset copy stays the existing interview strings', () {
    expect(
      sessionObjectiveInterviewCueTitle(
        objective: null,
        hasRecommendedPrimary: false,
      ),
      'Next: answer the current question',
    );
    expect(
      sessionObjectiveInterviewCueDetail(
        objective: null,
        hasRecommendedPrimary: true,
        hideNextQuestion: false,
      ),
      'Accept only if it fits, or keep answering questions below.',
    );
  });

  test('endSession copies the objective onto household memory', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalDomainStore(preferences: prefs);
    final deps = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 12),
      store: store,
    );
    deps.createHousehold('Objective Memory House');
    final dryer = deps.addDryer();
    final sessionId = deps.startOrResumeSession(dryer);
    deps.setSessionObjective(sessionId, SessionObjective.fixIt);

    expect(
      deps.repairSessionRepository.getSession(sessionId)!.sessionObjective,
      SessionObjective.fixIt,
    );

    final outcome = deps.endSession(
      sessionId: sessionId,
      closeKind: SessionCloseKind.stopped,
    );
    expect(outcome.sessionObjective, SessionObjective.fixIt);

    await deps.flushPersist();
    final restored = AppDependencies(
      clock: () => DateTime.utc(2026, 8, 17, 12),
      store: store,
    );
    await restored.restore();
    expect(
      restored.outcomeForSession(sessionId)?.sessionObjective,
      SessionObjective.fixIt,
    );
  });

  testWidgets('optional chips appear at session start', (tester) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 13));
    await openDryerSession(tester, deps, 'Objective Chips House');

    expect(find.byKey(const Key('session-objective-chips')), findsOneWidget);
    expect(find.text('Fix it'), findsOneWidget);
    expect(find.text("Figure out what's wrong"), findsOneWidget);
    expect(find.text('Decide repair vs replace'), findsOneWidget);
    expect(find.text('Prepare to call a pro'), findsOneWidget);
    expect(find.text('Current question'), findsOneWidget);
  });

  testWidgets('figure-out hides parts and call-pro on the close path', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 17, 13, 5));
    await openDryerSession(tester, deps, 'Objective Figure House');
    await tapVisible(
      tester,
      find.byKey(const Key('session-objective-chip-figureOutWhatsWrong')),
    );

    await selectObservation(tester, 'clothes-remain-damp');
    await tapVisible(tester, find.byKey(const Key('answer-choice-still-damp')));
    await selectObservation(tester, 'exterior-airflow');
    await tapInspectOrAnswerChoice(tester, 'weak');
    await selectFailureMode(tester, 'restricted-exhaust-airflow');
    await completeRepairReadinessIfPresent(tester);

    expect(find.byKey(const Key('parts-cost-card')), findsNothing);
    expect(find.text("I'll repair"), findsNothing);
    expect(find.text('Call a pro'), findsNothing);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
  });

  testWidgets(
    'decide repair vs replace shows cost on the recommended match',
    (tester) async {
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 17, 13, 10),
      );
      await openDryerSession(tester, deps, 'Objective Compare House');
      await tapVisible(
        tester,
        find.byKey(
          const Key('session-objective-chip-decideRepairVsReplace'),
        ),
      );
      await _answerUntilHeatingElementRecommended(tester);

      expect(find.byKey(const Key('recommended-primary-card')), findsOneWidget);
      expect(find.byKey(const Key('parts-cost-card')), findsOneWidget);
      expect(find.text('Heating element'), findsOneWidget);
    },
  );

  testWidgets(
    'prepare to call a pro shows an early handoff on the recommended match',
    (tester) async {
      final deps = AppDependencies(
        clock: () => DateTime.utc(2026, 8, 17, 13, 15),
      );
      await openDryerSession(tester, deps, 'Objective Pro House');
      await tapVisible(
        tester,
        find.byKey(const Key('session-objective-chip-prepareToCallAPro')),
      );
      await _answerUntilHeatingElementRecommended(tester);

      expect(find.byKey(const Key('recommended-primary-card')), findsOneWidget);
      expect(find.byKey(const Key('recommended-call-pro')), findsOneWidget);
      expect(find.byKey(const Key('primary-hypothesis-banner')), findsNothing);
    },
  );
}

Future<void> _answerUntilHeatingElementRecommended(WidgetTester tester) async {
  await selectObservation(tester, 'heat-observed');
  await tapVisible(tester, find.byKey(const Key('answer-choice-no-warmth')));
  await selectObservation(tester, 'cycle-heat-setting');
  await tapVisible(
    tester,
    find.byKey(const Key('answer-choice-yes-heat-cycle')),
  );
  await selectObservation(tester, 'recent-overheat');
  await tapVisible(tester, find.byKey(const Key('answer-choice-no')));
  await selectObservation(tester, 'clothes-feel-after-cycle');
  await tapVisible(
    tester,
    find.byKey(const Key('answer-choice-cold-and-still-damp')),
  );
  await selectObservation(tester, 'wall-plug-seated');
  await tapVisible(
    tester,
    find.byKey(const Key('answer-choice-fully-seated-looks-normal')),
  );
}
