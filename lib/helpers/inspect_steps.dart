import '../knowledge_factory/dishwasher_inspect_steps.dart';
import '../knowledge_factory/dryer_inspect_steps.dart';
import '../knowledge_factory/fridge_inspect_steps.dart';
import '../knowledge_factory/washer_inspect_steps.dart';
import '../models/evidence.dart';
import '../models/inspect_step.dart';
import 'close_path_phase.dart';
import 'dryer_close_path.dart';
import 'easy_check_already_checked.dart';
import 'evidence_prompt_match.dart';
import 'location_visual_aids.dart';
import 'visual_guide.dart';

export '../models/inspect_step.dart';

/// Ordered inspect steps for a close path: close-path list, else package data.
List<InspectStep> inspectStepsForClosePath({
  required FailureModeClosePath closePath,
  List<InspectStep> packageSteps = const [],
  String? applianceCategory,
}) {
  if (closePath.inspectSteps.isNotEmpty) {
    return inspectStepsForApplianceFamily(
      closePath.inspectSteps,
      applianceCategory,
    );
  }
  return inspectStepsForFailureMode(
    failureModeId: closePath.failureModeId,
    packageSteps: packageSteps,
    applianceCategory: applianceCategory,
  );
}

List<InspectStep> inspectStepsForApplianceFamily(
  List<InspectStep> steps,
  String? applianceCategory,
) {
  final family = (applianceCategory ?? '').trim();
  if (family.isEmpty) {
    return steps;
  }
  return [
    for (final step in steps)
      if (step.appliesTo == family) step,
  ];
}

List<InspectStep> inspectStepsForFailureMode({
  required String failureModeId,
  List<InspectStep> packageSteps = const [],
  String? applianceCategory,
}) {
  final fromPackage = [
    for (final step in packageSteps)
      if (step.failureModeIds.contains(failureModeId)) step,
  ];
  final matched = fromPackage.isNotEmpty
      ? fromPackage
      : [
          for (final step in [
            ...dryerPackageInspectSteps,
            ...washerPackageInspectSteps,
            ...dishwasherPackageInspectSteps,
            ...fridgePackageInspectSteps,
          ])
            if (step.failureModeIds.contains(failureModeId)) step,
        ];
  return inspectStepsForApplianceFamily(matched, applianceCategory);
}

/// Trusted curated raster only. Parked unless [locationVisualAidsEnabled].
///
/// Generated schematics (`diagram:` ids, dryer SVG placeholders) never count.
bool inspectHasCuratedImage(String diagramAsset) {
  if (!locationVisualAidsEnabled) {
    return false;
  }
  final raw = diagramAsset.trim();
  if (raw.isEmpty || raw.startsWith('diagram:')) {
    return false;
  }
  if (inspectUsesDryerSchematic(raw) || raw.toLowerCase().endsWith('.svg')) {
    return false;
  }
  return raw.startsWith('assets/');
}

/// Packaged dryer front/rear schematic (not a photo, not washer/DW art).
bool inspectUsesDryerSchematic(String diagramAsset) {
  final raw = diagramAsset.trim();
  return raw == dryerFrontInspectAsset || raw == dryerRearInspectAsset;
}

/// Inspect overlay that writes the same template as this interview prompt.
InspectStep? inspectStepForEvidenceTemplate({
  required String templateId,
  String? applianceCategory,
  List<InspectStep> packageSteps = const [],
}) {
  final pool = packageSteps.isNotEmpty
      ? packageSteps
      : [
          ...dryerPackageInspectSteps,
          ...washerPackageInspectSteps,
          ...dishwasherPackageInspectSteps,
          ...fridgePackageInspectSteps,
        ];
  final family = inspectStepsForApplianceFamily(pool, applianceCategory);
  for (final step in family) {
    if (step.evidenceTemplateId == templateId ||
        step.relatedEasyCheckTemplateId == templateId) {
      return step;
    }
  }
  return null;
}

/// First inspect step whose evidence template is not yet recorded.
InspectStep? firstIncompleteInspectStep({
  required List<InspectStep> steps,
  required List<Evidence> recordedEvidence,
}) {
  for (final step in steps) {
    if (!isTemplateRecordedById(
      templateId: step.evidenceTemplateId,
      recordedEvidence: recordedEvidence,
    )) {
      return step;
    }
  }
  return null;
}

bool hasIncompleteInspectStep({
  required List<InspectStep> steps,
  required List<Evidence> recordedEvidence,
}) {
  return firstIncompleteInspectStep(
        steps: steps,
        recordedEvidence: recordedEvidence,
      ) !=
      null;
}

/// 1-based index of the current incomplete inspect step and chain length.
({int current, int total}) inspectProgress({
  required List<InspectStep> steps,
  required List<Evidence> recordedEvidence,
}) {
  final total = steps.length;
  if (total == 0) {
    return (current: 0, total: 0);
  }
  final incomplete = firstIncompleteInspectStep(
    steps: steps,
    recordedEvidence: recordedEvidence,
  );
  if (incomplete == null) {
    return (current: total, total: total);
  }
  final index = steps.indexWhere((step) => step.id == incomplete.id);
  return (current: index < 0 ? 1 : index + 1, total: total);
}

String inspectProgressLabel({required int current, required int total}) {
  return 'Inspect $current of $total';
}

/// Keep the user on inspect if they would skip into guidance with work left.
ClosePathPhase closePathPhaseHonoringInspect({
  required ClosePathPhase requested,
  required bool hasIncompleteInspect,
}) {
  if (requested == ClosePathPhase.guidance && hasIncompleteInspect) {
    return ClosePathPhase.inspect;
  }
  return requested;
}

/// Chip order shown on one inspect step.
List<String> inspectStepChipLabels(InspectStep step) {
  return [
    inspectMatchesOkChip,
    inspectDoesntMatchChip,
    inspectCantSeeChip,
    if (isEasyCheckObservationTemplateId(step.evidenceTemplateId) ||
        step.evidenceAnswerByChip.containsKey(alreadyCheckedEasyCheckAnswer))
      alreadyCheckedEasyCheckAnswer,
  ];
}

String inspectChipKeySuffix(String chip) {
  if (chip == inspectMatchesOkChip) {
    return 'matches-ok';
  }
  if (chip == inspectDoesntMatchChip) {
    return 'doesnt-match';
  }
  if (chip == inspectCantSeeChip) {
    return 'cant-see';
  }
  if (chip == alreadyCheckedEasyCheckAnswer) {
    return 'already-checked';
  }
  return answerChoiceKeySuffix(chip);
}

VisualGuideAnchor inspectDiagramAnchor(InspectStep step) {
  VisualGuideAnchor mapped;
  if (step.id == dryerLintFilterInspectStep.id) {
    mapped = lintFilterGuide;
  } else if (step.id == dryerVentHoodInspectStep.id) {
    mapped = ventHoodGuide;
  } else if (step.id == dryerVentHoseInspectStep.id) {
    mapped = dryerVentHoseGuide;
  } else if (step.id == washerDoorClickInspectStep.id) {
    mapped = washerDoorLatchGuide;
  } else if (step.id == washerDrainFilterInspectStep.id) {
    mapped = drainFilterGuide;
  } else if (step.id == washerStandpipeInspectStep.id ||
      step.id == washerDrainHoseConfigInspectStep.id) {
    mapped = washerDrainHoseGuide;
  } else if (step.id == dishwasherFilterInspectStep.id) {
    mapped = dishwasherTubFilterGuide;
  } else if (step.id == dishwasherDoorClickInspectStep.id) {
    mapped = dishwasherDoorLatchGuide;
  } else if (step.id == dishwasherDrainHoseInspectStep.id) {
    mapped = dishwasherDrainHoseGuide;
  } else if (step.id == dishwasherSupplyInspectStep.id) {
    mapped = dishwasherSupplyGuide;
  } else if (step.id == dishwasherSprayInspectStep.id) {
    mapped = dishwasherSprayArmGuide;
  } else if (step.id == dishwasherLeakInspectStep.id) {
    mapped = dishwasherDoorLatchGuide;
  } else if (step.id == fridgeTempsInspectStep.id ||
      step.id == fridgeDoorSealInspectStep.id) {
    mapped = fridgeDoorGasketGuide;
  } else if (step.id == fridgeVentsInspectStep.id) {
    mapped = fridgeInternalVentGuide;
  } else if (step.id == fridgeCoilsInspectStep.id) {
    mapped = fridgeCoilsGuide;
  } else {
    mapped = VisualGuideAnchor(
      targetId: step.id,
      label: step.title,
      imageAsset: step.diagramAsset,
      applianceCategory: step.appliesTo,
      typicalDiagramOnly: true,
      whatYouShouldSee: step.lookFor,
    );
  }
  if (visualGuideAnchorFitsCategory(mapped, step.appliesTo)) {
    return mapped;
  }
  return VisualGuideAnchor(
    targetId: step.id,
    label: step.title,
    imageAsset: step.diagramAsset,
    applianceCategory: step.appliesTo,
    typicalDiagramOnly: true,
    whatYouShouldSee: step.lookFor,
  );
}
