import '../models/evidence.dart';
import 'evidence_prompt_match.dart';

/// Failure modes that assume the dryer is dead or supply-interrupted.
const deadPowerFailureModeIds = {
  'no-power-at-outlet',
  'missing-leg-240v-supply',
  'electric-supply-connection-fault',
};

/// Templates that only make sense while power/dead-machine is still unknown.
const deadPowerInterviewTemplateIds = {
  'outlet-power-check',
  'breaker-tripped-check',
  'panel-lights',
};

String? _answerFor(List<Evidence> evidence, String templateId) {
  return normalizeObservationAnswer(
    answerForTemplate(recordedEvidence: evidence, templateId: templateId),
  );
}

/// True when recorded answers show the dryer is not fully dead at the supply.
bool powerConfirmedFine(List<Evidence> evidence) {
  final panel = _answerFor(evidence, 'panel-lights');
  final response = _answerFor(evidence, 'dryer-response');
  final outlet = _answerFor(evidence, 'outlet-power-check');
  final breaker = _answerFor(evidence, 'breaker-tripped-check');

  if (panel == 'No lights at all' ||
      response == 'Nothing happens' ||
      outlet == 'Outlet appears dead / breaker tripped' ||
      breaker == 'Whole breaker tripped off') {
    return false;
  }

  return panel == 'Yes, panel responds' ||
      response == 'Starts normally' ||
      breaker == 'Both poles on, supply looks normal' ||
      outlet == 'Breaker looks on; still no dryer lights' ||
      outlet == 'Other nearby power looks normal; dryer still dead';
}

/// True when the machine is actually running / tumbling, not fully dead.
bool machineRuns(List<Evidence> evidence) {
  final drum = _answerFor(evidence, 'drum-turns');
  final response = _answerFor(evidence, 'dryer-response');
  return drum == 'Turns normally' ||
      drum == 'Motor runs, drum still' ||
      drum == 'Turns briefly then stops' ||
      response == 'Starts normally' ||
      response == 'Starts then stops';
}

/// Power is fine and the machine runs — dead-supply modes should not lead.
bool shouldDeemphasizeDeadPowerModes(List<Evidence> evidence) {
  return powerConfirmedFine(evidence) && machineRuns(evidence);
}

/// Failure modes that assume current heat is absent (not ongoing too-hot).
const Set<String> noHeatFailureModeIds = {
  'thermal-fuse-open',
  'heating-element-failed',
  'high-limit-thermostat-open',
  'electric-supply-connection-fault',
  'relay-or-control-no-heat-output',
  'missing-leg-240v-supply',
  'accessible-thermal-reset',
  'motor-overheat-protector-open',
};

/// Down-rank no-heat modes when the live complaint is ongoing excess heat.
bool shouldDeemphasizeNoHeatModes(List<Evidence> evidence) {
  return inferHeatPathPolarity(recordedEvidence: evidence) ==
      HeatPathPolarity.excessHeat;
}
