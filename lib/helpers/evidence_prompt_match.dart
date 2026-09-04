import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'dryer_problem_starter.dart';
import 'easy_check_already_checked.dart';

/// Engine id for the optional type-in chip. Display labels may change; this
/// recorded prefix never does.
const String kOtherDescribeChoiceId = 'Other / describe';

/// Fallback answer choices when a template does not define [answerChoices].
const List<String> observationAnswerChoices = [
  'Yes',
  'No',
  'Sometimes',
  'Not sure',
  kOtherDescribeChoiceId,
];

/// Templates that intentionally use generic Yes/No/Sometimes chips.
const Set<String> genericBooleanObservationTemplateIds = {
  'hazard-observation',
};

/// Whether [template] would render generic Yes/No/Sometimes chips.
bool usesGenericBooleanAnswerFallback(EvidenceTemplate template) {
  if (template.answerChoices.isNotEmpty) {
    return false;
  }
  if (genericBooleanObservationTemplateIds.contains(template.id)) {
    return true;
  }
  return answerChoicesFromTemplateEffects(template).isEmpty;
}

/// Resolves the answer labels to show for [template].
///
/// Package-authored [EvidenceTemplate.answerChoices] win. Categorical
/// observations must never silently fall back to Yes/No/Sometimes — infer from
/// template effect maps when choices were not authored, or offer uncertainty-only
/// chips rather than misleading boolean labels.
List<String> answerChoicesFor(
  EvidenceTemplate template, {
  bool offerAlreadyChecked = true,
}) {
  late final List<String> base;
  if (template.answerChoices.isNotEmpty) {
    base = template.answerChoices;
  } else {
    final fromEffects = answerChoicesFromTemplateEffects(template);
    if (fromEffects.isNotEmpty) {
      base = fromEffects;
    } else if (genericBooleanObservationTemplateIds.contains(template.id)) {
      base = observationAnswerChoices;
    } else {
      base = const ['Not sure', kOtherDescribeChoiceId];
    }
  }
  if (!offerAlreadyChecked) {
    return base;
  }
  return withAlreadyCheckedEasyCheckChoice(
    templateId: template.id,
    choices: base,
  );
}

/// Collects distinct answer labels referenced by a template's effect maps.
List<String> answerChoicesFromTemplateEffects(EvidenceTemplate template) {
  final seen = <String>{};
  final ordered = <String>[];
  void addKeys(Iterable<String> keys) {
    for (final key in keys) {
      if (seen.add(key)) {
        ordered.add(key);
      }
    }
  }

  addKeys(template.supportByAnswer.keys);
  addKeys(template.excludeByAnswer.keys);
  if (ordered.isEmpty) {
    return const [];
  }
  if (!seen.contains('Not sure')) {
    ordered.add('Not sure');
  }
  if (!seen.contains(kOtherDescribeChoiceId)) {
    ordered.add(kOtherDescribeChoiceId);
  }
  return ordered;
}

/// Human-readable question text for [template], never a raw id/slug.
///
/// Authored [EvidenceTemplate.promptText] is used as-is. A template whose
/// prompt is missing or still equal to its id falls back to a humanized label
/// so the interview never surfaces slugs like `gas-dryer-type` to the user.
String observationPromptTitle(EvidenceTemplate template) {
  if (template.id == 'gas-dryer-type') {
    return 'Is this dryer gas or electric?';
  }
  final prompt = template.promptText.trim();
  if (prompt.isNotEmpty && prompt != template.id) {
    return prompt;
  }
  return humanizeObservationId(template.id);
}

/// Converts a slug id into sentence-case words (`gas-dryer-type` -> `Gas dryer type`).
String humanizeObservationId(String id) {
  final words = id
      .split(RegExp(r'[-_\s]+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) {
    return 'Observation';
  }
  final first = words.first;
  return [
    first.substring(0, 1).toUpperCase() + first.substring(1),
    ...words.skip(1),
  ].join(' ');
}

/// Stable widget key suffix for an answer choice label.
String answerChoiceKeySuffix(String choice) {
  return choice.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}

/// Matches recorded evidence to a package template by id when present,
/// otherwise by exact prompt text equality (legacy records).
bool evidenceMatchesTemplate(Evidence evidence, EvidenceTemplate template) {
  final templateId = evidence.templateId;
  if (templateId != null && templateId.isNotEmpty) {
    return templateId == template.id;
  }
  return template.promptText == evidence.observation;
}

bool isTemplateRecorded({
  required EvidenceTemplate template,
  required List<Evidence> recordedEvidence,
}) {
  for (final item in recordedEvidence) {
    if (evidenceMatchesTemplate(item, template)) {
      return true;
    }
  }
  return false;
}

List<EvidenceTemplate> unusedTemplates({
  required List<EvidenceTemplate> templates,
  required List<Evidence> recordedEvidence,
}) {
  return templates
      .where(
        (template) => !isTemplateRecorded(
          template: template,
          recordedEvidence: recordedEvidence,
        ),
      )
      .toList(growable: false);
}

/// Whether [templateId] is a close-path verification prompt, not an interview
/// observation.
bool isCloseVerificationTemplateId(String? templateId) {
  return templateId != null && templateId.startsWith('close-verify-');
}

/// User interview observations only — excludes starter and close verification.
bool isInterviewObservationEvidence(Evidence evidence) {
  final templateId = evidence.templateId;
  if (templateId == null || templateId.isEmpty) {
    return false;
  }
  if (templateId == problemStarterComplaintTemplateId) {
    return false;
  }
  if (templateId == 'free-observation-note') {
    return false;
  }
  return !isCloseVerificationTemplateId(templateId);
}

/// Chronological interview observations for one session.
List<Evidence> interviewObservationsInOrder(List<Evidence> recordedEvidence) {
  return recordedEvidence
      .where(isInterviewObservationEvidence)
      .toList(growable: false);
}

/// Household Clues chrome count and Clues list — one filter, same items.
///
/// Identical to [interviewObservationsInOrder]. Do not count a different set
/// than the list paints.
List<Evidence> householdCluesInOrder(List<Evidence> recordedEvidence) {
  return interviewObservationsInOrder(recordedEvidence);
}

/// Latest recorded answer for [templateId], if any.
String? answerForTemplate({
  required List<Evidence> recordedEvidence,
  required String templateId,
}) {
  for (final item in recordedEvidence.reversed) {
    if (item.templateId == templateId) {
      return item.answer;
    }
  }
  return null;
}

bool _starterComplaintEstablishesNoHeat(String text) {
  final lowered = text.toLowerCase();
  if (_starterComplaintEstablishesExcessHeat(lowered)) {
    return false;
  }
  return lowered.contains('no heat') ||
      lowered.contains('no warmth') ||
      lowered.contains('cold') ||
      lowered.contains('not warm') ||
      lowered.contains('not heating') ||
      lowered.contains('doesn\'t heat') ||
      lowered.contains('doesnt heat') ||
      lowered.contains('won\'t heat') ||
      lowered.contains('wont heat') ||
      lowered.contains('no hot air');
}

bool _starterComplaintEstablishesExcessHeat(String text) {
  final lowered = text.toLowerCase();
  return lowered.contains('too hot') ||
      lowered.contains('very hot') ||
      lowered.contains('way too hot') ||
      lowered.contains('extra hot') ||
      lowered.contains('overheat') ||
      lowered.contains('overheating') ||
      lowered.contains('overheated') ||
      lowered.contains('burning hot') ||
      lowered.contains('scorching') ||
      lowered.contains('runs hot') ||
      lowered.contains('clothes too hot') ||
      lowered.contains('hot clothes');
}

/// Heat investigation polarity — no-heat and excess-heat are different paths.
enum HeatPathPolarity {
  unknown,
  noHeat,
  excessHeat,
}

/// Whether the session-start complaint already established excess heat.
bool isExcessHeatEstablishedFromStarter({
  required List<Evidence> recordedEvidence,
}) {
  for (final item in recordedEvidence) {
    if (item.templateId != problemStarterComplaintTemplateId) {
      continue;
    }
    // Unmatched Other is evidence only — do not treat the typed note as a
    // too-hot complaint that was never confirmed on a chip.
    if (_isUnmatchedOtherStarterObservation(item.observation)) {
      continue;
    }
    if (_starterComplaintEstablishesExcessHeat(
      item.answer ?? item.observation,
    )) {
      return true;
    }
  }
  return false;
}

/// Current heat-path polarity from starter complaint and recorded answers.
///
/// Overheat *history* plus current no-warmth stays [HeatPathPolarity.noHeat]
/// (fuse-after-overheat). Ongoing too-hot answers are [HeatPathPolarity.excessHeat].
HeatPathPolarity inferHeatPathPolarity({
  required List<Evidence> recordedEvidence,
  Set<String> starterMatchedSymptomIds = const {},
}) {
  var noHeatNow = starterMatchedSymptomIds.contains('no-heat') ||
      isNoHeatEstablishedFromStarter(recordedEvidence: recordedEvidence);
  var excessNow = starterMatchedSymptomIds.contains('dryer-very-hot') ||
      isExcessHeatEstablishedFromStarter(recordedEvidence: recordedEvidence);

  for (final item in recordedEvidence) {
    final templateId = item.templateId;
    final answer = normalizeObservationAnswer(item.answer);
    if (templateId == 'heat-observed' && answer == 'No warmth') {
      noHeatNow = true;
    }
    if (templateId == 'heat-pattern' && answer == 'No heat') {
      noHeatNow = true;
    }
    if (templateId == 'clothes-feel-after-cycle' &&
        answer == 'Cold and still damp') {
      noHeatNow = true;
    }
    if (templateId == 'heat-observed' && answer == 'Very hot') {
      excessNow = true;
    }
    if (templateId == 'heat-pattern' && answer == 'Too hot / overheating') {
      excessNow = true;
    }
    if (templateId == 'clothes-feel-after-cycle' &&
        isClothesFeelExcessHeatAnswer(answer)) {
      excessNow = true;
    }
    if (templateId == 'recent-overheat' && answer == recentOverheatYesAnswer) {
      excessNow = true;
    }
  }

  if (noHeatNow && excessNow) {
    // Current cold wins: overheat then no heat is the fuse path.
    for (final item in recordedEvidence.reversed) {
      final templateId = item.templateId;
      final answer = normalizeObservationAnswer(item.answer);
      if (templateId == 'heat-observed' && answer == 'Very hot') {
        return HeatPathPolarity.excessHeat;
      }
      if (templateId == 'heat-observed' && answer == 'No warmth') {
        return HeatPathPolarity.noHeat;
      }
      if (templateId == 'clothes-feel-after-cycle' &&
          answer == 'Cold and still damp') {
        return HeatPathPolarity.noHeat;
      }
      if (templateId == 'clothes-feel-after-cycle' &&
          isClothesFeelExcessHeatAnswer(answer)) {
        return HeatPathPolarity.excessHeat;
      }
    }
    if (isNoHeatEstablishedFromStarter(recordedEvidence: recordedEvidence) ||
        starterMatchedSymptomIds.contains('no-heat')) {
      return HeatPathPolarity.noHeat;
    }
    return HeatPathPolarity.excessHeat;
  }
  if (noHeatNow) {
    return HeatPathPolarity.noHeat;
  }
  if (excessNow) {
    return HeatPathPolarity.excessHeat;
  }
  return HeatPathPolarity.unknown;
}

bool isExcessHeatPolarity({
  required List<Evidence> recordedEvidence,
  Set<String> starterMatchedSymptomIds = const {},
}) {
  return inferHeatPathPolarity(
        recordedEvidence: recordedEvidence,
        starterMatchedSymptomIds: starterMatchedSymptomIds,
      ) ==
      HeatPathPolarity.excessHeat;
}

/// Whether the session-start complaint already established no heat.
bool isNoHeatEstablishedFromStarter({
  required List<Evidence> recordedEvidence,
}) {
  for (final item in recordedEvidence) {
    if (item.templateId != problemStarterComplaintTemplateId) {
      continue;
    }
    // Unmatched Other is evidence only — do not treat the typed note as a
    // warmth answer that was never shown.
    if (_isUnmatchedOtherStarterObservation(item.observation)) {
      continue;
    }
    if (_starterComplaintEstablishesNoHeat(
      item.answer ?? item.observation,
    )) {
      return true;
    }
  }
  return false;
}

bool _isUnmatchedOtherStarterObservation(String? observation) {
  return observation?.trim().toLowerCase() == 'other / free-text';
}

/// Whether interview evidence already establishes a no-heat / no-warmth pattern.
bool isNoHeatEstablished({
  required List<Evidence> recordedEvidence,
  required List<EvidenceTemplate> templates,
}) {
  if (isNoHeatEstablishedFromStarter(recordedEvidence: recordedEvidence)) {
    return true;
  }
  for (final item in recordedEvidence) {
    final templateId = item.templateId;
    final answer = normalizeObservationAnswer(item.answer);
    if (templateId == 'heat-observed' && answer == 'No warmth') {
      return true;
    }
    if (templateId == 'heat-pattern' && answer == 'No heat') {
      return true;
    }
    if (templateId == 'clothes-feel-after-cycle' &&
        answer == 'Cold and still damp') {
      return true;
    }
  }
  return false;
}

/// Templates that only re-confirm no heat once [isNoHeatEstablished] is true.
const Set<String> redundantNoHeatConfirmationTemplateIds = {
  'heat-observed',
};

/// Templates that only re-confirm excess heat once polarity is excess-heat.
const Set<String> redundantExcessHeatConfirmationTemplateIds = {
  'heat-observed',
  'recent-overheat',
};

/// Whether [templateId] is a pure warmth re-ask that should stay unscheduled.
bool isRedundantNoHeatConfirmation({
  required String templateId,
  required List<Evidence> recordedEvidence,
  required List<EvidenceTemplate> templates,
}) {
  return shouldSuppressObservationForHeatPolarity(
    templateId: templateId,
    recordedEvidence: recordedEvidence,
    templates: templates,
  );
}

/// Suppress polarity-wrong or already-established heat re-asks.
bool shouldSuppressObservationForHeatPolarity({
  required String templateId,
  required List<Evidence> recordedEvidence,
  required List<EvidenceTemplate> templates,
  Set<String> starterMatchedSymptomIds = const {},
}) {
  if (isTemplateRecordedById(
    templateId: templateId,
    recordedEvidence: recordedEvidence,
  )) {
    return false;
  }
  final polarity = inferHeatPathPolarity(
    recordedEvidence: recordedEvidence,
    starterMatchedSymptomIds: starterMatchedSymptomIds,
  );
  if (polarity == HeatPathPolarity.excessHeat) {
    return redundantExcessHeatConfirmationTemplateIds.contains(templateId);
  }
  if (polarity == HeatPathPolarity.noHeat) {
    return redundantNoHeatConfirmationTemplateIds.contains(templateId);
  }
  return false;
}

bool isTemplateRecordedById({
  required String templateId,
  required List<Evidence> recordedEvidence,
}) {
  for (final item in recordedEvidence) {
    if (item.templateId == templateId) {
      return true;
    }
  }
  return false;
}

/// Answer label for a recent overheat / shut-off observation (not vent neglect).
const String recentOverheatYesAnswer = 'Yes, very hot or shut off from heat';

/// Clothes-feel chip for excess heat when the load finished dry.
const String clothesFeelDryUnusuallyHotAnswer = 'Dry but unusually hot';

bool isClothesFeelExcessHeatAnswer(String? answer) {
  return answer == 'Warm or hot but still damp' ||
      answer == clothesFeelDryUnusuallyHotAnswer;
}

/// True when [choice] is the engine Other chip or a recorded
/// `Other / describe: {note}` answer. Groq display strings do not match.
bool isOtherDescribeEngineId(String choice) {
  final trimmed = choice.trim();
  return trimmed == kOtherDescribeChoiceId ||
      trimmed.startsWith(kOtherDescribeChoiceId);
}

/// Recorded answer for the Other chip. Typed text is the note only —
/// Groq must not remap it onto a different chip id.
String recordedOtherDescribeAnswer(String? note) {
  final trimmed = note?.trim() ?? '';
  return trimmed.isEmpty
      ? kOtherDescribeChoiceId
      : '$kOtherDescribeChoiceId: $trimmed';
}

/// Base answer choice used for package effect lookup.
String? normalizeObservationAnswer(String? answer) {
  if (answer == null) {
    return null;
  }
  final trimmed = answer.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final separator = trimmed.indexOf(':');
  if (separator <= 0) {
    return trimmed;
  }
  return trimmed.substring(0, separator).trim();
}
