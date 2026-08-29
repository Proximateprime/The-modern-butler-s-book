import '../models/appliance.dart';
import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'dryer_energy_source.dart';
import 'dryer_problem_starter.dart';
import 'dryer_start_easy_checks.dart';
import 'easy_airflow_checks.dart';
import 'evidence_prompt_match.dart';
import 'observation_prompt_quality.dart';
import 'package_authoring_index.dart';
import 'washer_easy_checks.dart';
import 'dishwasher_easy_checks.dart';
import 'fridge_easy_checks.dart';

/// Interview templates that discriminate no-heat causes without re-asking warmth.
const Set<String> noHeatDiscriminatorTemplateIds = {
  'lint-filter-condition',
  'exterior-airflow',
  'vent-hose-condition',
  'dry-time-change',
  'recent-overheat',
  'clothes-feel-after-cycle',
  'cycle-heat-setting',
  'clothes-remain-damp',
  'drum-turns',
  'heat-before-failure',
};

/// Discriminators for ongoing excess-heat / too-hot polarity.
const Set<String> excessHeatDiscriminatorTemplateIds = {
  'lint-filter-condition',
  'exterior-airflow',
  'vent-hose-condition',
  'dry-time-change',
  'clothes-feel-after-cycle',
};

/// First interview question after a confirmed problem starter.
///
/// When the starter already establishes no heat or excess heat, skips pure
/// heat re-confirms and picks a discriminator via [suggestNextObservation].
EvidenceTemplate? starterInterviewTemplate({
  required List<EvidenceTemplate> templates,
  required List<Evidence> recordedEvidence,
  required String firstTemplateId,
  Set<String> starterMatchedSymptomIds = const {},
  PackageAuthoringIndex? authoringIndex,
  ApplianceEnergySource energySource = ApplianceEnergySource.unknown,
}) {
  final fuel = _fuelQuestionIfNeeded(
    templates: templates,
    recordedEvidence: recordedEvidence,
    starterMatchedSymptomIds: starterMatchedSymptomIds,
    energySource: energySource,
  );
  if (fuel != null) {
    return fuel;
  }

  final polarity = inferHeatPathPolarity(
    recordedEvidence: recordedEvidence,
    starterMatchedSymptomIds: starterMatchedSymptomIds,
  );
  final establishedHeatPath =
      polarity == HeatPathPolarity.noHeat ||
      polarity == HeatPathPolarity.excessHeat ||
      starterMatchedSymptomIds.contains('no-heat') ||
      starterMatchedSymptomIds.contains('long-dry-time') ||
      starterMatchedSymptomIds.contains('dryer-very-hot');

  if (establishedHeatPath) {
    final next = suggestNextObservation(
      templates: templates,
      recordedEvidence: recordedEvidence,
      authoringIndex: authoringIndex,
      starterMatchedSymptomIds: starterMatchedSymptomIds,
      energySource: energySource,
    );
    if (next != null &&
        !shouldSuppressObservationForHeatPolarity(
          templateId: next.id,
          recordedEvidence: recordedEvidence,
          templates: templates,
          starterMatchedSymptomIds: starterMatchedSymptomIds,
        )) {
      return next;
    }

    final fallbackIds =
        polarity == HeatPathPolarity.excessHeat ||
                starterMatchedSymptomIds.contains('dryer-very-hot')
            ? excessHeatDiscriminatorTemplateIds
            : noHeatDiscriminatorTemplateIds;
    for (final template in templates) {
      if (fallbackIds.contains(template.id) &&
          !isTemplateRecorded(
            template: template,
            recordedEvidence: recordedEvidence,
          )) {
        return template;
      }
    }
    return null;
  }

  return starterFirstTemplate(
    templates: templates,
    firstTemplateId: firstTemplateId,
  );
}

/// Picks one unused evidence template with common-sense ordering guards.
///
/// Preference order:
/// 1. Related to the current primary hypothesis
/// 2. On-topic for inferred symptom families (avoids unrelated early questions)
/// 3. Low-effort listen/look checks before external/tool checks
/// 4. Best overlap with the current top supported modes
/// 5. Package order as tie-breaker
///
/// Skips the hazard prompt while suggesting (safety is handled separately when
/// the user chooses that prompt). Not a Reasoning Engine.
EvidenceTemplate? suggestNextObservation({
  required List<EvidenceTemplate> templates,
  required List<Evidence> recordedEvidence,
  String? primaryFailureModeId,
  Set<String> evidenceMatchedFailureModeIds = const {},
  List<String> topFailureModeIds = const [],
  PackageAuthoringIndex? authoringIndex,
  Set<String> starterMatchedSymptomIds = const {},
  ApplianceEnergySource energySource = ApplianceEnergySource.unknown,
}) {
  final fuel = _fuelQuestionIfNeeded(
    templates: templates,
    recordedEvidence: recordedEvidence,
    starterMatchedSymptomIds: starterMatchedSymptomIds,
    energySource: energySource,
  );
  if (fuel != null) {
    return fuel;
  }

  final remaining =
      unusedTemplates(
        templates: templates,
        recordedEvidence: recordedEvidence,
      ).where((template) {
        if (template.id == 'hazard-observation') {
          return false;
        }
        if (template.id == 'gas-ignition-observed') {
          return false;
        }
        if (template.id == 'relay-heat-output' &&
            isGasDryerFromEvidence(recordedEvidence)) {
          return false;
        }
        return !shouldSuppressObservationForHeatPolarity(
          templateId: template.id,
          recordedEvidence: recordedEvidence,
          templates: templates,
        );
      }).toList(growable: false);

  if (remaining.isEmpty) {
    return null;
  }

  if (shouldPrioritizeEasyAirflowChecks(
    recordedEvidence: recordedEvidence,
    starterMatchedSymptomIds: starterMatchedSymptomIds,
  )) {
    final easy = nextEasyAirflowCheckTemplate(
      remaining: remaining,
      polarity: inferHeatPathPolarity(
        recordedEvidence: recordedEvidence,
        starterMatchedSymptomIds: starterMatchedSymptomIds,
      ),
    );
    if (easy != null) {
      return easy;
    }
  }

  if (shouldPrioritizeDryerStartEasyChecks(
    recordedEvidence: recordedEvidence,
    starterMatchedSymptomIds: starterMatchedSymptomIds,
  )) {
    final easy = nextDryerStartEasyCheckTemplate(
      remaining: remaining,
      recordedEvidence: recordedEvidence,
      starterMatchedSymptomIds: starterMatchedSymptomIds,
    );
    if (easy != null) {
      return easy;
    }
  }

  if (shouldPrioritizeWasherEasyChecks(
    recordedEvidence: recordedEvidence,
  )) {
    final easy = nextWasherEasyCheckTemplate(
      remaining: remaining,
      recordedEvidence: recordedEvidence,
    );
    if (easy != null) {
      return easy;
    }
  }

  if (shouldPrioritizeDishwasherEasyChecks(
    recordedEvidence: recordedEvidence,
  )) {
    final easy = nextDishwasherEasyCheckTemplate(
      remaining: remaining,
      recordedEvidence: recordedEvidence,
    );
    if (easy != null) {
      return easy;
    }
  }

  if (shouldPrioritizeFridgeEasyChecks(
    recordedEvidence: recordedEvidence,
  )) {
    final easy = nextFridgeEasyCheckTemplate(
      remaining: remaining,
      recordedEvidence: recordedEvidence,
    );
    if (easy != null) {
      return easy;
    }
  }

  if (primaryFailureModeId != null) {
    for (final template in remaining) {
      if (template.relatedFailureModeIds.contains(primaryFailureModeId)) {
        return template;
      }
    }
  }

  final activeFamilies = inferActiveObservationFamilies(
    recordedEvidence: recordedEvidence,
    templates: templates,
    authoringIndex: authoringIndex,
  );
  final recordedCount = recordedEvidence.length;

  EvidenceTemplate? best;
  var bestScore = -999999;
  for (var i = 0; i < remaining.length; i++) {
    final template = remaining[i];
    final score = scoreObservationPrompt(
      template: template,
      activeFamilies: activeFamilies,
      topFailureModeIds: topFailureModeIds,
      recordedCount: recordedCount,
      packageIndex: i,
      authoringIndex: authoringIndex,
      recordedEvidence: recordedEvidence,
    );
    if (score > bestScore) {
      bestScore = score;
      best = template;
    }
  }

  if (best != null) {
    return best;
  }

  if (evidenceMatchedFailureModeIds.isNotEmpty) {
    for (final template in remaining) {
      final overlaps = template.relatedFailureModeIds.any(
        evidenceMatchedFailureModeIds.contains,
      );
      if (overlaps) {
        return template;
      }
    }
  }

  return remaining.first;
}

EvidenceTemplate? _fuelQuestionIfNeeded({
  required List<EvidenceTemplate> templates,
  required List<Evidence> recordedEvidence,
  required Set<String> starterMatchedSymptomIds,
  required ApplianceEnergySource energySource,
}) {
  if (!dryerNeedsFuelQuestionBeforeHeatComponents(
    energySource: energySource,
    recordedEvidence: recordedEvidence,
    templates: templates,
    starterMatchedSymptomIds: starterMatchedSymptomIds,
  )) {
    return null;
  }
  return gasDryerTypeTemplate(templates);
}
