import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import '../knowledge_factory/washer_mvp_v01.dart';
import 'close_path_phase.dart';
import 'dryer_close_path.dart';
import 'evidence_prompt_match.dart';

/// Washer interview order depends on the starter complaint.
/// Presentation only — does not change ranking.
const List<String> washerEasyCheckTemplateOrder = [
  'washer-door-click',
  'washer-drain-filter-access',
];

const Set<String> washerEasyCheckTemplateIds = {
  'washer-door-click',
  'washer-drain-filter-access',
  'washer-drain-hose-look',
  'washer-taps-open',
  'washer-inlet-screens-look',
  'washer-load-bunched',
  'washer-water-in-drum',
  'washer-leak-at-tap',
  'washer-standpipe-hose',
  'washer-power-or-lock',
};

const Set<String> washerEasyChecksBeforeRepairModeIds = {
  washerCloggedDrainFilterId,
  washerDrainHoseId,
  washerClosedTapsId,
  washerCloggedInletScreensId,
  washerUnbalancedLoadId,
  washerLooseInletHoseId,
  washerDrainHoseNotSeatedId,
  washerDoorNotLatchedId,
  washerNoPowerOrLockId,
};

const String washerEasyDoorGuidanceStep =
    'Check that the washer door closes firmly until you feel or hear a click. '
    'Do not bypass the door switch.';

const String washerEasyFilterLookGuidanceStep =
    'Look for an accessible drain filter at the front or bottom. Stay outside '
    'a sealed tub or pump.';

const List<String> canonicalWasherEasyGuidanceSteps = [
  washerEasyDoorGuidanceStep,
  washerEasyFilterLookGuidanceStep,
];

bool isWasherEasyCheckStep(String step) {
  if (isWasherRepairGuidanceStep(step)) {
    return false;
  }
  final lower = step.toLowerCase();
  if (lower.contains('door') &&
      (lower.contains('click') || lower.contains('latch'))) {
    return true;
  }
  if (lower.contains('accessible drain filter') &&
      (lower.contains('look') || lower.contains('look for'))) {
    return true;
  }
  if (lower.contains('look') &&
      (lower.contains('tap') ||
          lower.contains('inlet') ||
          lower.contains('standpipe') ||
          lower.contains('drain hose') ||
          lower.contains('plug') ||
          lower.contains('load') ||
          lower.contains('coupling'))) {
    return true;
  }
  if (lower.contains('open both hot and cold taps')) {
    return true;
  }
  if (lower.contains('screen') && lower.contains('hose')) {
    return true;
  }
  return false;
}

/// Cleaning, disconnecting, or moving steps that wait until easy looks are done.
bool isWasherRepairGuidanceStep(String step) {
  final lower = step.toLowerCase();
  if (lower.contains('do not bypass')) {
    return false;
  }
  if (lower.contains('user-accessible filter') ||
      lower.contains('shallow pan') ||
      lower.contains('remove lint, coins') ||
      lower.contains('close the filter firmly')) {
    return true;
  }
  if (lower.contains('unplug') &&
      (lower.contains('filter') ||
          lower.contains('moving') ||
          lower.contains('pull') ||
          lower.contains('touching') ||
          lower.contains('loosening') ||
          lower.contains('close the tap') ||
          lower.contains('close both taps'))) {
    return true;
  }
  if (lower.contains('unscrew only the hose') ||
      lower.contains('hand-tighten') ||
      lower.contains('seat the drain hose')) {
    return true;
  }
  return false;
}

bool closePathNeedsWasherEasyChecksFirst(FailureModeClosePath path) {
  return washerEasyChecksBeforeRepairModeIds.contains(path.failureModeId);
}

List<String> washerEasyCheckOrderForEvidence(List<Evidence> recordedEvidence) {
  final complaint = _washerComplaintAnswer(recordedEvidence);
  if (complaint.contains('drain')) {
    return const [
      'washer-door-click',
      'washer-drain-filter-access',
      'washer-drain-hose-look',
    ];
  }
  if (complaint.contains('fill')) {
    if (_washerTemplateAnswer(recordedEvidence, 'washer-taps-open') == 'no') {
      return const ['washer-taps-open'];
    }
    return const ['washer-taps-open', 'washer-inlet-screens-look'];
  }
  if (complaint.contains('spin')) {
    return const ['washer-water-in-drum', 'washer-load-bunched'];
  }
  if (complaint.contains('leak')) {
    return const ['washer-leak-at-tap', 'washer-standpipe-hose'];
  }
  if (complaint.contains('start')) {
    return const ['washer-door-click', 'washer-power-or-lock'];
  }
  if (complaint.contains('door')) {
    return const ['washer-door-click'];
  }
  return washerEasyCheckTemplateOrder;
}

EvidenceTemplate? nextWasherEasyCheckTemplate({
  required List<EvidenceTemplate> remaining,
  List<Evidence> recordedEvidence = const [],
}) {
  for (final id in washerEasyCheckOrderForEvidence(recordedEvidence)) {
    for (final template in remaining) {
      if (template.id == id) {
        return template;
      }
    }
  }
  return null;
}

bool shouldPrioritizeWasherEasyChecks({
  required List<Evidence> recordedEvidence,
}) {
  for (final item in recordedEvidence) {
    if (item.templateId == washerComplaintTemplateId) {
      return true;
    }
  }
  return false;
}

String _washerComplaintAnswer(List<Evidence> recordedEvidence) {
  for (final item in recordedEvidence) {
    if (item.templateId != washerComplaintTemplateId) {
      continue;
    }
    return normalizeObservationAnswer(item.answer)?.toLowerCase() ?? '';
  }
  return '';
}

String? _washerTemplateAnswer(
  List<Evidence> recordedEvidence,
  String templateId,
) {
  for (final item in recordedEvidence) {
    if (item.templateId != templateId) continue;
    return normalizeObservationAnswer(item.answer)?.toLowerCase();
  }
  return null;
}

Set<String> _easyTemplateIdsImpliedBySteps(List<String> steps) {
  final ids = <String>{};
  for (final step in steps) {
    if (!isWasherEasyCheckStep(step)) {
      continue;
    }
    final lower = step.toLowerCase();
    if (lower.contains('door') &&
        (lower.contains('click') || lower.contains('latch'))) {
      ids.add('washer-door-click');
    }
    if (lower.contains('accessible drain filter')) {
      ids.add('washer-drain-filter-access');
    }
    if (lower.contains('standpipe') ||
        (lower.contains('drain hose') && lower.contains('look'))) {
      ids.add('washer-drain-hose-look');
    }
    if (lower.contains('coupling')) {
      ids.add('washer-leak-at-tap');
    } else if (lower.contains('tap')) {
      ids.add('washer-taps-open');
    }
    if (lower.contains('screen') && lower.contains('hose')) {
      ids.add('washer-inlet-screens-look');
    }
    if (lower.contains('load')) {
      ids.add('washer-load-bunched');
    }
    if (lower.contains('plug') || lower.contains('control-lock')) {
      ids.add('washer-power-or-lock');
    }
  }
  return ids;
}

bool washerEasyChecksSatisfied({
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
      if (isWasherEasyCheckStep(steps[i])) i,
  ];
  if (easySteps.isEmpty) {
    return true;
  }
  return easySteps.every(
    (index) => done.contains(guidanceStepId(index, steps[index])),
  );
}

List<String> orderWasherEasyChecksFirst(
  List<String> steps, {
  String? failureModeId,
}) {
  final easy = <String>[
    for (final step in steps)
      if (isWasherEasyCheckStep(step)) step,
  ];
  final rest = [
    for (final step in steps)
      if (!isWasherEasyCheckStep(step)) step,
  ];

  String? take(bool Function(String) match) {
    final index = easy.indexWhere(match);
    if (index < 0) {
      return null;
    }
    return easy.removeAt(index);
  }

  bool isDoor(String step) =>
      step.toLowerCase().contains('door') &&
      (step.toLowerCase().contains('click') ||
          step.toLowerCase().contains('latch'));
  bool isFilterLook(String step) =>
      step.toLowerCase().contains('accessible drain filter');

  final injectDoorFilter = failureModeId == washerCloggedDrainFilterId ||
      (failureModeId == null &&
          steps.any((step) => step.toLowerCase().contains('accessible drain filter')));

  if (!injectDoorFilter) {
    return [...easy, ...rest];
  }

  return [
    take(isDoor) ?? canonicalWasherEasyGuidanceSteps[0],
    take(isFilterLook) ?? canonicalWasherEasyGuidanceSteps[1],
    ...easy,
    ...rest,
  ];
}

List<String> guidanceStepsForWasherEasyGate({
  required List<String> steps,
  required bool easyChecksSatisfied,
}) {
  if (easyChecksSatisfied) {
    return List<String>.from(steps);
  }
  return [
    for (final step in steps)
      if (!isWasherRepairGuidanceStep(step)) step,
  ];
}
