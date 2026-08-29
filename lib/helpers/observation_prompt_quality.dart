import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'dryer_problem_starter.dart';
import 'evidence_prompt_match.dart';
import 'package_authoring_index.dart';
import 'power_steering.dart';
import 'unmatched_starter.dart';

/// Symptom families used to keep early interview questions on-topic.
enum ObservationFamily {
  start,
  heat,
  drum,
  airflow,
  noise,
  smell,
  hazard,
}

/// Effort tier for a user-facing check (lower = prefer earlier).
enum ObservationEffort {
  listenLook,
  externalCheck,
}

/// Metadata for deterministic question ordering guards.
class ObservationPromptMeta {
  const ObservationPromptMeta({
    required this.families,
    required this.effort,
  });

  final Set<ObservationFamily> families;
  final ObservationEffort effort;
}

const Map<String, ObservationPromptMeta> observationPromptMetaById = {
  'dryer-response': ObservationPromptMeta(
    families: {ObservationFamily.start},
    effort: ObservationEffort.listenLook,
  ),
  'panel-lights': ObservationPromptMeta(
    families: {ObservationFamily.start},
    effort: ObservationEffort.listenLook,
  ),
  'door-closed-firmly': ObservationPromptMeta(
    families: {ObservationFamily.start},
    effort: ObservationEffort.listenLook,
  ),
  'door-held-closed-start': ObservationPromptMeta(
    families: {ObservationFamily.start},
    effort: ObservationEffort.listenLook,
  ),
  'control-lock-status': ObservationPromptMeta(
    families: {ObservationFamily.start},
    effort: ObservationEffort.listenLook,
  ),
  'outlet-power-check': ObservationPromptMeta(
    families: {ObservationFamily.start},
    effort: ObservationEffort.externalCheck,
  ),
  'heat-observed': ObservationPromptMeta(
    families: {ObservationFamily.heat},
    effort: ObservationEffort.listenLook,
  ),
  'cycle-heat-setting': ObservationPromptMeta(
    families: {ObservationFamily.heat},
    effort: ObservationEffort.listenLook,
  ),
  'heat-pattern': ObservationPromptMeta(
    families: {ObservationFamily.heat},
    effort: ObservationEffort.listenLook,
  ),
  'recent-overheat': ObservationPromptMeta(
    families: {ObservationFamily.heat, ObservationFamily.airflow},
    effort: ObservationEffort.externalCheck,
  ),
  'heat-before-failure': ObservationPromptMeta(
    families: {ObservationFamily.heat},
    effort: ObservationEffort.listenLook,
  ),
  'wall-plug-seated': ObservationPromptMeta(
    families: {ObservationFamily.heat, ObservationFamily.start},
    effort: ObservationEffort.externalCheck,
  ),
  'drum-turns': ObservationPromptMeta(
    families: {ObservationFamily.drum},
    effort: ObservationEffort.listenLook,
  ),
  'motor-audible': ObservationPromptMeta(
    families: {ObservationFamily.drum, ObservationFamily.start},
    effort: ObservationEffort.listenLook,
  ),
  'lint-filter-condition': ObservationPromptMeta(
    families: {ObservationFamily.airflow},
    effort: ObservationEffort.externalCheck,
  ),
  'lint-housing-slot': ObservationPromptMeta(
    families: {ObservationFamily.airflow},
    effort: ObservationEffort.externalCheck,
  ),
  'exterior-airflow': ObservationPromptMeta(
    families: {ObservationFamily.airflow},
    effort: ObservationEffort.externalCheck,
  ),
  'vent-hose-condition': ObservationPromptMeta(
    families: {ObservationFamily.airflow},
    effort: ObservationEffort.externalCheck,
  ),
  'dry-time-change': ObservationPromptMeta(
    families: {ObservationFamily.airflow},
    effort: ObservationEffort.listenLook,
  ),
  'clothes-feel-after-cycle': ObservationPromptMeta(
    families: {ObservationFamily.airflow, ObservationFamily.heat},
    effort: ObservationEffort.listenLook,
  ),
  'clothes-remain-damp': ObservationPromptMeta(
    families: {ObservationFamily.airflow},
    effort: ObservationEffort.listenLook,
  ),
  'load-size-wetness': ObservationPromptMeta(
    families: {ObservationFamily.airflow},
    effort: ObservationEffort.listenLook,
  ),
  'running-noise': ObservationPromptMeta(
    families: {ObservationFamily.noise},
    effort: ObservationEffort.listenLook,
  ),
  'noise-timing': ObservationPromptMeta(
    families: {ObservationFamily.noise},
    effort: ObservationEffort.listenLook,
  ),
  'odor-type': ObservationPromptMeta(
    families: {ObservationFamily.smell},
    effort: ObservationEffort.listenLook,
  ),
  'hazard-observation': ObservationPromptMeta(
    families: {ObservationFamily.hazard, ObservationFamily.smell},
    effort: ObservationEffort.listenLook,
  ),
  'breaker-tripped-check': ObservationPromptMeta(
    families: {ObservationFamily.start, ObservationFamily.heat},
    effort: ObservationEffort.externalCheck,
  ),
  'gas-dryer-type': ObservationPromptMeta(
    families: {ObservationFamily.heat},
    effort: ObservationEffort.listenLook,
  ),
  'gas-ignition-observed': ObservationPromptMeta(
    families: {ObservationFamily.heat, ObservationFamily.hazard},
    effort: ObservationEffort.listenLook,
  ),
  'duct-run-length': ObservationPromptMeta(
    families: {ObservationFamily.airflow},
    effort: ObservationEffort.externalCheck,
  ),
  'moisture-sensor-bars': ObservationPromptMeta(
    families: {ObservationFamily.airflow, ObservationFamily.heat},
    effort: ObservationEffort.externalCheck,
  ),
  'belt-slip-observation': ObservationPromptMeta(
    families: {ObservationFamily.drum},
    effort: ObservationEffort.listenLook,
  ),
  'cabinet-seal-gap': ObservationPromptMeta(
    families: {ObservationFamily.airflow},
    effort: ObservationEffort.externalCheck,
  ),
  'vent-pest-blockage': ObservationPromptMeta(
    families: {ObservationFamily.airflow},
    effort: ObservationEffort.externalCheck,
  ),
  'timer-heat-portion': ObservationPromptMeta(
    families: {ObservationFamily.heat},
    effort: ObservationEffort.listenLook,
  ),
  'relay-heat-output': ObservationPromptMeta(
    families: {ObservationFamily.heat},
    effort: ObservationEffort.listenLook,
  ),
  'motor-overheat-cooldown': ObservationPromptMeta(
    families: {ObservationFamily.start, ObservationFamily.drum},
    effort: ObservationEffort.listenLook,
  ),
  'door-latch-intermittent': ObservationPromptMeta(
    families: {ObservationFamily.start},
    effort: ObservationEffort.listenLook,
  ),
};

ObservationPromptMeta metaForTemplate(String templateId) {
  return observationPromptMetaById[templateId] ??
      const ObservationPromptMeta(
        families: {ObservationFamily.start},
        effort: ObservationEffort.listenLook,
      );
}

/// Infers active symptom families from starter complaint and recorded answers.
Set<ObservationFamily> inferActiveObservationFamilies({
  required List<Evidence> recordedEvidence,
  required List<EvidenceTemplate> templates,
  PackageAuthoringIndex? authoringIndex,
}) {
  final active = <ObservationFamily>{};

  for (final item in recordedEvidence) {
    if (item.templateId == problemStarterComplaintTemplateId) {
      // Unmatched Other is evidence only. Do not invent heat / noise / odor
      // families from the typed note (basement smell is not a hazard path).
      if (isUnmatchedOtherEvidence(item)) {
        continue;
      }
      final answer = (item.answer ?? item.observation).toLowerCase();
      for (final family in dryerStarterFamilies) {
        if (answer.contains(family.label.toLowerCase()) ||
            family.keywords.any(answer.contains)) {
          _addFamiliesForStarterSymptom(active, family.id);
        }
      }
      if (authoringIndex != null) {
        active.addAll(authoringIndex.familiesMatchingComplaint(answer));
      }
      continue;
    }

    EvidenceTemplate? template;
    for (final candidate in templates) {
      if (evidenceMatchesTemplate(item, candidate)) {
        template = candidate;
        break;
      }
    }
    if (template == null) {
      continue;
    }

    active.addAll(metaForTemplate(template.id).families);

    final answer = normalizeObservationAnswer(item.answer);
    if (template.id == 'dryer-response') {
      if (answer == 'Starts normally') {
        active.addAll({ObservationFamily.heat, ObservationFamily.drum});
      } else if (answer == 'Nothing happens' ||
          answer == 'Hums but does not start') {
        active.add(ObservationFamily.start);
      }
    }
    if (template.id == 'heat-observed' &&
        (answer == 'No warmth' || answer == 'Slight warmth')) {
      active.add(ObservationFamily.heat);
    }
    if (template.id == 'drum-turns') {
      active.add(ObservationFamily.drum);
    }
    if (template.id == 'exterior-airflow' ||
        template.id == 'clothes-remain-damp' ||
        template.id == 'dry-time-change') {
      active.add(ObservationFamily.airflow);
    }
    if (template.id == 'running-noise' && answer != 'No unusual sound') {
      active.add(ObservationFamily.noise);
    }
    if (template.id == 'odor-type' && answer != 'No unusual smell') {
      active.add(ObservationFamily.smell);
    }
  }

  if (active.isEmpty) {
    active.add(ObservationFamily.start);
  }
  return active;
}

void _addFamiliesForStarterSymptom(Set<ObservationFamily> active, String id) {
  switch (id) {
    case 'no-heat':
      active.addAll({ObservationFamily.heat, ObservationFamily.drum});
    case 'will-not-start':
      active.add(ObservationFamily.start);
    case 'motor-runs-drum-still':
      active.add(ObservationFamily.drum);
    case 'long-dry-time':
    case 'clothes-hot-but-damp':
    case 'weak-exterior-airflow':
      active.add(ObservationFamily.airflow);
    case 'squealing-or-thumping':
      active.add(ObservationFamily.noise);
    case 'dryer-very-hot':
      active.addAll({ObservationFamily.heat, ObservationFamily.airflow});
    case 'hazard-signs':
      active.addAll({ObservationFamily.hazard, ObservationFamily.smell});
    default:
      active.add(ObservationFamily.start);
  }
}

/// Higher score = better next question. Deterministic tie-break by package order.
int scoreObservationPrompt({
  required EvidenceTemplate template,
  required Set<ObservationFamily> activeFamilies,
  required List<String> topFailureModeIds,
  required int recordedCount,
  required int packageIndex,
  PackageAuthoringIndex? authoringIndex,
  List<Evidence> recordedEvidence = const [],
}) {
  var score = 0;
  final meta = metaForTemplate(template.id);

  for (final modeId in template.relatedFailureModeIds) {
    if (topFailureModeIds.contains(modeId)) {
      score += 8;
    }
  }

  if (authoringIndex != null) {
    for (final modeId in topFailureModeIds) {
      if (authoringIndex.supportTemplatesFor(modeId).contains(template.id)) {
        score += 14;
      }
      if (authoringIndex.firstLineTemplatesFor(modeId).contains(template.id)) {
        score += 10;
      }
    }
    if (topFailureModeIds.length >= 2) {
      final leader = topFailureModeIds.first;
      final runnerUp = topFailureModeIds[1];
      final supportsLeader =
          authoringIndex.supportTemplatesFor(leader).contains(template.id);
      final excludesRunner =
          authoringIndex.excludeTemplatesFor(runnerUp).contains(template.id);
      if (supportsLeader && excludesRunner) {
        score += 20;
      }
    }
  }

  if (meta.families.any(activeFamilies.contains)) {
    score += 24;
  } else if (recordedCount < 4) {
    score -= 18;
  } else {
    score -= 6;
  }

  if (meta.effort == ObservationEffort.listenLook) {
    score += 6;
  }

  // Preserve core branch order when little evidence exists.
  if (recordedCount <= 1 && template.id == 'drum-turns') {
    score += 12;
  }
  if (recordedCount <= 1 &&
      template.id == 'heat-observed' &&
      inferHeatPathPolarity(recordedEvidence: recordedEvidence) ==
          HeatPathPolarity.unknown) {
    score += 10;
  }

  // Fuel type constrains the whole heat branch. Ask immediately on a heat
  // path when unanswered — before electric-only element / fuse follow-ups.
  if (template.id == 'gas-dryer-type' &&
      activeFamilies.contains(ObservationFamily.heat) &&
      inferHeatPathPolarity(recordedEvidence: recordedEvidence) ==
          HeatPathPolarity.noHeat) {
    score += 80;
  }

  // De-prioritize smell/noise-only prompts on a clear heat/start path.
  if (recordedCount < 5 &&
      meta.families.every(
        (family) =>
            family == ObservationFamily.noise || family == ObservationFamily.smell,
      ) &&
      !activeFamilies.contains(ObservationFamily.noise) &&
      !activeFamilies.contains(ObservationFamily.smell)) {
    score -= 30;
  }

  if (shouldDeemphasizeDeadPowerModes(recordedEvidence) &&
      deadPowerInterviewTemplateIds.contains(template.id)) {
    score -= 40;
    if (isTemplateRecorded(
      template: template,
      recordedEvidence: recordedEvidence,
    )) {
      score -= 30;
    }
  }

  if (isNoHeatEstablished(
    recordedEvidence: recordedEvidence,
    templates: const [],
  ) &&
      inferHeatPathPolarity(recordedEvidence: recordedEvidence) ==
          HeatPathPolarity.noHeat) {
    if (redundantNoHeatConfirmationTemplateIds.contains(template.id) &&
        !isTemplateRecorded(
          template: template,
          recordedEvidence: recordedEvidence,
        )) {
      score -= 80;
    }
    if (template.id == 'lint-filter-condition') {
      score += 26;
    }
    if (template.id == 'exterior-airflow') {
      score += 22;
    }
    if (template.id == 'vent-hose-condition') {
      score += 18;
    }
    if (template.id == 'dry-time-change' ||
        template.id == 'recent-overheat') {
      score += 14;
    }
    final drumRecorded = recordedEvidence.any(
      (item) => item.templateId == 'drum-turns',
    );
    final cycleRecorded = recordedEvidence.any(
      (item) => item.templateId == 'cycle-heat-setting',
    );
    if (drumRecorded && cycleRecorded) {
      if (template.id == 'lint-filter-condition') {
        score += 48;
      }
      if (template.id == 'exterior-airflow') {
        score += 40;
      }
      if (template.id == 'vent-hose-condition') {
        score += 32;
      }
    }
    if (template.id == 'clothes-feel-after-cycle') {
      score += 8;
    }
  }

  if (inferHeatPathPolarity(recordedEvidence: recordedEvidence) ==
      HeatPathPolarity.excessHeat) {
    if (redundantExcessHeatConfirmationTemplateIds.contains(template.id) &&
        !isTemplateRecorded(
          template: template,
          recordedEvidence: recordedEvidence,
        )) {
      score -= 80;
    }
    if (template.id == 'lint-filter-condition') {
      score += 32;
    }
    if (template.id == 'exterior-airflow') {
      score += 28;
    }
    if (template.id == 'dry-time-change' ||
        template.id == 'vent-hose-condition') {
      score += 16;
    }
    if (template.id == 'clothes-feel-after-cycle') {
      score += 10;
    }
  }

  // Stable tie-breaker (lower index slightly better).
  score -= packageIndex;
  return score;
}
