import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/knowledge_factory/washer_mvp_v01.dart';
import 'package:modern_butlers_book/models/session_outcome.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  testWidgets(
    'dryer restricted-exhaust: inspect → conclusion → tools → guidance → resume → Fixed → history',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 15));
      await openDryerSession(tester, deps, 'Trace Dryer Exhaust');
      await selectFailureMode(tester, 'restricted-exhaust-airflow');

      expect(find.byKey(const Key('current-conclusion-card')), findsOneWidget);
      expect(find.byKey(const Key('inspect-step-card-inspect-lint-filter')), findsNothing);
      expect(find.byKey(const Key('repair-readiness-card')), findsNothing);
      await tapVisible(tester, find.byKey(const Key('close-path-continue')));
      expect(find.byKey(const Key('close-path-ill-repair')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('close-path-ill-repair')));
      expect(
        find.byKey(const Key('inspect-step-card-inspect-lint-filter')),
        findsOneWidget,
      );
      expect(find.text('Inspect 1 of 3'), findsOneWidget);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
      await completeInspectStepsIfPresent(tester);
      final partsContinue = find.byKey(const Key('close-path-parts-continue'));
      if (partsContinue.evaluate().isNotEmpty) {
        await tapVisible(tester, partsContinue);
      }

      expect(find.byKey(const Key('repair-readiness-card')), findsOneWidget);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
      await markRepairReadinessHaveIfPresent(tester);
      await tapVisible(tester, find.byKey(const Key('close-path-tools-continue')));

      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.textContaining('Step 1 of'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('guidance-did-this')));
      expect(find.textContaining('Step 2 of'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('guidance-did-this')));
      expect(find.textContaining('Step 3 of'), findsOneWidget);

      final session = deps.repairSessionRepository.listAllSessions().single;
      expect(
        deps.uiResumeForSession(session.id)?.closePathPhase,
        ClosePathPhase.guidance,
      );
      expect(
        deps.uiResumeForSession(session.id)?.completedGuidanceStepIds,
        hasLength(2),
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      await startRepairFromDetail(tester);
      await dismissProblemStarterIfPresent(tester);

      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.textContaining('Step 3 of'), findsOneWidget);

      await completeGuidanceStepsIfPresent(tester);
      await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
      await tapVisible(tester, find.byKey(const Key('end-session-button')));
      await saveSessionOutcome(tester);

      final dryer = deps.appliancesForCurrentHousehold().single;
      final history = deps.repairHistoryForAppliance(dryer.id);
      expect(history, hasLength(1));
      expect(history.single.outcome.closeKind, SessionCloseKind.fixed);
      await tester.tap(find.byKey(Key('appliance-${dryer.id}')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(Key('repair-history-${history.single.outcome.sessionId}')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'washer won’t-drain: inspect → conclusion → tools → guidance → resume → Fixed → history',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 15, 20));
      await openWasherSession(tester, deps, 'Trace Washer Drain Inspect');

      expect(find.text('What is the washer doing?'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('answer-choice-won-t-drain')));
      await selectFailureMode(tester, washerCloggedDrainFilterId);

      expect(find.byKey(const Key('current-conclusion-card')), findsOneWidget);
      expect(
        find.byKey(const Key('inspect-step-card-inspect-washer-door-click')),
        findsNothing,
      );
      await tapVisible(tester, find.byKey(const Key('close-path-continue')));
      expect(find.byKey(const Key('close-path-ill-repair')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('close-path-ill-repair')));
      expect(
        find.byKey(const Key('inspect-step-card-inspect-washer-door-click')),
        findsOneWidget,
      );
      expect(find.text('Inspect 1 of 2'), findsOneWidget);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
      await completeInspectStepsIfPresent(tester);
      final partsContinue = find.byKey(const Key('close-path-parts-continue'));
      if (partsContinue.evaluate().isNotEmpty) {
        await tapVisible(tester, partsContinue);
      }

      expect(find.byKey(const Key('repair-readiness-card')), findsOneWidget);
      expect(find.byKey(const Key('readiness-tool-shallow-pan')), findsOneWidget);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
      await markRepairReadinessHaveIfPresent(tester);
      await tapVisible(tester, find.byKey(const Key('close-path-tools-continue')));

      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.textContaining('Step 1 of'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('guidance-did-this')));
      expect(find.textContaining('Step 2 of'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('guidance-did-this')));
      expect(find.textContaining('Step 3 of'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await startRepairFromDetail(tester);

      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.textContaining('Step 3 of'), findsOneWidget);

      await completeGuidanceStepsIfPresent(tester);
      await tapVisible(tester, find.byKey(const Key('answer-choice-confirmed')));
      await tapVisible(tester, find.byKey(const Key('end-session-button')));
      await saveSessionOutcome(tester);

      final washer = deps.appliancesForCurrentHousehold().single;
      final history = deps.repairHistoryForAppliance(washer.id);
      expect(history, hasLength(1));
      expect(history.single.outcome.closeKind, SessionCloseKind.fixed);
      await tester.tap(find.byKey(Key('appliance-${washer.id}')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(Key('repair-history-${history.single.outcome.sessionId}')),
        findsOneWidget,
      );
    },
  );
}
