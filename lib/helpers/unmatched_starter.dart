import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import '../models/appliance.dart';
import 'dryer_problem_starter.dart';
import 'evidence_prompt_match.dart';
import 'package_resolve.dart';
import 'user_facing_error.dart';

/// Observation label when starter Other is unmatched free text.
///
/// Typed text stores as this observation — not as the Answer to a warmth
/// question that was never shown.
const String unmatchedOtherObservation = 'Other / free-text';

/// Existing family-level templates asked after unmatched Other.
///
/// Power / heat / spin / error lights already ship in dryer-core.
/// Smell (`odor-type`) and leak have no dryer-core template — do not invent
/// one. Groq must not pick this order or mint chips.
const List<String> unmatchedUniversalTemplateIds = [
  'dryer-response',
  'heat-observed',
  'drum-turns',
  'panel-lights',
];

/// Ranked no-heat / noise interview templates. Unmatched Other must not
/// open these as the path.
const Set<String> rankedHeatOrNoiseInterviewTemplateIds = {
  'cycle-heat-setting',
  'lint-filter-condition',
  'lint-housing-slot',
  'exterior-airflow',
  'vent-hose-condition',
  'dry-time-change',
  'recent-overheat',
  'clothes-feel-after-cycle',
  'clothes-remain-damp',
  'heat-before-failure',
  'heat-pattern',
  'running-noise',
  'noise-timing',
  'belt-slip-observation',
};

/// Failure modes that are a squeal / worn-rollers candidate-set swap.
const Set<String> noiseRollerFailureModeIds = {
  'worn-drum-rollers',
  'idler-pulley-wear',
};

/// Why-ask must not name these as a diagnosis the household never gave.
const List<String> unmatchedWhyAskForbiddenDiagnosisTerms = [
  'belt',
  'heating-element',
  'heating element',
  'heat-relay',
  'heat relay',
  'broken drive belt',
  'drive belt',
  'thermal fuse',
  'worn-rollers',
  'worn rollers',
];

bool isUnmatchedOtherEvidence(Evidence evidence) {
  if (evidence.templateId != problemStarterComplaintTemplateId) {
    return false;
  }
  final observation = evidence.observation.trim();
  if (observation == unmatchedOtherObservation) {
    return true;
  }
  return observation.toLowerCase() == unmatchedOtherObservation.toLowerCase();
}

bool sessionHasUnmatchedOther(List<Evidence> evidence) {
  return evidence.any(isUnmatchedOtherEvidence);
}

String unmatchedOtherNote(List<Evidence> evidence) {
  for (final item in evidence) {
    if (!isUnmatchedOtherEvidence(item)) {
      continue;
    }
    return (item.answer ?? '').trim();
  }
  return '';
}

/// Packaged echo. Groq may rephrase display; it must not pick the next
/// question id or write how-to.
String unmatchedNoteEcho(String note) {
  final trimmed = note.trim();
  if (trimmed.isEmpty) {
    return UserFacingCopy.unmatchedNoteHeardEmpty;
  }
  return '${UserFacingCopy.unmatchedNoteHeardLead}“$trimmed”.';
}

bool isRankedHeatOrNoiseInterviewTemplate(String templateId) {
  return rankedHeatOrNoiseInterviewTemplateIds.contains(templateId);
}

EvidenceTemplate? nextUnmatchedUniversalTemplate({
  required List<EvidenceTemplate> templates,
  required List<Evidence> recordedEvidence,
}) {
  final byId = {for (final template in templates) template.id: template};
  for (final id in unmatchedUniversalTemplateIds) {
    final template = byId[id];
    if (template == null) {
      continue;
    }
    if (isTemplateRecorded(
      template: template,
      recordedEvidence: recordedEvidence,
    )) {
      continue;
    }
    return template;
  }
  return null;
}

bool unmatchedUniversalSetComplete({
  required List<EvidenceTemplate> templates,
  required List<Evidence> recordedEvidence,
}) {
  return nextUnmatchedUniversalTemplate(
        templates: templates,
        recordedEvidence: recordedEvidence,
      ) ==
      null;
}

/// Observation-only why. Does not name a diagnosis they never gave.
String unmatchedWhyAskBody({
  EvidenceTemplate? template,
  String? templateId,
}) {
  final id = template?.id ?? templateId?.trim() ?? '';
  return switch (id) {
    'dryer-response' =>
      'This records what happens when you try to start the dryer. '
          'It is an observation, not a diagnosis.',
    'heat-observed' =>
      'This records whether you feel warmth. It is an observation, '
          'not a diagnosis.',
    'drum-turns' =>
      'This records whether the drum turns. It is an observation, '
          'not a diagnosis.',
    'panel-lights' =>
      'This records whether the panel or lights respond. It is an '
          'observation, not a diagnosis.',
    _ => 'This records what you notice. It is an observation, not a diagnosis.',
  };
}

bool unmatchedWhyAskIsObservationOnly(String body) {
  final lower = body.toLowerCase();
  for (final term in unmatchedWhyAskForbiddenDiagnosisTerms) {
    if (lower.contains(term)) {
      return false;
    }
  }
  return lower.contains('observation') &&
      !lower.contains('no-heat cause') &&
      !lower.contains('no heat cause');
}

bool hasNoiseObservation({
  required List<Evidence> recordedEvidence,
  Set<String> starterMatchedSymptomIds = const {},
}) {
  if (starterMatchedSymptomIds.contains('squealing-or-thumping') ||
      starterMatchedSymptomIds.contains(dryerStarterNoiseOrSmellId)) {
    return true;
  }
  for (final item in recordedEvidence) {
    if (isUnmatchedOtherEvidence(item)) {
      continue;
    }
    if (item.templateId == 'running-noise') {
      final answer = normalizeObservationAnswer(item.answer);
      if (answer != null && answer != 'No unusual sound') {
        return true;
      }
    }
    if (item.templateId == 'noise-timing') {
      return true;
    }
  }
  return false;
}

/// Worn-rollers / squeal must not become the candidate set without a
/// noise observation.
bool shouldSuppressNoiseCandidateSwap({
  required List<Evidence> recordedEvidence,
  required Iterable<String> candidateFailureModeIds,
  Set<String> starterMatchedSymptomIds = const {},
}) {
  if (hasNoiseObservation(
    recordedEvidence: recordedEvidence,
    starterMatchedSymptomIds: starterMatchedSymptomIds,
  )) {
    return false;
  }
  return candidateFailureModeIds.any(noiseRollerFailureModeIds.contains);
}

String? dryerCoverageNotice({
  required String? manufacturer,
  required String? modelNumber,
  required bool usingGeneralGuide,
  required String category,
}) {
  if (category != 'dryer') {
    return null;
  }
  if (!dryerHasMachinePlate(manufacturer, modelNumber)) {
    return UserFacingCopy.missingMachinePlateNotice;
  }
  if (usingGeneralGuide) {
    return generalDryerGuideNotice;
  }
  return null;
}

bool dryerHasMachinePlate(String? manufacturer, String? modelNumber) {
  final brand = (manufacturer ?? '').trim();
  final model = (modelNumber ?? '').trim();
  if (brand.isEmpty && model.isEmpty) {
    return false;
  }
  if (_isPlaceholderBrand(brand) || _isPlaceholderModel(model)) {
    return false;
  }
  return brand.isNotEmpty || model.isNotEmpty;
}

bool _isPlaceholderBrand(String brand) {
  final lower = brand.toLowerCase();
  return lower == 'demo manufacturer' || isUnknownApplianceIdentity(brand);
}

bool _isPlaceholderModel(String model) {
  final upper = model.toUpperCase();
  return upper.startsWith('DEMO-') || isUnknownApplianceIdentity(model);
}

/// Starter families the Other keyword matcher must not auto-check.
const Set<String> starterHeatOrNoiseFamilyIds = {
  'no-heat',
  'dryer-very-hot',
  'squealing-or-thumping',
};

/// Entry chips that correspond to [starterHeatOrNoiseFamilyIds].
const Set<String> starterHeatOrNoiseChipIds = {
  'no-heat',
  'dryer-very-hot',
  dryerStarterNoiseOrSmellId,
};

/// Live keyword matcher for Other type-in. Never returns heat / noise /
/// too-hot chips. Never returns a dismissed id. Groq does not call this.
Set<String> starterKeywordMatcherChipIds({
  required String freeText,
  Set<String> dismissedIds = const {},
}) {
  final resolution = resolveDryerStarter(
    selectedSymptomIds: const {},
    freeText: freeText,
  );
  final chips = <String>{};
  for (final id in resolution.matchedSymptomIds) {
    final chipId =
        id == 'squealing-or-thumping' ? dryerStarterNoiseOrSmellId : id;
    if (starterHeatOrNoiseFamilyIds.contains(id) ||
        starterHeatOrNoiseChipIds.contains(chipId)) {
      continue;
    }
    if (dismissedIds.contains(id) || dismissedIds.contains(chipId)) {
      continue;
    }
    chips.add(chipId);
  }
  return chips;
}

/// Applies the Other keyword matcher without auto-checking heat / noise
/// chips and without re-adding ids the household unchecked.
Set<String> applyStarterKeywordMatcher({
  required Set<String> selectedIds,
  required String freeText,
  Set<String> dismissedIds = const {},
}) {
  if (!selectedIds.contains(dryerStarterOtherDescribeId)) {
    return selectedIds;
  }
  // Other typing is Evidence. Do not mint or re-check chips from keywords.
  // Hazard / won’t-start mapping still happens on Confirm via resolve.
  final suggested = starterKeywordMatcherChipIds(
    freeText: freeText,
    dismissedIds: dismissedIds,
  );
  for (final id in suggested) {
    if (starterHeatOrNoiseChipIds.contains(id)) {
      continue;
    }
    if (dismissedIds.contains(id)) {
      continue;
    }
  }
  return Set<String>.from(selectedIds);
}

/// Confirm / interpretation: Other-only typed text must not become a
/// heat / noise family unless the household checked that chip.
DryerStarterResolution resolutionWithoutHeatNoiseUnlessChecked({
  required DryerStarterResolution resolution,
  required Set<String> selectedSymptomIds,
}) {
  final userFamilies = canonicalizeStarterSelection(selectedSymptomIds);
  final keptIds = [
    for (final id in resolution.matchedSymptomIds)
      if (!starterHeatOrNoiseFamilyIds.contains(id) ||
          userFamilies.contains(id))
        id,
  ];
  if (keptIds.length == resolution.matchedSymptomIds.length) {
    return resolution;
  }
  if (keptIds.isEmpty) {
    return DryerStarterResolution(
      matchedSymptomIds: const [],
      labels: const [],
      firstTemplateId: dryerStarterDefaultTemplateId,
      unmatchedFreeText: true,
    );
  }
  final families = [
    for (final id in keptIds) dryerStarterFamilyById(id),
  ].whereType<DryerStarterFamily>().toList()
    ..sort((a, b) => a.priority.compareTo(b.priority));
  return DryerStarterResolution(
    matchedSymptomIds: families.map((f) => f.id).toList(growable: false),
    labels: families.map((f) => f.label).toList(growable: false),
    firstTemplateId: families.first.firstTemplateId,
    unmatchedFreeText: resolution.unmatchedFreeText,
  );
}
