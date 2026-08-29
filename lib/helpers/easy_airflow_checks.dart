import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'close_path_phase.dart';
import 'dryer_close_path.dart';
import 'dryer_problem_starter.dart';
import 'evidence_prompt_match.dart';

/// Interview order for no-heat / long-dry / overheat: filter, then outside
/// hood, then visible hose. Presentation only — does not change ranking.
const List<String> easyAirflowCheckTemplateOrder = [
  'lint-filter-condition',
  'exterior-airflow',
  'vent-hose-condition',
];

const Set<String> easyAirflowCheckTemplateIds = {
  'lint-filter-condition',
  'exterior-airflow',
  'vent-hose-condition',
};

/// Dryer modes where next steps must verify airflow before panel or parts work.
const Set<String> dryerEasyAirflowBeforePartsModeIds = {
  'restricted-exhaust-airflow',
  'clogged-lint-pathway',
  'thermal-fuse-open',
  'heating-element-failed',
  'high-limit-thermostat-open',
  'thermistor-fault-electronic',
  'cycling-thermostat-failed',
  'cycling-thermostat-stuck-open',
  'cycling-thermostat-stuck-closed',
  'relay-or-control-no-heat-output',
  'timer-advanced-no-heat-portion',
  'motor-overheat-protector-open',
  'accessible-thermal-reset',
};

/// Shared beginner line for no-heat / long-dry / overheat easy checks.
const String easyAirflowBeforeCabinetLine =
    'Check airflow before opening the cabinet.';

const List<String> canonicalEasyAirflowGuidanceSteps = [
  '$easyAirflowBeforeCabinetLine Pull the lint filter and look at the screen.',
  '$easyAirflowBeforeCabinetLine Go outside to the vent hood while the dryer '
      'runs.',
  '$easyAirflowBeforeCabinetLine Look behind the dryer at the visible vent '
      'hose for crush, kinks, packed lint, or a long run.',
];

const String lintFilterEasyPrompt =
    '$easyAirflowBeforeCabinetLine Pull the lint filter and look at the '
    'screen. What do you see?';

const String exteriorAirflowEasyPrompt =
    '$easyAirflowBeforeCabinetLine Go outside to the vent hood while the '
    'dryer runs. How strong is the air at the outside vent?';

const String ventHoseEasyPrompt =
    '$easyAirflowBeforeCabinetLine Look behind the dryer at the visible vent '
    'hose. Is it crushed, kinked, packed with lint, or a long restricted run?';

bool isEasyAirflowCheckStep(String step) {
  if (isInvasiveGuidanceStep(step)) {
    return false;
  }
  final lower = step.toLowerCase();
  if (lower.contains('lint filter')) {
    return true;
  }
  if (lower.contains('outside vent') ||
      lower.contains('exterior vent') ||
      lower.contains('vent hood')) {
    return true;
  }
  if (lower.contains('vent hose') ||
      (lower.contains('crushed') && lower.contains('vent')) ||
      (lower.contains('kink') && lower.contains('hose'))) {
    return true;
  }
  return false;
}

bool _isLintFilterEasyStep(String step) =>
    step.toLowerCase().contains('lint filter');

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

/// No-heat, overheat, or long-dry symptoms — easy airflow checks apply.
bool shouldPrioritizeEasyAirflowChecks({
  required List<Evidence> recordedEvidence,
  Set<String> starterMatchedSymptomIds = const {},
}) {
  final polarity = inferHeatPathPolarity(
    recordedEvidence: recordedEvidence,
    starterMatchedSymptomIds: starterMatchedSymptomIds,
  );
  if (polarity == HeatPathPolarity.noHeat ||
      polarity == HeatPathPolarity.excessHeat) {
    return true;
  }
  if (starterMatchedSymptomIds.contains('long-dry-time') ||
      starterMatchedSymptomIds.contains('weak-exterior-airflow') ||
      starterMatchedSymptomIds.contains('clothes-hot-but-damp')) {
    return true;
  }
  for (final item in recordedEvidence) {
    if (item.templateId == problemStarterComplaintTemplateId) {
      final text = '${item.answer ?? ''} ${item.observation}'.toLowerCase();
      if (text.contains('long dry') ||
          text.contains('takes forever') ||
          text.contains('still wet') ||
          text.contains('won\'t dry') ||
          text.contains('wont dry')) {
        return true;
      }
    }
    final answer = normalizeObservationAnswer(item.answer);
    if (item.templateId == 'clothes-remain-damp' && answer == 'Still damp') {
      return true;
    }
    if (item.templateId == 'dry-time-change' &&
        (answer == 'Much longer' || answer == 'Somewhat longer')) {
      return true;
    }
  }
  return false;
}

/// Next unused easy-check template in filter → hood → hose order.
EvidenceTemplate? nextEasyAirflowCheckTemplate({
  required List<EvidenceTemplate> remaining,
  HeatPathPolarity polarity = HeatPathPolarity.unknown,
}) {
  if (polarity == HeatPathPolarity.noHeat) {
    for (final template in remaining) {
      if (template.id == 'drum-turns') {
        return template;
      }
    }
  }
  for (final id in easyAirflowCheckTemplateOrder) {
    for (final template in remaining) {
      if (template.id == id) {
        return template;
      }
    }
  }
  return null;
}

bool easyAirflowChecksSatisfied({
  required List<Evidence> recordedEvidence,
  required List<String> steps,
  required Iterable<String> completedIds,
}) {
  final recorded = recordedEvidence
      .map((item) => item.templateId)
      .whereType<String>()
      .toSet();
  if (easyAirflowCheckTemplateOrder.every(recorded.contains)) {
    return true;
  }
  final done = completedIds.toSet();
  final easySteps = [
    for (var i = 0; i < steps.length; i++)
      if (isEasyAirflowCheckStep(steps[i])) i,
  ];
  if (easySteps.isEmpty) {
    return true;
  }
  return easySteps.every(
    (index) => done.contains(guidanceStepId(index, steps[index])),
  );
}

/// Whether next steps must verify lint filter / outside air / vent hose
/// before panel or replace-part work.
///
/// Ranking may still name a part. Use this for presentation order and gating
/// only. True on no-heat / long-dry / overheat evidence, or when the close
/// path is a heat/airflow part mode.
bool closePathNeedsEasyAirflowFirst(
  FailureModeClosePath path, {
  List<Evidence> recordedEvidence = const [],
  Set<String> starterMatchedSymptomIds = const {},
}) {
  if (shouldPrioritizeEasyAirflowChecks(
    recordedEvidence: recordedEvidence,
    starterMatchedSymptomIds: starterMatchedSymptomIds,
  )) {
    return true;
  }
  return dryerEasyAirflowBeforePartsModeIds.contains(path.failureModeId);
}

/// Puts filter / outside hood / hose before panel or replace-part steps.
List<String> orderEasyAirflowGuidanceFirst(List<String> steps) {
  final easy = <String>[
    for (final step in steps)
      if (isEasyAirflowCheckStep(step)) step,
  ];
  final rest = [
    for (final step in steps)
      if (!isEasyAirflowCheckStep(step)) step,
  ];

  String? take(bool Function(String) match) {
    final index = easy.indexWhere(match);
    if (index < 0) {
      return null;
    }
    return easy.removeAt(index);
  }

  final ordered = <String>[
    take(_isLintFilterEasyStep) ?? canonicalEasyAirflowGuidanceSteps[0],
    take(_isOutsideVentEasyStep) ?? canonicalEasyAirflowGuidanceSteps[1],
    take(_isVentHoseEasyStep) ?? canonicalEasyAirflowGuidanceSteps[2],
    ...easy,
  ];
  return [...ordered, ...rest];
}

/// Hides panel / part / unplug-for-teardown steps until easy checks are done
/// or skipped with I couldn't.
List<String> guidanceStepsForEasyAirflowGate({
  required List<String> steps,
  required bool easyChecksSatisfied,
}) {
  if (easyChecksSatisfied) {
    return List<String>.from(steps);
  }
  return [
    for (final step in steps)
      if (isEasyAirflowCheckStep(step)) step,
  ];
}
