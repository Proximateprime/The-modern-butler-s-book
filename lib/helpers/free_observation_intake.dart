import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'dryer_problem_starter.dart';
import 'evidence_prompt_match.dart';

/// Template id for optional free-text notes. Not a ranked observation.
const String freeObservationNoteTemplateId = 'free-observation-note';

bool isFreeObservationNote(Evidence evidence) {
  return evidence.templateId == freeObservationNoteTemplateId;
}

/// Light keyword suggestion to also record a known observation. No LLM.
class FreeObservationSuggestion {
  const FreeObservationSuggestion({
    required this.templateId,
    required this.suggestedAnswer,
    required this.chipLabel,
  });

  final String templateId;
  final String suggestedAnswer;
  final String chipLabel;

  String get keySuffix =>
      '${templateId}_${suggestedAnswer.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';
}

/// Deterministic substring / family-keyword matches. Does not diagnose.
List<FreeObservationSuggestion> suggestFreeObservationMarks({
  required String note,
  required List<EvidenceTemplate> templates,
  required List<Evidence> recordedEvidence,
  HeatPathPolarity? polarity,
}) {
  final lowered = note
      .trim()
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll('‘', "'");
  if (lowered.isEmpty) {
    return const [];
  }

  final recordedIds = {
    for (final item in recordedEvidence)
      if (item.templateId != null &&
          item.templateId != freeObservationNoteTemplateId)
        item.templateId!,
  };
  final byId = {for (final template in templates) template.id: template};
  final found = <String, FreeObservationSuggestion>{};

  void consider(String templateId, String answer, String chipLabel) {
    if (recordedIds.contains(templateId)) {
      return;
    }
    final template = byId[templateId];
    if (template == null) {
      return;
    }
    if (!answerChoicesFor(template).contains(answer)) {
      return;
    }
    if (_wouldFlipEstablishedPolarity(
      polarity: polarity,
      templateId: templateId,
      answer: answer,
    )) {
      return;
    }
    found.putIfAbsent(
      '$templateId::$answer',
      () => FreeObservationSuggestion(
        templateId: templateId,
        suggestedAnswer: answer,
        chipLabel: chipLabel,
      ),
    );
  }

  for (final template in templates) {
    for (final choice in answerChoicesFor(template)) {
      if (_skipChoice(choice, templateId: template.id)) {
        continue;
      }
      if (_noteContainsChoice(lowered, choice)) {
        consider(
          template.id,
          choice,
          'Also mark: ${observationPromptTitle(template)} — $choice',
        );
      }
    }
  }

  for (final family in dryerStarterFamilies) {
    var hit = false;
    for (final keyword in family.keywords) {
      if (lowered.contains(keyword)) {
        hit = true;
        break;
      }
    }
    if (!hit) {
      continue;
    }
    final mapped = _familySuggestedAnswer(family.id, lowered);
    if (mapped == null) {
      continue;
    }
    consider(
      mapped.templateId,
      mapped.answer,
      'Also mark: ${family.chipLabel}',
    );
  }

  final list = found.values.toList();
  list.sort((a, b) => a.chipLabel.length.compareTo(b.chipLabel.length));
  if (list.length <= 3) {
    return List<FreeObservationSuggestion>.unmodifiable(list);
  }
  return List<FreeObservationSuggestion>.unmodifiable(list.take(3));
}

bool _skipChoice(String choice, {required String templateId}) {
  final lower = choice.toLowerCase();
  if (lower == 'not sure' ||
      lower.startsWith('other') ||
      lower == 'sometimes' ||
      lower == 'no unusual sound') {
    return true;
  }
  if (lower == 'yes' || lower == 'no') {
    return templateId != 'hazard-observation';
  }
  return lower.length < 3;
}

bool _noteContainsChoice(String loweredNote, String choice) {
  final needle = choice.toLowerCase().trim();
  if (needle.length < 3) {
    return false;
  }
  if (needle.contains(' ')) {
    return loweredNote.contains(needle);
  }
  return RegExp('\\b${RegExp.escape(needle)}\\b').hasMatch(loweredNote);
}

({String templateId, String answer})? _familySuggestedAnswer(
  String familyId,
  String loweredNote,
) {
  return switch (familyId) {
    'no-heat' => (templateId: 'heat-observed', answer: 'No warmth'),
    'dryer-very-hot' => (templateId: 'heat-observed', answer: 'Very hot'),
    'hazard-signs' => (templateId: 'hazard-observation', answer: 'Yes'),
    'will-not-start' => (templateId: 'dryer-response', answer: 'Nothing happens'),
    'squealing-or-thumping' =>
      loweredNote.contains('thump')
          ? (templateId: 'running-noise', answer: 'Thump')
          : (templateId: 'running-noise', answer: 'Squeal'),
    _ => null,
  };
}

bool _wouldFlipEstablishedPolarity({
  required HeatPathPolarity? polarity,
  required String templateId,
  required String answer,
}) {
  if (polarity == null || polarity == HeatPathPolarity.unknown) {
    return false;
  }
  final normalized = normalizeObservationAnswer(answer);
  final isNoHeatMark =
      (templateId == 'heat-observed' && normalized == 'No warmth') ||
      (templateId == 'heat-pattern' && normalized == 'No heat') ||
      (templateId == 'clothes-feel-after-cycle' &&
          normalized == 'Cold and still damp');
  final isExcessMark =
      (templateId == 'heat-observed' && normalized == 'Very hot') ||
      (templateId == 'heat-pattern' && normalized == 'Too hot / overheating') ||
      (templateId == 'clothes-feel-after-cycle' &&
          isClothesFeelExcessHeatAnswer(normalized));
  if (polarity == HeatPathPolarity.noHeat && isExcessMark) {
    return true;
  }
  if (polarity == HeatPathPolarity.excessHeat && isNoHeatMark) {
    return true;
  }
  return false;
}
