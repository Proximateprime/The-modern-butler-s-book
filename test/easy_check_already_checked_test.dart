import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/easy_check_already_checked.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets(
    'dryer easy-check questions offer Already checked beside Not sure',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 18));
      await openDryerSession(
        tester,
        deps,
        'Already Checked Interview',
        skipProblemStarter: false,
      );
      await confirmNoHeatStarter(tester);
      await answerObservation(tester, 'drum-turns', 'turns-normally');

      expect(
        find.byKey(const Key('inspect-step-card-inspect-lint-filter')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('inspect-look-for')), findsOneWidget);
      expect(find.byKey(const Key('inspect-chip-already-checked')), findsOneWidget);
      expect(find.text('Already checked'), findsOneWidget);
      expect(find.text("Can't see"), findsOneWidget);

      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-already-checked')),
      );
      expect(
        find.byKey(const Key('inspect-step-card-inspect-vent-hood')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'washer drain easy checks offer Already checked on door click',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 18, 10));
      await openWasherSession(tester, deps, 'Already Checked Washer');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-won-t-drain')),
      );
      expect(
        find.byKey(const Key('inspect-step-card-inspect-washer-door-click')),
        findsOneWidget,
      );
      expect(find.text('Already checked'), findsOneWidget);
      expect(find.text("Can't see"), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-already-checked')),
      );
      expect(
        find.byKey(const Key('inspect-step-card-inspect-washer-drain-filter')),
        findsOneWidget,
      );
      expect(find.text('Already checked'), findsOneWidget);
    },
  );

  testWidgets(
    'Already checked on inspect unlocks panel after lint, hood, and hose',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 18, 20));
      await openDryerSession(tester, deps, 'Already Checked Guidance');
      await selectFailureMode(tester, 'thermal-fuse-open');
      await advanceClosePathFromConclusionIfPresent(tester);

      expect(
        find.byKey(const Key('inspect-step-card-inspect-lint-filter')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('inspect-chip-already-checked')), findsOneWidget);
      expect(find.textContaining('Open the heater service panel'), findsNothing);

      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-already-checked')),
      );
      expect(
        find.byKey(const Key('inspect-step-card-inspect-vent-hood')),
        findsOneWidget,
      );
      expect(find.textContaining('Open the heater service panel'), findsNothing);
      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-already-checked')),
      );
      expect(
        find.byKey(const Key('inspect-step-card-inspect-vent-hose')),
        findsOneWidget,
      );
      expect(find.textContaining('Open the heater service panel'), findsNothing);
      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-already-checked')),
      );

      await completeRepairReadinessIfPresent(tester);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.byKey(const Key('guidance-did-this')), findsOneWidget);
      expect(find.byKey(const Key('guidance-could-not')), findsOneWidget);
      expect(find.textContaining('Open the heater service panel'), findsNothing);
      var sawTechnician = false;
      for (var i = 0; i < 8; i++) {
        if (find.textContaining('technician').evaluate().isNotEmpty) {
          sawTechnician = true;
          break;
        }
        await tapVisible(tester, find.byKey(const Key('guidance-did-this')));
      }
      expect(sawTechnician, isTrue);
      expect(find.textContaining('Open the heater service panel'), findsNothing);
    },
  );

  testWidgets(
    "Can't see on inspect is a valid skip and still blocks the panel until all three",
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 9));
      await openDryerSession(tester, deps, 'Cant See Inspect Gate');
      await selectFailureMode(tester, 'thermal-fuse-open');
      await advanceClosePathFromConclusionIfPresent(tester);

      expect(
        find.byKey(const Key('inspect-step-card-inspect-lint-filter')),
        findsOneWidget,
      );
      expect(find.textContaining('Open the heater service panel'), findsNothing);
      await tapVisible(tester, find.byKey(const Key('inspect-chip-cant-see')));
      expect(
        find.byKey(const Key('inspect-step-card-inspect-vent-hood')),
        findsOneWidget,
      );
      expect(find.textContaining('Open the heater service panel'), findsNothing);
      await tapVisible(tester, find.byKey(const Key('inspect-chip-cant-see')));
      expect(
        find.byKey(const Key('inspect-step-card-inspect-vent-hose')),
        findsOneWidget,
      );
      expect(find.textContaining('Open the heater service panel'), findsNothing);
      await tapVisible(tester, find.byKey(const Key('inspect-chip-cant-see')));

      await completeRepairReadinessIfPresent(tester);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.textContaining('Open the heater service panel'), findsNothing);
      var sawTechnician = false;
      for (var i = 0; i < 8; i++) {
        if (find.textContaining('technician').evaluate().isNotEmpty) {
          sawTechnician = true;
          break;
        }
        await tapVisible(tester, find.byKey(const Key('guidance-did-this')));
      }
      expect(sawTechnician, isTrue);
      expect(find.textContaining('Open the heater service panel'), findsNothing);
    },
  );

  testWidgets(
    'dishwasher door and filter questions offer Already checked',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 12));
      await openDishwasherSession(tester, deps, 'Already Checked Dishwasher');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-standing-water')),
      );
      expect(
        find.byKey(const Key('inspect-step-card-inspect-dishwasher-filter')),
        findsOneWidget,
      );
      expect(find.text('Already checked'), findsOneWidget);
      expect(find.text("Can't see"), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-already-checked')),
      );
    },
  );

  testWidgets(
    'dishwasher filter guidance offers I already did this',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 12, 5));
      await openDishwasherSession(tester, deps, 'Already Did Filter');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-standing-water')),
      );
      await selectFailureMode(tester, 'clogged-dishwasher-filter');
      await completeRepairReadinessIfPresent(tester);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.byKey(const Key('guidance-already-checked')), findsOneWidget);
      expect(find.text(alreadyDidThisEasyCheckLabel), findsOneWidget);
      expect(find.byKey(const Key('guidance-could-not')), findsOneWidget);
    },
  );
}
