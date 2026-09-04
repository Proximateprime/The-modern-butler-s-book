import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets(
    'thermal-fuse-open Primary reaches verification, not hazard hard-stop',
    (tester) async {
      final dependencies = AppDependencies(
        clock: () => DateTime.utc(2026, 7, 24, 14),
      );
      await openDryerSession(tester, dependencies, 'Thermal Fuse Household');

      await selectObservation(tester, 'heat-observed');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-no-warmth')),
      );
      await selectObservation(tester, 'cycle-heat-setting');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-yes-heat-cycle')),
      );
      await selectObservation(tester, 'recent-overheat');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-yes-very-hot-or-shut-off-from-heat')),
      );

      expect(find.byKey(const Key('recommended-primary-card')), findsNothing);

      await selectObservation(tester, 'exterior-airflow');
      if (find.byKey(const Key('inspect-chip-doesnt-match')).evaluate().isNotEmpty) {
        await tapVisible(
          tester,
          find.byKey(const Key('inspect-chip-doesnt-match')),
        );
      } else {
        await tapVisible(tester, find.byKey(const Key('answer-choice-weak')));
      }

      expect(find.byKey(const Key('recommended-primary-card')), findsNothing);

      await selectObservation(tester, 'clothes-feel-after-cycle');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-cold-and-still-damp')),
      );

      expect(find.byKey(const Key('recommended-primary-card')), findsOneWidget);
      expect(
        find.byKey(const Key('recommended-primary-label-thermal-fuse-open')),
        findsOneWidget,
      );

      await tapVisible(
        tester,
        find.byKey(const Key('accept-recommended-primary-thermal-fuse-open')),
      );

      await advanceClosePathFromConclusionIfPresent(tester);
      await completeInspectStepsIfPresent(tester);
      expect(find.byKey(const Key('repair-readiness-card')), findsOneWidget);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);

      await completeRepairReadinessIfPresent(tester);

      expect(find.byKey(const Key('safety-stop-banner')), findsNothing);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(
        find.textContaining('lint filter'),
        findsWidgets,
      );
      expect(find.textContaining('Open the heater service panel'), findsNothing);
      expect(find.textContaining('Hand off to a qualified technician'), findsNothing);

      await completeGuidanceStepsIfPresent(tester);

      expect(find.byKey(const Key('pro-recommended-card')), findsOneWidget);
      expect(find.byKey(const Key('verification-card')), findsNothing);
      expect(find.byKey(const Key('guidance-step-progress')), findsNothing);
      expect(find.byKey(const Key('pro-handoff-why')), findsOneWidget);
      expect(find.textContaining('What a technician should be told'), findsOneWidget);
      expect(find.textContaining('thermal fuse'), findsWidgets);

      await tapVisible(
        tester,
        find.byKey(const Key('pro-handoff-understand')),
      );
      expect(find.byKey(const Key('outcome-needs-professional')), findsOneWidget);
    },
  );

  testWidgets(
    'thermal-fuse after I\'ll repair does not lecture that DIY cannot finish',
    (tester) async {
      final dependencies = AppDependencies(
        clock: () => DateTime.utc(2026, 7, 24, 14, 5),
      );
      await openDryerSession(tester, dependencies, 'Pro Scope House');
      await selectFailureMode(tester, 'thermal-fuse-open');
      await advanceClosePathFromConclusionIfPresent(tester);
      await completeInspectStepsIfPresent(tester);
      await markRepairReadinessHaveIfPresent(tester);
      final cont = find.byKey(const Key('close-path-tools-continue'));
      if (cont.evaluate().isNotEmpty) {
        await tapVisible(tester, cont);
      }

      expect(find.byKey(const Key('pro-scope-warning-card')), findsNothing);
      expect(find.textContaining('A full fix likely needs a pro'), findsNothing);
      expect(
        find.textContaining('won’t be able to finish the repair yourself at home'),
        findsNothing,
      );
      expect(
        find.textContaining('A technician fits this part on this path'),
        findsNothing,
      );
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.textContaining('Step 1 of'), findsOneWidget);
      expect(
        find.textContaining('Hand off to a qualified technician'),
        findsNothing,
      );
    },
  );

  testWidgets('burning/smoke hazard still hard-stops to professional path', (
    tester,
  ) async {
    final dependencies = AppDependencies(
      clock: () => DateTime.utc(2026, 7, 24, 14, 15),
    );
    await openDryerSession(tester, dependencies, 'Hazard Household');

    await selectObservation(tester, 'hazard-observation');
    await tapVisible(tester, find.byKey(const Key('answer-choice-yes')));

      expect(find.byKey(const Key('safety-stop-banner')), findsOneWidget);
      expect(find.byKey(const Key('verification-card')), findsNothing);
      expect(find.byKey(const Key('answer-choice-panel')), findsNothing);
      expect(find.byKey(const Key('failure-modes-tile')), findsNothing);
      expect(
        find.text('Needs a professional'),
        findsWidgets,
      );
  });
}
