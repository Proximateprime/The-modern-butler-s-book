import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/helpers/repair_readiness.dart';
import 'package:modern_butlers_book/models/session_objective.dart';
import 'package:modern_butlers_book/models/session_ui_resume_state.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';

import 'support/session_test_helpers.dart';

void main() {
  test('resume JSON round-trips close-path step fields', () {
    const resume = SessionUiResumeState(
      closePathPhase: ClosePathPhase.guidance,
      choseRepair: true,
      guidanceStepIndex: 2,
      completedGuidanceStepIds: ['0:unplug', '1:lint'],
      proScopeAcknowledged: true,
    );
    final restored = SessionUiResumeState.fromJson(resume.toJson());
    expect(restored.closePathPhase, ClosePathPhase.guidance);
    expect(restored.choseRepair, isTrue);
    expect(restored.guidanceStepIndex, 2);
    expect(restored.completedGuidanceStepIds, ['0:unplug', '1:lint']);
    expect(restored.proScopeAcknowledged, isTrue);
  });

  test('missing required tool blocks invasive panel steps', () {
    const screwdriver = RepairReadinessItem(
      id: 'screwdriver',
      label: 'Screwdriver',
      optional: false,
      liveElectrical: false,
    );
    final gated = guidanceStepsForToolsGate(
      steps: const [
        'Unplug the dryer.',
        'Open the heater service panel.',
        'Replace the thermal fuse.',
      ],
      missingRequiredTool: true,
      continueWithCaution: true,
    );
    expect(gated, ['Unplug the dryer.']);
    expect(missingRequiredTools(items: const [screwdriver], haveByToolId: const {'screwdriver': false}), hasLength(1));
  });

  test('missing washer pan blocks opening the drain filter, not the look step', () {
    const pan = RepairReadinessItem(
      id: 'shallow-pan',
      label: 'Shallow pan and towel',
      optional: false,
      liveElectrical: false,
    );
    const flashlight = RepairReadinessItem(
      id: 'flashlight',
      label: 'Flashlight (optional)',
      optional: true,
      liveElectrical: false,
    );
    expect(
      missingRequiredTools(
        items: const [pan, flashlight],
        haveByToolId: const {'shallow-pan': true, 'flashlight': false},
      ),
      isEmpty,
    );
    final gated = guidanceStepsForToolsGate(
      steps: const [
        'Look for an accessible drain filter at the front or bottom.',
        'Place a shallow pan and towel under the accessible drain filter.',
        'Open only the user-accessible filter or pump trap.',
      ],
      missingRequiredTool: true,
      continueWithCaution: true,
    );
    expect(gated, [
      'Look for an accessible drain filter at the front or bottom.',
    ]);
  });

  testWidgets('close path is stepped: conclusion, then tools, then one guidance step', (
    tester,
  ) async {
    final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 12));
    await openDryerSession(tester, deps, 'Stepped Close Path');
    await selectFailureMode(tester, 'thermal-fuse-open');

    expect(find.byKey(const Key('current-conclusion-card')), findsOneWidget);
    expect(find.byKey(const Key('parts-cost-card')), findsNothing);
    expect(find.byKey(const Key('repair-readiness-card')), findsNothing);
    expect(find.byKey(const Key('safe-guidance-card')), findsNothing);

    await tapVisible(tester, find.byKey(const Key('close-path-continue')));
    expect(find.byKey(const Key('close-path-ill-repair')), findsOneWidget);
    expect(find.byKey(const Key('parts-cost-card')), findsNothing);
    expect(find.byKey(const Key('safe-guidance-card')), findsNothing);

    await tapVisible(tester, find.byKey(const Key('close-path-ill-repair')));
    expect(find.byKey(const Key('parts-cost-card')), findsOneWidget);
    expect(find.text("I'll repair"), findsNothing);
    expect(find.byKey(const Key('safe-guidance-card')), findsNothing);

    await tapVisible(tester, find.byKey(const Key('close-path-parts-continue')));
    expect(
      find.byKey(const Key('inspect-step-card-inspect-lint-filter')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('repair-readiness-card')), findsNothing);
    await completeInspectStepsIfPresent(tester);
    expect(find.byKey(const Key('repair-readiness-card')), findsOneWidget);
    expect(find.byKey(const Key('safe-guidance-card')), findsNothing);

    await completeRepairReadinessIfPresent(tester);
    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    expect(find.byKey(const Key('guidance-did-this')), findsOneWidget);
    expect(find.byKey(const Key('guidance-could-not')), findsOneWidget);
    expect(find.textContaining('Step 1 of'), findsOneWidget);
    expect(find.byKey(const Key('verification-card')), findsNothing);

    await tapVisible(tester, find.byKey(const Key('guidance-did-this')));
    expect(find.textContaining('Step 2 of'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await startRepairFromDetail(tester);
    await dismissProblemStarterIfPresent(tester);

    expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    expect(find.textContaining('Step 2 of'), findsOneWidget);
  });

  test('first incomplete index skips completed guidance step ids', () {
    const steps = ['Lint filter', 'Vent hood', 'Vent hose', 'Unplug'];
    expect(
      firstIncompleteGuidanceIndex(
        steps: steps,
        completedIds: [
          guidanceStepId(0, steps[0]),
          guidanceStepId(1, steps[1]),
        ],
      ),
      2,
    );
  });

  test('resumeClosePathPhase keeps decision until guidance has started', () {
    expect(
      resumeClosePathPhase(
        stored: ClosePathPhase.decision,
        completedIds: const [],
      ),
      ClosePathPhase.decision,
    );
    expect(
      resumeClosePathPhase(
        stored: ClosePathPhase.conclusion,
        completedIds: const ['0:lint'],
      ),
      ClosePathPhase.guidance,
    );
    expect(
      resumeClosePathPhase(
        stored: ClosePathPhase.tools,
        completedIds: const [],
        choseRepair: true,
        toolsChecklistComplete: true,
      ),
      ClosePathPhase.guidance,
    );
    expect(
      resumeClosePathPhase(
        stored: ClosePathPhase.tools,
        completedIds: const [],
        choseRepair: true,
        toolsChecklistComplete: false,
      ),
      ClosePathPhase.tools,
    );
    expect(
      resumeClosePathPhase(
        stored: ClosePathPhase.conclusion,
        completedIds: const [],
        choseRepair: false,
        toolsChecklistComplete: true,
      ),
      ClosePathPhase.conclusion,
    );
    expect(
      resumeClosePathPhase(
        stored: ClosePathPhase.inspect,
        completedIds: const [],
        choseRepair: false,
        hasIncompleteInspect: false,
      ),
      ClosePathPhase.inspect,
    );
    expect(
      resumeClosePathPhase(
        stored: ClosePathPhase.inspect,
        completedIds: const [],
        choseRepair: true,
        hasIncompleteInspect: true,
      ),
      ClosePathPhase.inspect,
    );
    expect(
      resumeClosePathPhase(
        stored: ClosePathPhase.inspect,
        completedIds: const [],
        choseRepair: true,
        hasIncompleteInspect: false,
      ),
      ClosePathPhase.guidance,
    );
    expect(
      resumeClosePathPhase(
        stored: ClosePathPhase.tools,
        completedIds: const [],
        choseRepair: true,
        toolsChecklistComplete: true,
        hasIncompleteInspect: true,
      ),
      ClosePathPhase.inspect,
    );
    expect(
      resumeClosePathPhase(
        stored: ClosePathPhase.guidance,
        completedIds: const ['0:lint'],
        choseRepair: true,
        hasIncompleteInspect: true,
      ),
      ClosePathPhase.inspect,
    );
      expect(
        phaseAfterConclusion(
          objective: SessionObjective.figureOutWhatsWrong,
          hasParts: false,
          hasTools: false,
          hasIncompleteInspect: true,
        ),
        ClosePathPhase.inspect,
      );
    expect(
      phaseAfterRepairChoice(
        objective: null,
        hasParts: false,
        hasTools: true,
        hasIncompleteInspect: true,
      ),
      ClosePathPhase.inspect,
    );
  });

  testWidgets(
    'Continue repair after two guidance steps lands on step 3',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 13));
      await openDryerSession(tester, deps, 'Guidance Resume');
      await selectFailureMode(tester, 'thermal-fuse-open');
      await completeRepairReadinessIfPresent(tester);

      expect(find.textContaining('Step 1 of'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('guidance-did-this')));
      expect(find.textContaining('Step 2 of'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('guidance-did-this')));
      expect(find.textContaining('Step 3 of'), findsOneWidget);

      final session = deps.repairSessionRepository.listAllSessions().single;
      final saved = deps.uiResumeForSession(session.id);
      expect(saved?.closePathPhase, ClosePathPhase.guidance);
      expect(saved?.completedGuidanceStepIds, hasLength(2));
      expect(saved?.guidanceStepIndex, 2);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await startRepairFromDetail(tester);
      await dismissProblemStarterIfPresent(tester);

      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.byKey(const Key('guidance-step-progress')), findsOneWidget);
      expect(find.textContaining('Step 3 of'), findsOneWidget);
      expect(find.textContaining('Step 1 of'), findsNothing);
      expect(find.textContaining('Step 2 of'), findsNothing);
    },
  );

  testWidgets(
    'Continue repair before guidance stays on the decision screen',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 18, 14));
      await openDryerSession(tester, deps, 'Guidance Not Started');
      await selectFailureMode(tester, 'thermal-fuse-open');
      await tapVisible(tester, find.byKey(const Key('close-path-continue')));
      expect(find.byKey(const Key('close-path-ill-repair')), findsOneWidget);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await startRepairFromDetail(tester);
      await dismissProblemStarterIfPresent(tester);

      expect(find.byKey(const Key('close-path-ill-repair')), findsOneWidget);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
    },
  );
}
