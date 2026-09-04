import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/blocking_reason.dart';
import 'package:modern_butlers_book/helpers/close_path_phase.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/easy_airflow_checks.dart';
import 'package:modern_butlers_book/helpers/easy_check_already_checked.dart';
import 'package:modern_butlers_book/helpers/evidence_prompt_match.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/inspect_steps.dart';
import 'package:modern_butlers_book/helpers/location_visual_aids.dart';
import 'package:modern_butlers_book/helpers/pro_scope.dart';
import 'package:modern_butlers_book/helpers/visual_guide.dart';
import 'package:modern_butlers_book/knowledge_factory/dishwasher_inspect_steps.dart';
import 'package:modern_butlers_book/knowledge_factory/dryer_inspect_steps.dart';
import 'package:modern_butlers_book/knowledge_factory/fridge_inspect_steps.dart';
import 'package:modern_butlers_book/knowledge_factory/washer_inspect_steps.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/inspect_step.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/ui/app_dependencies.dart';
import 'package:modern_butlers_book/ui/inspect_step_card.dart';

import 'support/session_test_helpers.dart';

Evidence _recorded(String templateId, String answer) {
  return Evidence(
    id: 'e-$templateId',
    sessionId: 's',
    applianceId: 'a',
    type: EvidenceType.structuredAnswer,
    observation: templateId,
    answer: answer,
    templateId: templateId,
    collectedAt: DateTime.utc(2026, 8, 19),
    collectedInState: RepairSessionState.evidenceCollection,
    source: EvidenceSource.user,
    schemaVersion: '1.0',
  );
}

void main() {
  test('dryer package ships lint → hood → hose inspect steps', () {
    final package = KnowledgePackageRepository().loadById('dryer-core')!;
    expect(package.version, '1.4.2');
    expect(
      package.inspectSteps.map((step) => step.id).toList(),
      [
        dryerLintFilterInspectStep.id,
        dryerVentHoodInspectStep.id,
        dryerVentHoseInspectStep.id,
      ],
    );

    for (final modeId in [
      'clogged-lint-pathway',
      'restricted-exhaust-airflow',
      'heating-element-failed',
      'thermal-fuse-open',
    ]) {
      final path = closePathForFailureMode(modeId)!;
      final steps = inspectStepsForClosePath(
        closePath: path,
        packageSteps: package.inspectSteps,
      );
      expect(
        steps.map((step) => step.evidenceTemplateId).toList(),
        [
          'lint-filter-condition',
          'exterior-airflow',
          'vent-hose-condition',
        ],
        reason: modeId,
      );
      expect(steps.every((step) => step.cameraMode == InspectCameraMode.viewOnly), isTrue);
      expect(steps.every((step) => step.appliesTo == 'dryer'), isTrue);
      expect(steps.every((step) => step.beginnerSafe && step.noLiveElectrical), isTrue);
      expect(steps.every((step) => step.frameHint != null), isTrue);
    }
  });

  test('diagram: ids are not curated inspect images', () {
    expect(inspectHasCuratedImage('diagram:dryer-front'), isFalse);
    expect(inspectHasCuratedImage(''), isFalse);
    expect(inspectHasCuratedImage('assets/inspect/lint-filter.png'), isFalse);
    expect(inspectHasCuratedImage(dryerFrontInspectAsset), isFalse);
    expect(inspectUsesDryerSchematic(dryerFrontInspectAsset), isTrue);
    expect(inspectUsesDryerSchematic('diagram:dryer-front'), isFalse);
    expect(arParked, isTrue);
    expect(locationVisualAidsEnabled, isFalse);
  });

  test('lint-filter template maps to the dryer inspect step', () {
    expect(
      inspectStepForEvidenceTemplate(
        templateId: 'lint-filter-condition',
        applianceCategory: 'dryer',
      )?.id,
      dryerLintFilterInspectStep.id,
    );
  });

  test('inspect look-for copy names one physical check per step', () {
    expect(
      dryerLintFilterInspectStep.lookFor,
      contains('rectangular mesh screen'),
    );
    expect(dryerVentHoodInspectStep.lookFor, contains('vent flap'));
    expect(dryerVentHoseInspectStep.lookFor, contains('rear exhaust collar'));
    expect(washerDoorClickInspectStep.lookFor, contains('solid click'));
    expect(washerDrainFilterInspectStep.lookFor, contains('coin trap'));
    expect(dishwasherFilterInspectStep.lookFor, contains('lower dish rack'));
    expect(dishwasherDoorClickInspectStep.lookFor, contains('top-center latch'));
    expect(dishwasherDrainHoseInspectStep.lookFor, contains('high loop'));
    expect(dishwasherSupplyInspectStep.lookFor, contains('supply tap'));
    expect(dishwasherSprayInspectStep.lookFor, contains('spray'));
    expect(dishwasherLeakInspectStep.lookFor, contains('gasket'));
    expect(fridgeTempsInspectStep.lookFor, contains('digital setpoints'));
    expect(fridgeDoorSealInspectStep.lookFor, contains('gasket'));
    expect(fridgeVentsInspectStep.lookFor, contains('slotted air vents'));
    expect(fridgeCoilsInspectStep.lookFor, contains('toe-kick'));
  });

  test('first incomplete inspect step follows recorded evidence in order', () {
    final steps = inspectStepsForFailureMode(
      failureModeId: 'heating-element-failed',
      packageSteps: dryerPackageInspectSteps,
    );
    expect(
      firstIncompleteInspectStep(steps: steps, recordedEvidence: const [])?.id,
      dryerLintFilterInspectStep.id,
    );
    expect(
      firstIncompleteInspectStep(
        steps: steps,
        recordedEvidence: [_recorded('lint-filter-condition', 'Clean')],
      )?.id,
      dryerVentHoodInspectStep.id,
    );
    expect(
      firstIncompleteInspectStep(
        steps: steps,
        recordedEvidence: [
          _recorded('lint-filter-condition', 'Clean'),
          _recorded('exterior-airflow', 'Normal'),
        ],
      )?.id,
      dryerVentHoseInspectStep.id,
    );
    expect(
      firstIncompleteInspectStep(
        steps: steps,
        recordedEvidence: [
          _recorded('lint-filter-condition', 'Clean'),
          _recorded('exterior-airflow', 'Normal'),
          _recorded('vent-hose-condition', 'Looks clear'),
        ],
      ),
      isNull,
    );
    expect(
      inspectProgress(steps: steps, recordedEvidence: const []).current,
      1,
    );
    expect(
      inspectProgress(
        steps: steps,
        recordedEvidence: [_recorded('lint-filter-condition', 'Clean')],
      ),
      (current: 2, total: 3),
    );
    expect(
      inspectProgressLabel(current: 2, total: 3),
      'Inspect 2 of 3',
    );
    expect(
      closePathPhaseHonoringInspect(
        requested: ClosePathPhase.guidance,
        hasIncompleteInspect: true,
      ),
      ClosePathPhase.inspect,
    );
  });

  testWidgets(
    'no-heat path shows lint, hood, then hose inspect before guidance',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 13));
      await openDryerSession(
        tester,
        deps,
        'No Heat Inspect House',
        priorRepairHistory: true,
      );
      await selectFailureMode(tester, 'thermal-fuse-open');
      await advanceClosePathFromConclusionIfPresent(tester);

      expect(
        find.byKey(const Key('inspect-step-card-inspect-lint-filter')),
        findsOneWidget,
      );
      expect(find.text('Inspect 1 of 3'), findsOneWidget);
      expect(find.byKey(const Key('inspect-look-for')), findsOneWidget);
      expect(find.byKey(const Key('inspect-look-for-heading')), findsOneWidget);
      expect(
        find.text(UserFacingCopy.inspectTypicalLocationCaption),
        findsNothing,
      );
      expect(
        find.text(blockingReasonInspectIncompleteLine),
        findsOneWidget,
      );
      expect(find.textContaining('rectangular mesh screen'), findsOneWidget);
      expect(find.textContaining('packed lint'), findsOneWidget);
      expect(find.byKey(const Key('inspect-diagram')), findsNothing);
      expect(find.byKey(const Key('inspect-frame-hint')), findsNothing);
      expect(find.byKey(const Key('inspect-location-icon')), findsNothing);
      expect(find.byKey(const Key('inspect-media-tabs')), findsNothing);
      expect(find.byKey(const Key('visual-guide-target-box')), findsNothing);
      expect(find.text(alreadyCheckedEasyCheckAnswer), findsOneWidget);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);

      await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
      expect(
        find.byKey(const Key('inspect-step-card-inspect-vent-hood')),
        findsOneWidget,
      );
      expect(find.text('Inspect 2 of 3'), findsOneWidget);
      expect(find.textContaining('Stand to the side'), findsOneWidget);
      expect(find.byKey(const Key('inspect-diagram')), findsNothing);
      expect(find.byKey(const Key('inspect-frame-hint')), findsNothing);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);

      await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
      expect(
        find.byKey(const Key('inspect-step-card-inspect-vent-hose')),
        findsOneWidget,
      );
      expect(find.text('Inspect 3 of 3'), findsOneWidget);
      expect(find.textContaining('Unplug the dryer before pulling'), findsOneWidget);
      expect(find.textContaining('crushed'), findsWidgets);
      expect(find.byKey(const Key('inspect-diagram')), findsNothing);

      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-doesnt-match')),
      );
      await completeRepairReadinessIfPresent(tester);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);

      final dryer = deps.appliancesForCurrentHousehold().single;
      final sessionId = deps.startOrResumeSession(dryer);
      final session = deps.repairSessionRepository.getSession(sessionId)!;
      final evidence =
          deps.repairSessionRepository.evidenceForSession(session.id);
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'lint-filter-condition',
        ),
        'Clean',
      );
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'exterior-airflow',
        ),
        'Normal',
      );
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'vent-hose-condition',
        ),
        'Yes, restricted',
      );
    },
  );

  testWidgets(
    'inspect chips use the questionnaire evidence path and unlock airflow gating',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 13, 30));
      await openDryerSession(tester, deps, 'Inspect Evidence Gate');
      await selectFailureMode(tester, 'thermal-fuse-open');
      await advanceClosePathFromConclusionIfPresent(tester);

      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-doesnt-match')),
      );
      await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
      await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));

      final session = deps.repairSessionRepository.listAllSessions().single;
      final evidence =
          deps.repairSessionRepository.evidenceForSession(session.id);
      expect(
        evidence.every((item) => item.source == EvidenceSource.user),
        isTrue,
      );
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'lint-filter-condition',
        ),
        'Heavily clogged',
      );
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'exterior-airflow',
        ),
        'Normal',
      );
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'vent-hose-condition',
        ),
        'Looks clear',
      );

      final package = KnowledgePackageRepository().loadById('dryer-core')!;
      final standings = evaluateFailureModeStandings(
        package: package,
        evidence: evidence,
      );
      expect(standings['clogged-lint-pathway']!.isSupported, isTrue);

      final path = closePathForFailureMode('thermal-fuse-open')!;
      final ordered = orderEasyAirflowGuidanceFirst(path.safeGuidanceSteps);
      expect(
        easyAirflowChecksSatisfied(
          recordedEvidence: evidence,
          steps: ordered,
          completedIds: const [],
        ),
        isTrue,
      );
      expect(
        guidanceStepsForEasyAirflowGate(
          steps: ordered,
          easyChecksSatisfied: true,
        ).any((step) => step.toLowerCase().contains('qualified technician')),
        isTrue,
      );

      await completeRepairReadinessIfPresent(tester);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      final progress = tester.widget<Text>(
        find.byKey(const Key('guidance-step-progress')),
      );
      expect(
        progress.data,
        'Step 1 of ${safeCheckGuidanceSteps(ordered).length}',
      );
      expect(
        find.text(blockingReasonInspectIncompleteLine),
        findsNothing,
      );
    },
  );

  testWidgets(
    'inspect chips record lint-filter evidence and survive leaving the session',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 12));
      await openDryerSession(tester, deps, 'Inspect Lint House');
      await selectFailureMode(tester, 'clogged-lint-pathway');
      await advanceClosePathFromConclusionIfPresent(tester);

      expect(
        find.byKey(const Key('inspect-step-card-inspect-lint-filter')),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      await startRepairFromDetail(tester);
      await dismissProblemStarterIfPresent(tester);

      expect(
        find.byKey(const Key('inspect-step-card-inspect-lint-filter')),
        findsOneWidget,
      );
      expect(deps.uiResumeForSession(
        deps.repairSessionRepository.listAllSessions().single.id,
      )?.closePathPhase, ClosePathPhase.inspect);

      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-doesnt-match')),
      );

      final session = deps.repairSessionRepository.listAllSessions().single;
      expect(
        answerForTemplate(
          recordedEvidence:
              deps.repairSessionRepository.evidenceForSession(session.id),
          templateId: 'lint-filter-condition',
        ),
        'Heavily clogged',
      );
      expect(
        find.byKey(const Key('inspect-step-card-inspect-vent-hood')),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      await startRepairFromDetail(tester);
      await dismissProblemStarterIfPresent(tester);

      expect(
        find.byKey(const Key('inspect-step-card-inspect-vent-hood')),
        findsOneWidget,
      );
      expect(
        answerForTemplate(
          recordedEvidence:
              deps.repairSessionRepository.evidenceForSession(session.id),
          templateId: 'lint-filter-condition',
        ),
        'Heavily clogged',
      );
    },
  );

  test('washer package ships drain and standpipe/hose-setup inspect steps', () {
    final package = KnowledgePackageRepository().loadById('washer-core')!;
    expect(package.version, '0.2.3');
    expect(
      package.inspectSteps.map((step) => step.id).toList(),
      [
        washerDoorClickInspectStep.id,
        washerDrainFilterInspectStep.id,
        washerStandpipeInspectStep.id,
        washerDrainHoseConfigInspectStep.id,
        washerTapsInletInspectStep.id,
        washerInletScreensInspectStep.id,
        washerLeakTapInspectStep.id,
        washerPowerLockInspectStep.id,
      ],
    );
    expect(
      washerDrainFilterInspectStep.evidenceAnswerByChip[inspectMatchesOkChip],
      'No',
    );
    expect(
      washerDrainFilterInspectStep.evidenceAnswerByChip[inspectDoesntMatchChip],
      'Yes',
    );
    expect(
      package.inspectSteps.every((step) => step.appliesTo == 'washer'),
      isTrue,
    );
    expect(
      package.inspectSteps.any((step) => step.id.contains('lint-filter')),
      isFalse,
    );

    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('clogged-washer-drain-filter')!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      ['washer-door-click', 'washer-drain-filter-access'],
    );
    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('kinked-or-clogged-washer-drain-hose')!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      [
        'washer-door-click',
        'washer-drain-filter-access',
        'washer-drain-hose-look',
      ],
    );
    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('washer-drain-hose-not-seated')!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      ['washer-standpipe-hose', 'washer-drain-hose-look'],
    );
    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('washer-door-not-latched')!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      ['washer-door-click'],
    );
    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('closed-taps-or-kinked-inlet')!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      ['washer-taps-open'],
    );
    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('clogged-washer-inlet-screens')!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      ['washer-taps-open', 'washer-inlet-screens-look'],
    );
    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('loose-inlet-hose')!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      ['washer-leak-at-tap'],
    );
    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('washer-no-power-or-control-lock')!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      ['washer-power-or-lock'],
    );
    expect(
      inspectStepsForFailureMode(
        failureModeId: 'clogged-washer-drain-filter',
        packageSteps: [...dryerPackageInspectSteps, ...package.inspectSteps],
        applianceCategory: 'washer',
      ).map((step) => step.id),
      isNot(contains(dryerLintFilterInspectStep.id)),
    );
    expect(
      inspectDiagramAnchor(washerDrainFilterInspectStep).targetId,
      isNot('lint-filter'),
    );
    expect(
      inspectDiagramAnchor(washerDrainFilterInspectStep).imageAsset,
      isNot(contains('dryer')),
    );
    expect(
      inspectDiagramAnchor(dishwasherFilterInspectStep).targetId,
      isNot('lint-filter'),
    );
    expect(
      inspectDiagramAnchor(dishwasherFilterInspectStep).imageAsset,
      isNot(contains('dryer')),
    );
    expect(
      inspectDiagramAnchor(dishwasherSupplyInspectStep).targetId,
      isNot('lint-filter'),
    );
    expect(
      inspectDiagramAnchor(dishwasherSprayInspectStep).imageAsset,
      isNot(contains('dryer')),
    );
    expect(
      visualGuideUsesDryerLintFilterGraphic(
        inspectDiagramAnchor(washerDrainFilterInspectStep),
      ),
      isFalse,
    );
  });

  test('dishwasher package ships filter, door, hose, supply, spray, leak inspect', () {
    final package = KnowledgePackageRepository().loadById('dishwasher-core')!;
    expect(package.version, '0.2.3');
    expect(
      package.inspectSteps.map((step) => step.id).toList(),
      [
        dishwasherFilterInspectStep.id,
        dishwasherDoorClickInspectStep.id,
        dishwasherDrainHoseInspectStep.id,
        dishwasherSupplyInspectStep.id,
        dishwasherSprayInspectStep.id,
        dishwasherLeakInspectStep.id,
      ],
    );
    expect(
      package.inspectSteps.every((step) => step.appliesTo == 'dishwasher'),
      isTrue,
    );
    expect(
      package.inspectSteps.every(
        (step) => !step.diagramAsset.contains('dryer'),
      ),
      isTrue,
    );

    for (final modeId in [
      'clogged-dishwasher-filter',
      'kinked-or-clogged-dishwasher-drain',
    ]) {
      final steps = inspectStepsForClosePath(
        closePath: closePathForFailureMode(modeId)!,
        packageSteps: package.inspectSteps,
      );
      expect(
        steps.map((step) => step.evidenceTemplateId).toList(),
        [
          'dishwasher-filter-debris',
          'dishwasher-door-click',
          'dishwasher-drain-hose',
        ],
        reason: modeId,
      );
      expect(steps.every((step) => step.cameraMode == InspectCameraMode.viewOnly), isTrue);
    }

    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('dishwasher-door-not-latched')!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      ['dishwasher-door-click'],
    );
    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('closed-dishwasher-supply-or-air-gap')!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      ['dishwasher-supply-open'],
    );
    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('clogged-dishwasher-spray-arms')!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      ['dishwasher-filter-debris', 'dishwasher-spray-holes'],
    );
    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode(
          'dishwasher-door-seal-or-loose-connection',
        )!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      ['dishwasher-door-seal-leak'],
    );
  });

  test('fridge package ships temps, gasket, vents, coils inspect', () {
    final package = KnowledgePackageRepository().loadById('fridge-core')!;
    expect(package.version, '1.0.1');
    expect(
      package.inspectSteps.map((step) => step.id).toList(),
      [
        fridgeTempsInspectStep.id,
        fridgeDoorSealInspectStep.id,
        fridgeVentsInspectStep.id,
        fridgeCoilsInspectStep.id,
      ],
    );
    expect(
      package.inspectSteps.every((step) => step.appliesTo == 'fridge'),
      isTrue,
    );
    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('blocked-fridge-coils-or-airflow')!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      [
        'fridge-temps-or-settings',
        'fridge-door-seal',
        'fridge-internal-vents',
        'fridge-coils-or-space',
      ],
    );
    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('blocked-fridge-internal-vents')!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      ['fridge-door-seal', 'fridge-internal-vents'],
    );
    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('fridge-door-gasket-or-ajar')!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      ['fridge-door-seal'],
    );
    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('fridge-temp-controls-set-wrong')!,
        packageSteps: package.inspectSteps,
      ).map((step) => step.evidenceTemplateId).toList(),
      ['fridge-temps-or-settings', 'fridge-door-seal'],
    );
    expect(
      inspectStepsForClosePath(
        closePath: closePathForFailureMode('fridge-no-power-or-control')!,
        packageSteps: package.inspectSteps,
      ),
      isEmpty,
    );
  });

  testWidgets(
    'washer won\'t-drain path shows door then filter inspect before opening',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 14));
      await openWasherSession(tester, deps, 'Washer Drain Inspect');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-won-t-drain')),
      );
      await selectFailureMode(tester, 'clogged-washer-drain-filter');
      await advanceClosePathFromConclusionIfPresent(tester);

      expect(
        find.byKey(const Key('inspect-step-card-inspect-washer-door-click')),
        findsOneWidget,
      );
      expect(find.textContaining('solid click'), findsWidgets);
      expect(find.byKey(const Key('inspect-look-for')), findsOneWidget);
      expect(find.byKey(const Key('inspect-location-icon')), findsNothing);
      expect(find.byKey(const Key('inspect-diagram')), findsNothing);
      expect(find.byKey(const Key('inspect-frame-hint')), findsNothing);
      expect(find.textContaining('Open only the user-accessible filter'), findsNothing);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);

      await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
      expect(
        find.byKey(const Key('inspect-step-card-inspect-washer-drain-filter')),
        findsOneWidget,
      );
      expect(find.textContaining('Unplug the washer'), findsWidgets);
      expect(find.textContaining('coin trap'), findsWidgets);
      expect(find.textContaining('Open only the user-accessible filter'), findsNothing);
      expect(find.byKey(const Key('inspect-step-card-inspect-lint-filter')), findsNothing);
      expect(find.textContaining('pull-out mesh'), findsNothing);
      expect(find.byKey(const Key('visual-guide-show-lint-filter')), findsNothing);

      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-doesnt-match')),
      );
      await completeRepairReadinessIfPresent(tester);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.textContaining('Open only the user-accessible filter'), findsNothing);
      expect(find.byKey(const Key('visual-guide-show-lint-filter')), findsNothing);

      final session = deps.repairSessionRepository.listAllSessions().single;
      final evidence =
          deps.repairSessionRepository.evidenceForSession(session.id);
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'washer-door-click',
        ),
        'Yes',
      );
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'washer-drain-filter-access',
        ),
        'Yes',
      );
    },
  );

  testWidgets(
    'dishwasher won\'t-drain path shows filter, door, hose inspect before teardown',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 14, 10));
      await openDishwasherSession(tester, deps, 'Dishwasher Drain Inspect');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-won-t-drain')),
      );
      await selectFailureMode(tester, 'kinked-or-clogged-dishwasher-drain');
      await advanceClosePathFromConclusionIfPresent(tester);

      expect(
        find.byKey(const Key('inspect-step-card-inspect-dishwasher-filter')),
        findsOneWidget,
      );
      expect(find.textContaining('sump'), findsWidgets);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
      expect(find.textContaining('Straighten kinks'), findsNothing);
      expect(find.byKey(const Key('inspect-step-card-inspect-lint-filter')), findsNothing);
      expect(find.textContaining('pull-out mesh'), findsNothing);
      expect(find.byKey(const Key('visual-guide-show-lint-filter')), findsNothing);

      await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
      expect(
        find.byKey(const Key('inspect-step-card-inspect-dishwasher-door-click')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);

      await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
      expect(
        find.byKey(const Key('inspect-step-card-inspect-dishwasher-drain-hose')),
        findsOneWidget,
      );
      expect(find.textContaining('high loop'), findsWidgets);
      expect(find.textContaining('knockout'), findsWidgets);
      expect(find.textContaining('Observation only'), findsWidgets);
      expect(find.textContaining('Straighten kinks'), findsNothing);

      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-doesnt-match')),
      );
      await completeRepairReadinessIfPresent(tester);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.byKey(const Key('visual-guide-show-lint-filter')), findsNothing);

      final session = deps.repairSessionRepository.listAllSessions().single;
      final evidence =
          deps.repairSessionRepository.evidenceForSession(session.id);
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'dishwasher-filter-debris',
        ),
        'No',
      );
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'dishwasher-door-click',
        ),
        'Yes',
      );
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'dishwasher-drain-hose',
        ),
        'Yes',
      );
    },
  );

  testWidgets(
    'dishwasher fill path shows supply inspect before moving the unit',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 9));
      await openDishwasherSession(tester, deps, 'Dishwasher Fill Inspect');
      await tapVisible(tester, find.byKey(const Key('answer-choice-won-t-fill')));
      await selectFailureMode(tester, 'closed-dishwasher-supply-or-air-gap');
      await advanceClosePathFromConclusionIfPresent(tester);

      expect(
        find.byKey(const Key('inspect-step-card-inspect-dishwasher-supply')),
        findsOneWidget,
      );
      expect(find.textContaining('supply tap'), findsWidgets);
      expect(find.byKey(const Key('inspect-step-card-inspect-lint-filter')), findsNothing);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);

      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-doesnt-match')),
      );
      await completeRepairReadinessIfPresent(tester);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
      expect(find.textContaining('Look under the sink'), findsWidgets);
      expect(find.textContaining('Open the supply tap'), findsNothing);
    },
  );

  testWidgets(
    'dishwasher poor-clean path shows filter then spray inspect before rinse',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 22, 9, 1));
      await openDishwasherSession(tester, deps, 'Dishwasher Spray Inspect');
      await tapVisible(tester, find.byKey(const Key('answer-choice-poor-clean')));
      await selectFailureMode(tester, 'clogged-dishwasher-spray-arms');
      await advanceClosePathFromConclusionIfPresent(tester);

      expect(
        find.byKey(const Key('inspect-step-card-inspect-dishwasher-filter')),
        findsOneWidget,
      );
      expect(find.textContaining('sump'), findsWidgets);
      expect(find.textContaining('Clear visible spray-arm'), findsNothing);

      await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
      expect(
        find.byKey(const Key('inspect-step-card-inspect-dishwasher-spray')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('inspect-step-card-inspect-dishwasher-drain-hose')),
        findsNothing,
      );
      expect(find.byKey(const Key('inspect-step-card-inspect-lint-filter')), findsNothing);

      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-doesnt-match')),
      );
      await completeRepairReadinessIfPresent(tester);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    },
  );

  testWidgets(
    'washer leak path shows standpipe then hose-run inspect before seating',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 15));
      await openWasherSession(tester, deps, 'Washer Standpipe Inspect');
      await tapVisible(tester, find.byKey(const Key('answer-choice-leaks')));
      await selectFailureMode(tester, 'washer-drain-hose-not-seated');
      await advanceClosePathFromConclusionIfPresent(tester);

      expect(
        find.byKey(const Key('inspect-step-card-inspect-washer-standpipe')),
        findsOneWidget,
      );
      expect(find.textContaining('new-install'), findsWidgets);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
      expect(find.textContaining('Seat the drain hose'), findsNothing);

      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-doesnt-match')),
      );
      expect(
        find.byKey(const Key('inspect-step-card-inspect-washer-drain-hose-config')),
        findsOneWidget,
      );
      expect(find.textContaining('stuffed deep'), findsWidgets);
      expect(find.textContaining('Seat the drain hose'), findsNothing);

      await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);

      final session = deps.repairSessionRepository.listAllSessions().single;
      final evidence =
          deps.repairSessionRepository.evidenceForSession(session.id);
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'washer-standpipe-hose',
        ),
        'Yes',
      );
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'washer-drain-hose-look',
        ),
        'No',
      );
    },
  );

  testWidgets(
    'fridge coils path shows temps, gasket, vents, coils inspect before pull-out',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 17));
      await openFridgeSession(tester, deps, 'Fridge Coils Inspect');
      await tapVisible(
        tester,
        find.byKey(const Key('answer-choice-not-cooling')),
      );
      await selectFailureMode(tester, 'blocked-fridge-coils-or-airflow');
      await advanceClosePathFromConclusionIfPresent(tester);

      expect(
        find.byKey(const Key('inspect-step-card-inspect-fridge-temps')),
        findsOneWidget,
      );
      expect(find.textContaining('digital setpoints'), findsWidgets);
      expect(find.byKey(const Key('safe-guidance-card')), findsNothing);
      expect(find.textContaining('Vacuum dust'), findsNothing);

      await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
      expect(
        find.byKey(const Key('inspect-step-card-inspect-fridge-door-seal')),
        findsOneWidget,
      );
      await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
      expect(
        find.byKey(const Key('inspect-step-card-inspect-fridge-vents')),
        findsOneWidget,
      );
      await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
      expect(
        find.byKey(const Key('inspect-step-card-inspect-fridge-coils')),
        findsOneWidget,
      );
      expect(find.textContaining('toe-kick'), findsWidgets);
      expect(find.textContaining('Do not vacuum yet'), findsWidgets);

      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-doesnt-match')),
      );
      await completeRepairReadinessIfPresent(tester);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);

      final session = deps.repairSessionRepository.listAllSessions().single;
      final evidence =
          deps.repairSessionRepository.evidenceForSession(session.id);
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'fridge-temps-or-settings',
        ),
        'Yes — mid-range',
      );
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'fridge-door-seal',
        ),
        'Yes',
      );
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'fridge-internal-vents',
        ),
        'No',
      );
      expect(
        answerForTemplate(
          recordedEvidence: evidence,
          templateId: 'fridge-coils-or-space',
        ),
        'Yes',
      );
    },
  );

  testWidgets(
    'denied camera keeps inspect text, copy, and chips through filter and hose',
    (tester) async {
      final deps = AppDependencies(clock: () => DateTime.utc(2026, 8, 19, 16));
      deps.simulateMediaDenied = true;
      await openDryerSession(tester, deps, 'Inspect Camera Denied');
      await selectFailureMode(tester, 'thermal-fuse-open');
      await advanceClosePathFromConclusionIfPresent(tester);

      expect(
        find.byKey(const Key('inspect-step-card-inspect-lint-filter')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('inspect-look-for')), findsOneWidget);
      expect(find.byKey(const Key('inspect-safety-preamble')), findsOneWidget);
      expect(find.byKey(const Key('inspect-diagram')), findsNothing);
      expect(find.byKey(const Key('inspect-frame-hint')), findsNothing);
      expect(find.byKey(const Key('inspect-location-icon')), findsNothing);
      expect(
        find.text(UserFacingCopy.inspectTypicalLocationCaption),
        findsNothing,
      );

      expect(find.byKey(const Key('inspect-chip-matches-ok')), findsOneWidget);
      expect(find.byKey(const Key('visual-guide-target-box')), findsNothing);
      expect(find.byKey(const Key('inspect-use-camera')), findsNothing);
      expect(find.byKey(const Key('inspect-camera-on-phone')), findsNothing);

      await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
      expect(
        find.byKey(const Key('inspect-step-card-inspect-vent-hood')),
        findsOneWidget,
      );
      await tapVisible(tester, find.byKey(const Key('inspect-chip-matches-ok')));
      expect(
        find.byKey(const Key('inspect-step-card-inspect-vent-hose')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('inspect-look-for')), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const Key('inspect-chip-doesnt-match')),
      );
      await completeRepairReadinessIfPresent(tester);
      expect(find.byKey(const Key('safe-guidance-card')), findsOneWidget);
    },
  );

  testWidgets(
    'inspect camera tab keeps instructions and never shows a found-part box',
    (tester) async {
      var answered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InspectStepCard(
                step: dryerLintFilterInspectStep,
                offerLiveCamera: true,
                onChip: (_) => answered = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('inspect-look-for')), findsOneWidget);
      expect(find.byKey(const Key('inspect-safety-preamble')), findsOneWidget);
      expect(find.byKey(const Key('inspect-diagram')), findsNothing);
      expect(find.byKey(const Key('inspect-frame-hint')), findsNothing);
      expect(find.byKey(const Key('inspect-location-icon')), findsNothing);
      expect(
        find.text(UserFacingCopy.inspectTypicalLocationCaption),
        findsNothing,
      );
      expect(find.byKey(const Key('inspect-use-camera')), findsOneWidget);
      expect(find.byKey(const Key('visual-guide-target-box')), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('inspect-use-camera')));
      await tester.tap(find.byKey(const Key('inspect-use-camera')));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inspect-look-for')), findsOneWidget);
      expect(find.byKey(const Key('inspect-diagram')), findsNothing);
      expect(find.byKey(const Key('inspect-frame-hint')), findsNothing);
      expect(find.byKey(const Key('inspect-chip-matches-ok')), findsOneWidget);
      expect(find.byKey(const Key('visual-guide-target-box')), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('inspect-chip-matches-ok')));
      await tester.tap(find.byKey(const Key('inspect-chip-matches-ok')));
      await tester.pumpAndSettle();
      expect(answered, isTrue);
    },
  );

  testWidgets('inspect without offerLiveCamera has no camera chrome', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InspectStepCard(
              step: dryerLintFilterInspectStep,
              onChip: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inspect-look-for')), findsOneWidget);
    expect(find.byKey(const Key('inspect-use-camera')), findsNothing);
    expect(find.byKey(const Key('inspect-camera-on-phone')), findsNothing);
    expect(find.byKey(const Key('inspect-chip-matches-ok')), findsOneWidget);
  });
}
