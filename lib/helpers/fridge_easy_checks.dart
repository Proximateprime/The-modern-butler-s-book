import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import '../knowledge_factory/fridge_mvp_v01.dart';
import 'close_path_phase.dart';
import 'dryer_close_path.dart';
import 'evidence_prompt_match.dart';

/// Fridge observational looks (temps, door seal, vents) before coil pull-out.
///
/// Presentation only — does not change ranking.
const List<String> fridgeEasyCheckTemplateOrder = [
  'fridge-temps-or-settings',
  'fridge-door-seal',
  'fridge-internal-vents',
];

const Set<String> fridgeEasyCheckTemplateIds = {
  'fridge-temps-or-settings',
  'fridge-door-seal',
  'fridge-internal-vents',
  'fridge-coils-or-space',
  'fridge-drain-or-pan',
  'fridge-ice-maker-supply',
  'fridge-ice-bin-jam',
  'fridge-level-or-rattle',
  'fridge-power-or-plug',
};

const Set<String> fridgeEasyChecksBeforeRepairModeIds = {
  fridgeBlockedCoilsId,
  fridgeBlockedInternalVentsId,
  fridgeDoorGasketId,
  fridgeTempControlsId,
  fridgeCloggedDefrostDrainId,
  fridgeIceMakerSupplyId,
  fridgeIceBinJamId,
  fridgeUnlevelVibrationId,
  fridgeNoPowerId,
};

bool isFridgeEasyCheckTemplateId(String? templateId) {
  return templateId != null && fridgeEasyCheckTemplateIds.contains(templateId);
}

bool isFridgeEasyCheckStep(String step) {
  if (isFridgeRepairGuidanceStep(step)) {
    return false;
  }
  final lower = step.toLowerCase();
  if (lower.contains('look') &&
      (lower.contains('temp') ||
          lower.contains('control') ||
          lower.contains('gasket') ||
          lower.contains('seal') ||
          lower.contains('vent') ||
          lower.contains('plug') ||
          lower.contains('bin') ||
          lower.contains('rock'))) {
    return true;
  }
  if (lower.contains('door') &&
      (lower.contains('close') || lower.contains('gasket') || lower.contains('seal'))) {
    return true;
  }
  if (lower.contains('confirm the ice maker switch')) {
    return true;
  }
  return false;
}

bool isFridgeRepairGuidanceStep(String step) {
  final lower = step.toLowerCase();
  if (lower.contains('vacuum') && lower.contains('coil')) {
    return true;
  }
  if (lower.contains('empty a slide-out drip pan') ||
      lower.contains('clear only a user-accessible freezer drain')) {
    return true;
  }
  if (lower.contains('unplug') &&
      (lower.contains('pulling') ||
          lower.contains('before pulling') ||
          lower.contains('roll or lift') ||
          lower.contains('moving it') ||
          lower.contains('touching the drip'))) {
    return true;
  }
  return false;
}

bool closePathNeedsFridgeEasyChecksFirst(FailureModeClosePath path) {
  return fridgeEasyChecksBeforeRepairModeIds.contains(path.failureModeId);
}

List<String> fridgeEasyCheckOrderForEvidence(List<Evidence> recordedEvidence) {
  final complaint = _fridgeComplaintAnswer(recordedEvidence);
  if (complaint.contains('warm') && complaint.contains('freezer')) {
    return const ['fridge-door-seal', 'fridge-internal-vents'];
  }
  if (complaint.contains('not cooling')) {
    return const [
      'fridge-temps-or-settings',
      'fridge-door-seal',
      'fridge-internal-vents',
      'fridge-coils-or-space',
    ];
  }
  if (complaint.contains('too cold')) {
    return const ['fridge-temps-or-settings'];
  }
  if (complaint.contains('leak')) {
    return const ['fridge-drain-or-pan'];
  }
  if (complaint.contains('ice')) {
    return const ['fridge-ice-maker-supply', 'fridge-ice-bin-jam'];
  }
  if (complaint.contains('noisy')) {
    return const ['fridge-level-or-rattle'];
  }
  if (complaint.contains('door')) {
    return const ['fridge-door-seal'];
  }
  if (complaint.contains('run')) {
    return const ['fridge-power-or-plug'];
  }
  return fridgeEasyCheckTemplateOrder;
}

EvidenceTemplate? nextFridgeEasyCheckTemplate({
  required List<EvidenceTemplate> remaining,
  List<Evidence> recordedEvidence = const [],
}) {
  for (final id in fridgeEasyCheckOrderForEvidence(recordedEvidence)) {
    for (final template in remaining) {
      if (template.id == id) {
        return template;
      }
    }
  }
  return null;
}

bool shouldPrioritizeFridgeEasyChecks({
  required List<Evidence> recordedEvidence,
}) {
  for (final item in recordedEvidence) {
    if (item.templateId == fridgeComplaintTemplateId) {
      return true;
    }
  }
  return false;
}

String _fridgeComplaintAnswer(List<Evidence> recordedEvidence) {
  for (final item in recordedEvidence) {
    if (item.templateId != fridgeComplaintTemplateId) {
      continue;
    }
    return normalizeObservationAnswer(item.answer)?.toLowerCase() ?? '';
  }
  return '';
}

Set<String> _easyTemplateIdsImpliedBySteps(List<String> steps) {
  final ids = <String>{};
  for (final step in steps) {
    if (!isFridgeEasyCheckStep(step)) {
      continue;
    }
    final lower = step.toLowerCase();
    if (lower.contains('temp') || lower.contains('control') || lower.contains('setpoint')) {
      ids.add('fridge-temps-or-settings');
    }
    if (lower.contains('gasket') ||
        (lower.contains('door') && lower.contains('close'))) {
      ids.add('fridge-door-seal');
    }
    if (lower.contains('vent')) {
      ids.add('fridge-internal-vents');
    }
    if (lower.contains('plug') || lower.contains('breaker')) {
      ids.add('fridge-power-or-plug');
    }
    if (lower.contains('ice maker switch')) {
      ids.add('fridge-ice-maker-supply');
    }
    if (lower.contains('bin')) {
      ids.add('fridge-ice-bin-jam');
    }
    if (lower.contains('rock')) {
      ids.add('fridge-level-or-rattle');
    }
  }
  return ids;
}

bool fridgeEasyChecksSatisfied({
  required List<Evidence> recordedEvidence,
  required List<String> steps,
  required Iterable<String> completedIds,
}) {
  final recorded = recordedEvidence
      .map((item) => item.templateId)
      .whereType<String>()
      .toSet();
  final needed = _easyTemplateIdsImpliedBySteps(steps);
  if (needed.isNotEmpty && needed.every(recorded.contains)) {
    return true;
  }
  final done = completedIds.toSet();
  final easySteps = [
    for (var i = 0; i < steps.length; i++)
      if (isFridgeEasyCheckStep(steps[i])) i,
  ];
  if (easySteps.isEmpty) {
    return true;
  }
  return easySteps.every(
    (index) => done.contains(guidanceStepId(index, steps[index])),
  );
}

List<String> orderFridgeEasyChecksFirst(List<String> steps) {
  final easy = <String>[
    for (final step in steps)
      if (isFridgeEasyCheckStep(step)) step,
  ];
  final rest = [
    for (final step in steps)
      if (!isFridgeEasyCheckStep(step)) step,
  ];
  return [...easy, ...rest];
}

List<String> guidanceStepsForFridgeEasyGate({
  required List<String> steps,
  required bool easyChecksSatisfied,
}) {
  if (easyChecksSatisfied) {
    return List<String>.from(steps);
  }
  return [
    for (final step in steps)
      if (!isFridgeRepairGuidanceStep(step)) step,
  ];
}
