import '../knowledge_factory/failure_mode_authoring_record.dart';
import '../models/knowledge_package.dart';
import 'observation_prompt_quality.dart';

/// Runtime view of package authoring data for ranking and interview.
///
/// Built deterministically from merged [KnowledgePackage] templates and
/// optional Knowledge Factory records. Modes without authoring metadata
/// degrade gracefully (empty family/support sets).
class PackageAuthoringIndex {
  PackageAuthoringIndex._({
    required Map<String, Set<ObservationFamily>> familiesByModeId,
    required Map<String, Set<String>> supportTemplatesByModeId,
    required Map<String, Set<String>> excludeTemplatesByModeId,
    required Map<String, Set<String>> firstLineTemplatesByModeId,
    required List<({String phrasing, Set<ObservationFamily> families})>
    symptomPhrasingHints,
  }) : _familiesByModeId = familiesByModeId,
       _supportTemplatesByModeId = supportTemplatesByModeId,
       _excludeTemplatesByModeId = excludeTemplatesByModeId,
       _firstLineTemplatesByModeId = firstLineTemplatesByModeId,
       _symptomPhrasingHints = symptomPhrasingHints;

  final Map<String, Set<ObservationFamily>> _familiesByModeId;
  final Map<String, Set<String>> _supportTemplatesByModeId;
  final Map<String, Set<String>> _excludeTemplatesByModeId;
  final Map<String, Set<String>> _firstLineTemplatesByModeId;
  final List<({String phrasing, Set<ObservationFamily> families})>
  _symptomPhrasingHints;

  /// Builds an index from merged package templates.
  factory PackageAuthoringIndex.fromPackage(
    KnowledgePackage package, {
    List<FailureModeAuthoringRecord> records = const [],
  }) {
    final familiesByModeId = <String, Set<ObservationFamily>>{
      for (final mode in package.failureModes) mode.id: <ObservationFamily>{},
    };
    final supportTemplatesByModeId = <String, Set<String>>{
      for (final mode in package.failureModes) mode.id: <String>{},
    };
    final excludeTemplatesByModeId = <String, Set<String>>{
      for (final mode in package.failureModes) mode.id: <String>{},
    };
    final firstLineTemplatesByModeId = <String, Set<String>>{
      for (final mode in package.failureModes) mode.id: <String>{},
    };

    for (final template in package.evidenceTemplates) {
      final templateFamilies = metaForTemplate(template.id).families;
      for (final modeId in template.relatedFailureModeIds) {
        if (!familiesByModeId.containsKey(modeId)) {
          continue;
        }
        familiesByModeId[modeId]!.addAll(templateFamilies);
      }
      for (final entry in template.supportByAnswer.entries) {
        for (final modeId in entry.value) {
          supportTemplatesByModeId.putIfAbsent(modeId, () => <String>{});
          supportTemplatesByModeId[modeId]!.add(template.id);
          familiesByModeId.putIfAbsent(modeId, () => <ObservationFamily>{});
          familiesByModeId[modeId]!.addAll(templateFamilies);
        }
      }
      for (final entry in template.excludeByAnswer.entries) {
        for (final modeId in entry.value) {
          excludeTemplatesByModeId.putIfAbsent(modeId, () => <String>{});
          excludeTemplatesByModeId[modeId]!.add(template.id);
        }
      }
    }

    for (final record in records) {
      for (final question in record.firstLineQuestions) {
        firstLineTemplatesByModeId.putIfAbsent(record.id, () => <String>{});
        firstLineTemplatesByModeId[record.id]!.add(question.templateId);
        familiesByModeId.putIfAbsent(record.id, () => <ObservationFamily>{});
        familiesByModeId[record.id]!.addAll(
          metaForTemplate(question.templateId).families,
        );
      }
      for (final hint in record.evidenceSupports) {
        familiesByModeId.putIfAbsent(record.id, () => <ObservationFamily>{});
        familiesByModeId[record.id]!.addAll(
          metaForTemplate(hint.templateId).families,
        );
      }
    }

    final phrasingHints = <({String phrasing, Set<ObservationFamily> families})>[
      for (final record in records)
        for (final phrasing in record.symptomPhrasings)
          (
            phrasing: phrasing.toLowerCase(),
            families: inferFamiliesFromSymptomPhrasing(phrasing),
          ),
    ];

    return PackageAuthoringIndex._(
      familiesByModeId: {
        for (final entry in familiesByModeId.entries)
          entry.key: Set.unmodifiable(entry.value),
      },
      supportTemplatesByModeId: {
        for (final entry in supportTemplatesByModeId.entries)
          entry.key: Set.unmodifiable(entry.value),
      },
      excludeTemplatesByModeId: {
        for (final entry in excludeTemplatesByModeId.entries)
          entry.key: Set.unmodifiable(entry.value),
      },
      firstLineTemplatesByModeId: {
        for (final entry in firstLineTemplatesByModeId.entries)
          entry.key: Set.unmodifiable(entry.value),
      },
      symptomPhrasingHints: phrasingHints,
    );
  }

  Set<ObservationFamily> observationFamiliesFor(String failureModeId) {
    return _familiesByModeId[failureModeId] ?? const {};
  }

  Set<String> supportTemplatesFor(String failureModeId) {
    return _supportTemplatesByModeId[failureModeId] ?? const {};
  }

  Set<String> excludeTemplatesFor(String failureModeId) {
    return _excludeTemplatesByModeId[failureModeId] ?? const {};
  }

  Set<String> firstLineTemplatesFor(String failureModeId) {
    return _firstLineTemplatesByModeId[failureModeId] ?? const {};
  }

  /// Matches Batch 01 symptom phrasings against free-text complaint text.
  Set<ObservationFamily> familiesMatchingComplaint(String complaintText) {
    final lower = complaintText.toLowerCase();
    final matched = <ObservationFamily>{};
    for (final hint in _symptomPhrasingHints) {
      if (lower.contains(hint.phrasing) || hint.phrasing.contains(lower.trim())) {
        matched.addAll(hint.families);
      }
    }
    return matched;
  }

  int familyOverlapScore(
    String failureModeId,
    Set<ObservationFamily> activeFamilies,
  ) {
    if (activeFamilies.isEmpty) {
      return 0;
    }
    return observationFamiliesFor(failureModeId)
        .intersection(activeFamilies)
        .length;
  }
}

/// Keyword families for Batch 01 symptom phrasings (deterministic, no LLM).
Set<ObservationFamily> inferFamiliesFromSymptomPhrasing(String phrasing) {
  final lower = phrasing.toLowerCase();
  final families = <ObservationFamily>{};

  if (lower.contains('heat') ||
      lower.contains('cold') ||
      lower.contains('warm') ||
      lower.contains('overheat') ||
      lower.contains('fluff') ||
      lower.contains('air only')) {
    families.add(ObservationFamily.heat);
  }
  if (lower.contains('vent') ||
      lower.contains('airflow') ||
      lower.contains('damp') ||
      lower.contains('dry time') ||
      lower.contains('lint') ||
      lower.contains('clog')) {
    families.add(ObservationFamily.airflow);
  }
  if (lower.contains('drum') ||
      lower.contains('belt') ||
      lower.contains('turn') ||
      lower.contains('motor')) {
    families.add(ObservationFamily.drum);
  }
  if (lower.contains('start') ||
      lower.contains("won't") ||
      lower.contains('lock') ||
      lower.contains('power') ||
      lower.contains('plug')) {
    families.add(ObservationFamily.start);
  }
  if (lower.contains('noise') ||
      lower.contains('squeal') ||
      lower.contains('thump') ||
      lower.contains('rattle')) {
    families.add(ObservationFamily.noise);
  }
  if (lower.contains('smell') ||
      lower.contains('odor') ||
      lower.contains('burn') ||
      lower.contains('smoke')) {
    families.addAll({ObservationFamily.smell, ObservationFamily.hazard});
  }

  if (families.isEmpty) {
    families.add(ObservationFamily.start);
  }
  return families;
}
