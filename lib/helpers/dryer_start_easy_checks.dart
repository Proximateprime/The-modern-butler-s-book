import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'dryer_problem_starter.dart';
import 'evidence_prompt_match.dart';

/// Non-invasive start checks after **Won't start** (not live metering).
const List<String> dryerWontStartEasyCheckOrder = [
  'door-closed-firmly',
  'panel-lights',
  'control-lock-status',
  'outlet-power-check',
  'door-held-closed-start',
];

/// Listen/look after **Drum doesn't turn** (belt vs motor).
const List<String> dryerNoTumbleEasyCheckOrder = [
  'motor-audible',
];

const Set<String> dryerStartEasyCheckTemplateIds = {
  ...dryerWontStartEasyCheckOrder,
  ...dryerNoTumbleEasyCheckOrder,
};

/// Modes whose first guidance must stay outside the cabinet.
const Set<String> dryerStartEasyChecksBeforeRepairModeIds = {
  'door-switch-failure',
  'control-lock-engaged',
  'no-power-at-outlet',
  'motor-failure',
  'broken-drive-belt',
};

bool shouldPrioritizeDryerStartEasyChecks({
  required List<Evidence> recordedEvidence,
  Set<String> starterMatchedSymptomIds = const {},
}) {
  if (starterMatchedSymptomIds.contains('will-not-start') ||
      starterMatchedSymptomIds.contains('motor-runs-drum-still')) {
    return true;
  }
  for (final item in recordedEvidence) {
    if (item.templateId == problemStarterComplaintTemplateId) {
      final text = '${item.answer ?? ''} ${item.observation}'.toLowerCase();
      if (text.contains('won\'t start') ||
          text.contains('wont start') ||
          text.contains('will not start') ||
          text.contains('drum doesn') ||
          text.contains('no tumble')) {
        return true;
      }
    }
    final answer = normalizeObservationAnswer(item.answer);
    if (item.templateId == 'dryer-response' &&
        (answer == 'Nothing happens' ||
            answer == 'Hums but does not start' ||
            answer == 'Starts then stops')) {
      return true;
    }
    if (item.templateId == 'drum-turns' &&
        (answer == 'Does not turn' || answer == 'Motor runs, drum still')) {
      return true;
    }
  }
  return false;
}

bool isDryerStartEasyCheckStep(String step) {
  final lower = step.toLowerCase();
  if (lower.contains('bypass') && lower.contains('door switch')) {
    return true;
  }
  if (lower.contains('door') &&
      (lower.contains('click') || lower.contains('firmly closed'))) {
    return true;
  }
  if (lower.contains('control lock') || lower.contains('child lock')) {
    return true;
  }
  if (lower.contains('breaker') && lower.contains('visual')) {
    return true;
  }
  if (lower.contains('motor run') && lower.contains('drum does not turn')) {
    return true;
  }
  return false;
}

EvidenceTemplate? nextDryerStartEasyCheckTemplate({
  required List<EvidenceTemplate> remaining,
  required List<Evidence> recordedEvidence,
  Set<String> starterMatchedSymptomIds = const {},
}) {
  final ids = <String>[];
  final wontStart =
      starterMatchedSymptomIds.contains('will-not-start') ||
      recordedEvidence.any((item) => item.templateId == 'dryer-response');
  final noTumble =
      starterMatchedSymptomIds.contains('motor-runs-drum-still') ||
      recordedEvidence.any((item) {
        if (item.templateId != 'drum-turns') {
          return false;
        }
        final answer = normalizeObservationAnswer(item.answer);
        return answer == 'Does not turn' || answer == 'Motor runs, drum still';
      });
  if (wontStart) {
    ids.addAll(dryerWontStartEasyCheckOrder);
  }
  if (noTumble) {
    ids.addAll(dryerNoTumbleEasyCheckOrder);
  }
  if (ids.isEmpty) {
    ids.addAll(dryerWontStartEasyCheckOrder);
  }
  for (final id in ids) {
    for (final template in remaining) {
      if (template.id == id) {
        return template;
      }
    }
  }
  return null;
}
