import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets(
    'system-driven no-heat path: answer questions → recommend → verify → resolve',
    (tester) async {
      final dependencies = AppDependencies(
        clock: () => DateTime.utc(2026, 7, 24, 11),
      );
      await openDryerSession(tester, dependencies, 'Interview Household');

      expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);
      expect(find.text('Current question'), findsOneWidget);
      expect(find.byKey(const Key('recommended-primary-card')), findsNothing);

      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );
      expect(find.byKey(const Key('answer-choice-panel')), findsOneWidget);

      await selectObservation(tester, 'cycle-heat-setting');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-yes-heat-cycle')),
      );

      await selectObservation(tester, 'recent-overheat');
      await tapVisible(tester, find.byKey(const Key('answer-choice-no')));

      expect(find.byKey(const Key('recommended-primary-card')), findsNothing);

      await selectObservation(tester, 'clothes-feel-after-cycle');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-cold-and-still-damp')),
      );

      expect(find.byKey(const Key('recommended-primary-card')), findsNothing);

      await selectObservation(tester, 'wall-plug-seated');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-fully-seated-looks-normal')),
      );

      expect(find.byKey(const Key('recommended-primary-card')), findsOneWidget);
      expect(
        find.textContaining('Best match so far'),
        findsWidgets,
      );
      expect(find.textContaining('%'), findsNothing);
      expect(
        find.byKey(
          const Key('recommended-primary-label-heating-element-failed'),
        ),
        findsOneWidget,
      );

      await tapVisible(
        tester,
        find.byKey(
          const Key('accept-recommended-primary-heating-element-failed'),
        ),
      );

      await reachClosePathVerificationIfPresent(tester);
      expect(find.byKey(const Key('pro-recommended-card')), findsOneWidget);
      expect(find.byKey(const Key('close-answer-choice-panel')), findsNothing);
      expect(find.byKey(const Key('answer-choice-panel')), findsNothing);

      await tapVisible(
        tester,
        find.byKey(const Key('pro-handoff-understand')),
      );
      await saveSessionOutcome(
        tester,
        choiceKey: const Key('outcome-needs-professional'),
      );

      expect(find.text('Needs a professional'), findsWidgets);
    },
  );

  testWidgets(
    'manual browse still allows selecting a different primary',
    (tester) async {
      final dependencies = AppDependencies(
        clock: () => DateTime.utc(2026, 7, 24, 11, 30),
      );
      await openDryerSession(tester, dependencies, 'Manual Browse Household');

      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );

      await selectFailureMode(tester, 'heating-element-failed');
      await reachClosePathVerificationIfPresent(tester);

      expect(find.byKey(const Key('pro-recommended-card')), findsOneWidget);
      expect(find.byKey(const Key('close-answer-choice-panel')), findsNothing);
    },
  );
}
