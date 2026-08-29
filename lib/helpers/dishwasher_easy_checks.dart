import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import '../knowledge_factory/dishwasher_mvp_v01.dart';
import 'close_path_phase.dart';
import 'dryer_close_path.dart';
import 'evidence_prompt_match.dart';

/// Dishwasher beginner door / filter / hose / supply / spray looks.
///
/// Presentation only — does not change ranking.
const List<String> dishwasherEasyCheckTemplateOrder = [
  'dishwasher-filter-debris',
  'dishwasher-door-click',
  'dishwasher-drain-hose',
];

const Set<String> dishwasherEasyCheckTemplateIds = {
  'dishwasher-door-click',
  'dishwasher-filter-debris',
  'dishwasher-drain-hose',
  'dishwasher-supply-open',
  'dishwasher-spray-holes',
  'dishwasher-door-seal-leak',
};

const Set<String> dishwasherEasyChecksBeforeRepairModeIds = {
  dishwasherCloggedFilterId,
  dishwasherDrainPathId,
  dishwasherClosedSupplyId,
  dishwasherCloggedSprayArmsId,
  dishwasherDoorSealLeakId,
  dishwasherDoorNotLatchedId,
};

const String dishwasherEasyDoorGuidanceStep =
    'Check that the dishwasher door closes firmly until you feel or hear a '
    'click. Do not bypass the door switch.';

const String dishwasherEasyFilterLookGuidanceStep =
    'Look at the accessible tub filter under the lower rack. Do not open a '
    'sealed pump.';

bool isDishwasherEasyCheckTemplateId(String? templateId) {
  return templateId != null &&
      dishwasherEasyCheckTemplateIds.contains(templateId);
}

/// Look-only door, filter, hose, supply, or spray checks.
bool isDishwasherEasyCheckStep(String step) {
  if (isDishwasherRepairGuidanceStep(step)) {
    return false;
  }
  final lower = step.toLowerCase();
  if (lower.contains('bypass')) {
    return false;
  }
  if (lower.contains('door') &&
      (lower.contains('click') ||
          lower.contains('latch') ||
          lower.contains('seal'))) {
    return true;
  }
  if (lower.contains('look') &&
      (lower.contains('filter') ||
          lower.contains('hose') ||
          lower.contains('air-gap') ||
          lower.contains('air gap') ||
          lower.contains('supply') ||
          lower.contains('spray'))) {
    return true;
  }
  return false;
}

bool isDishwasherRepairGuidanceStep(String step) {
  final lower = step.toLowerCase();
  if (lower.contains('remove and rinse') ||
      lower.contains('rinse the accessible filter') ||
      lower.contains('clear visible spray-arm') ||
      lower.contains('lift the air-gap cap') ||
      lower.contains('hand-check a visible hose')) {
    return true;
  }
  if (lower.contains('unplug') &&
      (lower.contains('reaching') ||
          lower.contains('pulling') ||
          lower.contains('lifting') ||
          lower.contains('moving'))) {
    return true;
  }
  return false;
}

bool closePathNeedsDishwasherEasyChecksFirst(FailureModeClosePath path) {
  return dishwasherEasyChecksBeforeRepairModeIds.contains(path.failureModeId);
}

List<String> dishwasherEasyCheckOrderForEvidence(
  List<Evidence> recordedEvidence,
) {
  final complaint = _dishwasherComplaintAnswer(recordedEvidence);
  if (complaint.contains('standing') || complaint.contains('drain')) {
    return const [
      'dishwasher-filter-debris',
      'dishwasher-door-click',
      'dishwasher-drain-hose',
    ];
  }
  if (complaint.contains('fill')) {
    return const ['dishwasher-supply-open'];
  }
  if (complaint.contains('poor') || complaint.contains('clean')) {
    return const [
      'dishwasher-filter-debris',
      'dishwasher-spray-holes',
    ];
  }
  if (complaint.contains('leak')) {
    return const ['dishwasher-door-seal-leak'];
  }
  if (complaint.contains('start') || complaint.contains('door')) {
    return const ['dishwasher-door-click'];
  }
  return dishwasherEasyCheckTemplateOrder;
}

EvidenceTemplate? nextDishwasherEasyCheckTemplate({
  required List<EvidenceTemplate> remaining,
  List<Evidence> recordedEvidence = const [],
}) {
  for (final id in dishwasherEasyCheckOrderForEvidence(recordedEvidence)) {
    for (final template in remaining) {
      if (template.id == id) {
        return template;
      }
    }
  }
  return null;
}

bool shouldPrioritizeDishwasherEasyChecks({
  required List<Evidence> recordedEvidence,
}) {
  for (final item in recordedEvidence) {
    if (item.templateId == dishwasherComplaintTemplateId) {
      return true;
    }
  }
  return false;
}

String _dishwasherComplaintAnswer(List<Evidence> recordedEvidence) {
  for (final item in recordedEvidence) {
    if (item.templateId != dishwasherComplaintTemplateId) {
      continue;
    }
    return normalizeObservationAnswer(item.answer)?.toLowerCase() ?? '';
  }
  return '';
}

Set<String> _easyTemplateIdsImpliedBySteps(List<String> steps) {
  final ids = <String>{};
  for (final step in steps) {
    if (!isDishwasherEasyCheckStep(step)) {
      continue;
    }
    final lower = step.toLowerCase();
    if (lower.contains('door') &&
        (lower.contains('click') || lower.contains('latch'))) {
      ids.add('dishwasher-door-click');
    }
    if (lower.contains('filter')) {
      ids.add('dishwasher-filter-debris');
    }
    if (lower.contains('hose') || lower.contains('air gap') || lower.contains('air-gap')) {
      ids.add('dishwasher-drain-hose');
    }
    if (lower.contains('supply')) {
      ids.add('dishwasher-supply-open');
    }
    if (lower.contains('spray')) {
      ids.add('dishwasher-spray-holes');
    }
    if (lower.contains('seal')) {
      ids.add('dishwasher-door-seal-leak');
    }
  }
  return ids;
}

bool dishwasherEasyChecksSatisfied({
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
      if (isDishwasherEasyCheckStep(steps[i])) i,
  ];
  if (easySteps.isEmpty) {
    return true;
  }
  return easySteps.every(
    (index) => done.contains(guidanceStepId(index, steps[index])),
  );
}

List<String> orderDishwasherEasyChecksFirst(List<String> steps) {
  final easy = <String>[
    for (final step in steps)
      if (isDishwasherEasyCheckStep(step)) step,
  ];
  final rest = [
    for (final step in steps)
      if (!isDishwasherEasyCheckStep(step)) step,
  ];
  return [...easy, ...rest];
}

List<String> guidanceStepsForDishwasherEasyGate({
  required List<String> steps,
  required bool easyChecksSatisfied,
}) {
  if (easyChecksSatisfied) {
    return List<String>.from(steps);
  }
  return [
    for (final step in steps)
      if (!isDishwasherRepairGuidanceStep(step)) step,
  ];
}
