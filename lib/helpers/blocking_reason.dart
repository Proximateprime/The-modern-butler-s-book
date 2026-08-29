import 'close_path_phase.dart';
import 'repair_readiness.dart';

/// One calm sentence when a close-path gate blocks the next repair step.
///
/// Presentation only. Does not change ranking, safety evaluation, or gates.

const String blockingReasonSafetyLine =
    'This step is blocked for safety—call a pro.';

const String blockingReasonToolsUnmarkedLine =
    'Mark I have or I don’t for each tool to continue.';

const String blockingReasonEasyLintFilterLine =
    'Next: check the lint filter before opening the cabinet.';

const String blockingReasonEasyOutsideVentLine =
    'Next: check outside vent before opening the cabinet.';

const String blockingReasonEasyVentHoseLine =
    'Next: check the visible vent hose before opening the cabinet.';

const String blockingReasonWasherDoorLine =
    'Next: check that the door clicks before opening the filter.';

const String blockingReasonWasherFilterLookLine =
    'Next: look for the drain filter before opening it.';

const String blockingReasonWasherTapsLine =
    'Next: check the taps before moving the washer.';

const String blockingReasonWasherHoseLookLine =
    'Next: look at the drain hose before pulling the washer out.';

const String blockingReasonDishwasherFilterLookLine =
    'Next: look at the tub filter before removing it.';

const String blockingReasonDishwasherHoseLookLine =
    'Next: look at the drain hose or air gap before pulling the unit out.';

const String blockingReasonDishwasherDoorLine =
    'Next: check that the door clicks before other repair steps.';

const String blockingReasonFridgeEasyLine =
    'Next: check temps, the door seal, or vents before pulling the fridge out.';

const String blockingReasonInspectIncompleteLine =
    'Finish this look before opening a panel or pulling the appliance out.';

String blockingReasonMissingTools(List<RepairReadinessItem> missing) {
  if (missing.isEmpty) {
    return blockingReasonToolsUnmarkedLine;
  }
  final needs = missing.map(_toolNeedPhrase).join(' and ');
  return 'You need $needs for the next steps.';
}

String _toolNeedPhrase(RepairReadinessItem item) {
  final name = readinessDisplayLabel(item).toLowerCase();
  final first = name.isEmpty ? '' : name[0];
  final article = 'aeiou'.contains(first) ? 'an' : 'a';
  return '$article $name';
}

String blockingReasonEasyAirflowLine(String? currentStep) {
  final step = currentStep ?? '';
  if (_isOutsideVentEasyStep(step)) {
    return blockingReasonEasyOutsideVentLine;
  }
  if (_isVentHoseEasyStep(step)) {
    return blockingReasonEasyVentHoseLine;
  }
  return blockingReasonEasyLintFilterLine;
}

String blockingReasonWasherEasyLine(String? currentStep) {
  final step = (currentStep ?? '').toLowerCase();
  if (step.contains('accessible drain filter')) {
    return blockingReasonWasherFilterLookLine;
  }
  if (step.contains('tap') || step.contains('inlet')) {
    return blockingReasonWasherTapsLine;
  }
  if (step.contains('drain hose') || step.contains('standpipe')) {
    return blockingReasonWasherHoseLookLine;
  }
  return blockingReasonWasherDoorLine;
}

String blockingReasonDishwasherEasyLine(String? currentStep) {
  final step = (currentStep ?? '').toLowerCase();
  if (step.contains('filter')) {
    return blockingReasonDishwasherFilterLookLine;
  }
  if (step.contains('hose') || step.contains('air gap') || step.contains('air-gap')) {
    return blockingReasonDishwasherHoseLookLine;
  }
  return blockingReasonDishwasherDoorLine;
}

bool _isOutsideVentEasyStep(String step) {
  final lower = step.toLowerCase();
  return lower.contains('vent hood') ||
      lower.contains('outside vent') ||
      (lower.contains('exterior') && lower.contains('airflow')) ||
      (lower.contains('exterior') && lower.contains('vent'));
}

bool _isVentHoseEasyStep(String step) {
  final lower = step.toLowerCase();
  return lower.contains('vent hose') ||
      ((lower.contains('crushed') || lower.contains('kink')) &&
          (lower.contains('hose') || lower.contains('vent')));
}

/// Null when nothing is gating the current close-path screen.
String? blockingReasonLine({
  required bool safetyStop,
  required ClosePathPhase phase,
  required List<RepairReadinessItem> missingRequiredTools,
  required bool toolsChecklistComplete,
  required bool continueWithCaution,
  required bool easyAirflowGateActive,
  required bool easyAirflowSatisfied,
  required bool washerEasyGateActive,
  required bool washerEasySatisfied,
  bool dishwasherEasyGateActive = false,
  bool dishwasherEasySatisfied = false,
  bool fridgeEasyGateActive = false,
  bool fridgeEasySatisfied = false,
  bool hasIncompleteInspect = false,
  required String? currentGuidanceStep,
}) {
  if (safetyStop) {
    return blockingReasonSafetyLine;
  }
  if (hasIncompleteInspect &&
      (phase == ClosePathPhase.inspect || phase == ClosePathPhase.guidance)) {
    return blockingReasonInspectIncompleteLine;
  }
  if (phase == ClosePathPhase.tools) {
    if (missingRequiredTools.isNotEmpty) {
      return blockingReasonMissingTools(missingRequiredTools);
    }
    if (!toolsChecklistComplete) {
      return blockingReasonToolsUnmarkedLine;
    }
    return null;
  }
  if (phase == ClosePathPhase.guidance) {
    if (easyAirflowGateActive && !easyAirflowSatisfied) {
      return blockingReasonEasyAirflowLine(currentGuidanceStep);
    }
    if (washerEasyGateActive && !washerEasySatisfied) {
      return blockingReasonWasherEasyLine(currentGuidanceStep);
    }
    if (dishwasherEasyGateActive && !dishwasherEasySatisfied) {
      return blockingReasonDishwasherEasyLine(currentGuidanceStep);
    }
    if (fridgeEasyGateActive && !fridgeEasySatisfied) {
      return blockingReasonFridgeEasyLine;
    }
    if (missingRequiredTools.isNotEmpty && !continueWithCaution) {
      return blockingReasonMissingTools(missingRequiredTools);
    }
    if (missingRequiredTools.isNotEmpty && continueWithCaution) {
      final gatedInvasive =
          currentGuidanceStep != null &&
          isInvasiveGuidanceStep(currentGuidanceStep);
      if (gatedInvasive) {
        return blockingReasonMissingTools(missingRequiredTools);
      }
    }
    return null;
  }
  return null;
}
