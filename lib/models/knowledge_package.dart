import 'evidence.dart';
import 'inspect_step.dart';

/// Qualitative frequency label supplied by package authors.
///
/// This is package data only and is not a probability or confidence formula.
enum FailureModeCommonality {
  veryHigh,
  high,
  common,
  moderate,
}

/// Publication state supplied as package metadata.
enum KnowledgePackageStatus {
  production,
  staging,
  deprecated,
}

/// A known way an appliance can fail.
class FailureMode {
  const FailureMode({
    required this.id,
    required this.label,
    required this.description,
    required this.commonality,
    required this.safetyNotes,
  });

  final String id;
  final String label;
  final String description;
  final FailureModeCommonality commonality;
  final String safetyNotes;

  FailureMode copyWith({FailureModeCommonality? commonality}) {
    return FailureMode(
      id: id,
      label: label,
      description: description,
      commonality: commonality ?? this.commonality,
      safetyNotes: safetyNotes,
    );
  }
}

/// An observable appliance behavior or condition.
class Symptom {
  const Symptom({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

/// A package-authored prompt for collecting an observation.
///
/// The prompt asks what the user can observe; it does not ask the user to
/// diagnose a failure.
///
/// Optional [supportByAnswer] / [excludeByAnswer] map answer labels to failure
/// mode ids. These are deterministic package metadata, not probabilities.
///
/// Optional [answerChoices] overrides the default Yes/No-style choices when
/// non-empty. Ranking maps must use the same answer label strings.
class EvidenceTemplate {
  EvidenceTemplate({
    required this.id,
    required this.promptText,
    required this.expectedEvidenceType,
    required List<String> relatedFailureModeIds,
    List<String> answerChoices = const [],
    Map<String, List<String>> supportByAnswer = const {},
    Map<String, List<String>> excludeByAnswer = const {},
  }) : relatedFailureModeIds = List.unmodifiable(relatedFailureModeIds),
       answerChoices = List.unmodifiable(answerChoices),
       supportByAnswer = _freezeAnswerMap(supportByAnswer),
       excludeByAnswer = _freezeAnswerMap(excludeByAnswer);

  final String id;
  final String promptText;
  final EvidenceType expectedEvidenceType;
  final List<String> relatedFailureModeIds;

  /// Package-authored answer labels. Empty → UI uses the default set.
  final List<String> answerChoices;
  final Map<String, List<String>> supportByAnswer;
  final Map<String, List<String>> excludeByAnswer;
}

Map<String, List<String>> _freezeAnswerMap(Map<String, List<String>> source) {
  return Map.unmodifiable({
    for (final entry in source.entries)
      entry.key: List<String>.unmodifiable(entry.value),
  });
}

/// A safely worded check stored as package data.
///
/// Applying safety policy remains the responsibility of a later Safety Engine.
class SafeCheck {
  SafeCheck({
    required this.id,
    required this.label,
    required this.description,
    required List<String> requiredTools,
    required this.safetyLevel,
  }) : requiredTools = List.unmodifiable(requiredTools);

  final String id;
  final String label;
  final String description;
  final List<String> requiredTools;
  final String safetyLevel;
}

/// Immutable, versioned appliance engineering knowledge package.
///
/// This model is data only. It performs no diagnosis, ranking, traversal,
/// question selection, confidence calculation, or safety decision.
class KnowledgePackage {
  KnowledgePackage({
    required this.id,
    required this.category,
    required this.version,
    required this.displayName,
    required this.schemaVersion,
    required List<FailureMode> failureModes,
    required List<Symptom> symptoms,
    required List<EvidenceTemplate> evidenceTemplates,
    required List<SafeCheck> safeChecks,
    required this.createdAt,
    required this.source,
    required this.status,
    List<InspectStep> inspectSteps = const [],
  })  : failureModes = List.unmodifiable(failureModes),
        symptoms = List.unmodifiable(symptoms),
        evidenceTemplates = List.unmodifiable(evidenceTemplates),
        safeChecks = List.unmodifiable(safeChecks),
        inspectSteps = List.unmodifiable(inspectSteps);

  final String id;
  final String category;
  final String version;
  final String displayName;
  final String schemaVersion;
  final List<FailureMode> failureModes;
  final List<Symptom> symptoms;
  final List<EvidenceTemplate> evidenceTemplates;
  final List<SafeCheck> safeChecks;
  final List<InspectStep> inspectSteps;
  final DateTime createdAt;
  final String source;
  final KnowledgePackageStatus status;

  KnowledgePackage withFailureModes(List<FailureMode> failureModes) {
    return KnowledgePackage(
      id: id,
      category: category,
      version: version,
      displayName: displayName,
      schemaVersion: schemaVersion,
      failureModes: failureModes,
      symptoms: symptoms,
      evidenceTemplates: evidenceTemplates,
      safeChecks: safeChecks,
      inspectSteps: inspectSteps,
      createdAt: createdAt,
      source: source,
      status: status,
    );
  }
}
