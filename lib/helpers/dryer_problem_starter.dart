import '../models/knowledge_package.dart';
import 'hazard_language.dart';

/// Template id for the seeded starting-complaint evidence row.
const String problemStarterComplaintTemplateId = 'problem-starter-complaint';

/// Special entry choice — opens free-text describe flow (not a symptom family).
const String dryerStarterOtherDescribeId = 'other-describe';

/// Primary chip that covers unusual noise. Burning smell is a separate safety chip.
const String dryerStarterNoiseOrSmellId = 'noise-or-smell';

/// One deterministic dryer starter family (maps to package [Symptom] ids where possible).
class DryerStarterFamily {
  const DryerStarterFamily({
    required this.id,
    required this.label,
    required this.chipLabel,
    required this.firstTemplateId,
    required this.keywords,
    required this.priority,
  });

  /// Stable id — prefers package symptom ids.
  final String id;
  final String label;
  final String chipLabel;

  /// Evidence template to open first after confirmation.
  final String firstTemplateId;

  /// Lowercase substring keywords for free-text mapping (no LLM).
  final List<String> keywords;

  /// Lower number = higher priority when several families match.
  final int priority;
}

/// Result of chip + keyword interpretation before the interview starts.
class DryerStarterResolution {
  const DryerStarterResolution({
    required this.matchedSymptomIds,
    required this.labels,
    required this.firstTemplateId,
    this.unmatchedFreeText = false,
  });

  final List<String> matchedSymptomIds;
  final List<String> labels;
  final String firstTemplateId;
  final bool unmatchedFreeText;

  bool get hasMatch => matchedSymptomIds.isNotEmpty;

  bool get isHazard => matchedSymptomIds.contains('hazard-signs');
}

/// Primary entry choices shown on “What’s going on?” (order = display order).
const List<String> dryerStarterEntryChoiceIds = [
  'no-heat',
  'long-dry-time',
  'will-not-start',
  'motor-runs-drum-still',
  'dryer-very-hot',
  dryerStarterNoiseOrSmellId,
  'hazard-signs',
  dryerStarterOtherDescribeId,
];

/// Clarification list after unmatched Other text (includes safety path).
const List<String> dryerStarterClarifyChoiceIds = [
  'no-heat',
  'long-dry-time',
  'will-not-start',
  'motor-runs-drum-still',
  'dryer-very-hot',
  dryerStarterNoiseOrSmellId,
  'hazard-signs',
];

/// Dryer MVP starter families — chips + keyword synonyms only.
const List<DryerStarterFamily> dryerStarterFamilies = [
  DryerStarterFamily(
    id: 'hazard-signs',
    label: 'Burning smell, smoke, or sparks',
    chipLabel: 'Burning smell / smoke',
    firstTemplateId: 'hazard-observation',
    keywords: kSharedHazardLanguageMarkers,
    priority: 0,
  ),
  DryerStarterFamily(
    id: 'no-heat',
    label: 'No heat',
    chipLabel: 'No heat',
    firstTemplateId: 'cycle-heat-setting',
    keywords: [
      'no heat',
      'not heating',
      'won\'t heat',
      'wont heat',
      'doesn\'t heat',
      'doesnt heat',
      'no warmth',
      'not warm',
      'cold clothes',
      'clothes cold',
      'no hot air',
      'weak heat',
      'little heat',
      'not much heat',
    ],
    priority: 1,
  ),
  DryerStarterFamily(
    id: 'will-not-start',
    label: 'Will not start',
    chipLabel: 'Won\'t start',
    firstTemplateId: 'dryer-response',
    keywords: [
      'won\'t start',
      'wont start',
      'will not start',
      'doesn\'t start',
      'doesnt start',
      'nothing happens',
      'no power',
      'dead',
      'won\'t turn on',
      'wont turn on',
    ],
    priority: 2,
  ),
  DryerStarterFamily(
    id: 'motor-runs-drum-still',
    label: 'Drum does not turn',
    chipLabel: 'Drum doesn\'t turn',
    firstTemplateId: 'drum-turns',
    keywords: [
      'drum doesn\'t turn',
      'drum doesnt turn',
      'drum won\'t turn',
      'drum wont turn',
      'drum not turning',
      'belt',
      'motor runs',
      'hums but',
    ],
    priority: 3,
  ),
  DryerStarterFamily(
    id: 'long-dry-time',
    label: 'Long dry time',
    chipLabel: 'Takes too long to dry',
    firstTemplateId: 'lint-filter-condition',
    keywords: [
      'long dry',
      'takes forever',
      'takes too long',
      'longer than usual',
      'still wet',
      'won\'t dry',
      'wont dry',
      'not drying',
    ],
    priority: 4,
  ),
  DryerStarterFamily(
    id: 'clothes-hot-but-damp',
    label: 'Clothes hot but damp',
    chipLabel: 'Hot but damp',
    firstTemplateId: 'clothes-feel-after-cycle',
    keywords: [
      'hot but damp',
      'hot and damp',
      'hot but wet',
      'warm but wet',
      'clothes damp',
    ],
    priority: 5,
  ),
  DryerStarterFamily(
    id: 'weak-exterior-airflow',
    label: 'Weak exterior airflow',
    chipLabel: 'Weak vent airflow',
    firstTemplateId: 'exterior-airflow',
    keywords: [
      'weak airflow',
      'no airflow',
      'poor airflow',
      'vent blocked',
      'clogged vent',
    ],
    priority: 6,
  ),
  DryerStarterFamily(
    id: 'squealing-or-thumping',
    label: 'Unusual noise',
    chipLabel: 'Unusual noise',
    firstTemplateId: 'running-noise',
    keywords: [
      'squeal',
      'squealing',
      'thump',
      'thumping',
      'grinding',
      'loud noise',
      'noisy',
      'screech',
      'unusual noise',
      'strange noise',
    ],
    priority: 7,
  ),
  DryerStarterFamily(
    id: 'dryer-very-hot',
    label: 'Dryer becomes very hot',
    chipLabel: 'Too hot or overheating',
    firstTemplateId: 'lint-filter-condition',
    keywords: [
      'too hot',
      'very hot',
      'way too hot',
      'extra hot',
      'overheat',
      'overheating',
      'overheated',
      'burning hot',
      'scorching',
      'runs hot',
      'clothes too hot',
      'hot clothes',
    ],
    priority: 8,
  ),
];

/// Default first question when the user skips the starter.
const String dryerStarterDefaultTemplateId = 'dryer-response';

DryerStarterFamily? dryerStarterFamilyById(String id) {
  for (final family in dryerStarterFamilies) {
    if (family.id == id) {
      return family;
    }
  }
  return null;
}

String dryerStarterEntryChipLabel(String id) {
  switch (id) {
    case dryerStarterOtherDescribeId:
      return 'Other';
    case 'no-heat':
      return 'No heat';
    case 'dryer-very-hot':
      return 'Too hot or overheating';
    case 'will-not-start':
      return "Won't start";
    case 'long-dry-time':
      return 'Takes too long to dry';
    case 'motor-runs-drum-still':
      return "Drum doesn't turn";
    case dryerStarterNoiseOrSmellId:
      return 'Unusual noise';
    case 'hazard-signs':
      return 'Burning smell / smoke';
    default:
      return dryerStarterFamilyById(id)?.chipLabel ?? id;
  }
}

/// Maps picker chips onto family ids used by polarity and first questions.
Set<String> canonicalizeStarterSelection(Set<String> selectedSymptomIds) {
  final mapped = <String>{};
  for (final id in selectedSymptomIds) {
    if (id == dryerStarterOtherDescribeId) {
      continue;
    }
    if (id == dryerStarterNoiseOrSmellId) {
      mapped.add('squealing-or-thumping');
    } else {
      mapped.add(id);
    }
  }
  return mapped;
}

/// Maps selected chip ids + optional free text to starter families (deterministic).
DryerStarterResolution resolveDryerStarter({
  required Set<String> selectedSymptomIds,
  String freeText = '',
}) {
  final matched = <String>{
    ...canonicalizeStarterSelection(selectedSymptomIds),
  };
  final trimmed = freeText.trim();
  var unmatchedFreeText = false;

  if (trimmed.isNotEmpty) {
    final lowered = trimmed
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('‘', "'");
    var anyKeyword = false;
    for (final family in dryerStarterFamilies) {
      if (family.id == 'hazard-signs') {
        // Shared lexicon (incl. bare burning / “burning smell”), not a
        // first-keyword-only scan of the concatenated list.
        if (textSuggestsHazard(trimmed)) {
          matched.add(family.id);
          anyKeyword = true;
        }
        continue;
      }
      for (final keyword in family.keywords) {
        if (lowered.contains(keyword)) {
          matched.add(family.id);
          anyKeyword = true;
          break;
        }
      }
    }
    unmatchedFreeText = !anyKeyword;
  }

  if (matched.isEmpty) {
    return DryerStarterResolution(
      matchedSymptomIds: const [],
      labels: const [],
      firstTemplateId: dryerStarterDefaultTemplateId,
      unmatchedFreeText: trimmed.isNotEmpty,
    );
  }

  final families =
      matched
          .map(dryerStarterFamilyById)
          .whereType<DryerStarterFamily>()
          .toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));

  return DryerStarterResolution(
    matchedSymptomIds: families.map((f) => f.id).toList(growable: false),
    labels: families.map((f) => f.label).toList(growable: false),
    firstTemplateId: families.first.firstTemplateId,
    unmatchedFreeText: unmatchedFreeText,
  );
}

/// Evidence answer text for the seeded starting complaint (never a diagnosis).
String buildStarterComplaintAnswer({
  required DryerStarterResolution resolution,
  String freeText = '',
}) {
  final parts = <String>[...resolution.labels];
  final trimmed = freeText.trim();
  if (trimmed.isNotEmpty) {
    parts.add(trimmed);
  }
  var answer = parts.join(' — ');
  if (resolution.isHazard) {
    final lowered = answer.toLowerCase();
    if (!textSuggestsHazard(lowered)) {
      answer = answer.isEmpty
          ? 'Burning smell / smoke'
          : '$answer — burning smell / smoke';
    }
  }
  return answer;
}

/// Picks the template for a confirmed starter, falling back to package order.
EvidenceTemplate? starterFirstTemplate({
  required List<EvidenceTemplate> templates,
  required String firstTemplateId,
}) {
  for (final template in templates) {
    if (template.id == firstTemplateId) {
      return template;
    }
  }
  for (final template in templates) {
    if (template.id == dryerStarterDefaultTemplateId) {
      return template;
    }
  }
  return templates.isEmpty ? null : templates.first;
}
