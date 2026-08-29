import '../helpers/expert_mode.dart';
import '../helpers/parts_cost.dart';
import '../helpers/visual_guide.dart';
import '../models/evidence.dart';
import '../models/knowledge_package.dart';

/// Canonical Knowledge Factory authoring record for one failure mode.
///
/// This is package-authoring data only — not a runtime diagnosis engine.
/// Ranking still consumes support/exclude maps on [EvidenceTemplate]s after import.
class FailureModeAuthoringRecord {
  FailureModeAuthoringRecord({
    required this.id,
    required this.title,
    required this.applianceFamily,
    required List<String> symptomPhrasings,
    required this.immediateCause,
    required this.rootCause,
    required List<String> contributingFactors,
    required List<EvidenceAnswerHint> evidenceSupports,
    required List<EvidenceAnswerHint> evidenceExcludes,
    required List<String> commonMisdiagnoses,
    required List<FirstLineObservation> firstLineQuestions,
    required this.verificationAsk,
    required this.verificationWhy,
    required List<String> verificationSteps,
    required List<String> safeGuidanceBoundary,
    required List<String> stopProfessionalConditions,
    required List<String> preventionActions,
    required List<String> toolsRequired,
    required this.difficultyNotes,
    required this.commonality,
    required this.safetyNotes,
    this.schemaVersion = '1.0',
    this.allowResolvedWhenConfirmed = true,
    this.preferProfessionalWhenNotConfirmed = true,
    List<VisualGuideAnchor> visualGuides = const [],
    List<PartCostEstimate> partsEstimates = const [],
    List<String> expertOkSteps = const [],
  }) : symptomPhrasings = List.unmodifiable(symptomPhrasings),
       contributingFactors = List.unmodifiable(contributingFactors),
       evidenceSupports = List.unmodifiable(evidenceSupports),
       evidenceExcludes = List.unmodifiable(evidenceExcludes),
       commonMisdiagnoses = List.unmodifiable(commonMisdiagnoses),
       firstLineQuestions = List.unmodifiable(firstLineQuestions),
       verificationSteps = List.unmodifiable(verificationSteps),
       safeGuidanceBoundary = List.unmodifiable(safeGuidanceBoundary),
       stopProfessionalConditions = List.unmodifiable(
         stopProfessionalConditions,
       ),
       preventionActions = List.unmodifiable(preventionActions),
       toolsRequired = List.unmodifiable(toolsRequired),
       visualGuides = List.unmodifiable(visualGuides),
       partsEstimates = List.unmodifiable(partsEstimates),
       expertOkSteps = List.unmodifiable(expertOkSteps);

  /// Stable slug / failure mode id (e.g. `thermal-fuse-open`).
  final String id;
  final String title;
  final String applianceFamily;
  final List<String> symptomPhrasings;
  final String immediateCause;
  final String rootCause;
  final List<String> contributingFactors;
  final List<EvidenceAnswerHint> evidenceSupports;
  final List<EvidenceAnswerHint> evidenceExcludes;
  final List<String> commonMisdiagnoses;
  final List<FirstLineObservation> firstLineQuestions;
  final String verificationAsk;
  final String verificationWhy;
  final List<String> verificationSteps;
  final List<String> safeGuidanceBoundary;
  final List<String> stopProfessionalConditions;
  final List<String> preventionActions;
  final List<String> toolsRequired;
  final String difficultyNotes;
  final String commonality;
  final String safetyNotes;
  final String schemaVersion;
  final bool allowResolvedWhenConfirmed;
  final bool preferProfessionalWhenNotConfirmed;
  final List<VisualGuideAnchor> visualGuides;
  final List<PartCostEstimate> partsEstimates;
  final List<String> expertOkSteps;

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'id': id,
      'title': title,
      'applianceFamily': applianceFamily,
      'symptomPhrasings': symptomPhrasings,
      'immediateCause': immediateCause,
      'rootCause': rootCause,
      'contributingFactors': contributingFactors,
      'evidenceSupports': evidenceSupports.map((e) => e.toJson()).toList(),
      'evidenceExcludes': evidenceExcludes.map((e) => e.toJson()).toList(),
      'commonMisdiagnoses': commonMisdiagnoses,
      'firstLineQuestions': firstLineQuestions.map((e) => e.toJson()).toList(),
      'verificationAsk': verificationAsk,
      'verificationWhy': verificationWhy,
      'verificationSteps': verificationSteps,
      'safeGuidanceBoundary': safeGuidanceBoundary,
      if (expertOkSteps.isNotEmpty) 'expertOkSteps': expertOkSteps,
      'stopProfessionalConditions': stopProfessionalConditions,
      'preventionActions': preventionActions,
      'toolsRequired': toolsRequired,
      'difficultyNotes': difficultyNotes,
      'commonality': commonality,
      'safetyNotes': safetyNotes,
      'allowResolvedWhenConfirmed': allowResolvedWhenConfirmed,
      'preferProfessionalWhenNotConfirmed': preferProfessionalWhenNotConfirmed,
      if (visualGuides.isNotEmpty)
        'visualGuides': visualGuides.map(visualGuideAnchorToJson).toList(),
      if (partsEstimates.isNotEmpty)
        'partsEstimates': partsEstimates.map((part) => part.toJson()).toList(),
    };
  }

  factory FailureModeAuthoringRecord.fromJson(Map<String, dynamic> json) {
    return FailureModeAuthoringRecord(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0',
      id: json['id'] as String,
      title: json['title'] as String,
      applianceFamily: json['applianceFamily'] as String,
      symptomPhrasings: List<String>.from(
        json['symptomPhrasings'] as List? ?? const [],
      ),
      immediateCause: json['immediateCause'] as String? ?? '',
      rootCause: json['rootCause'] as String? ?? '',
      contributingFactors: List<String>.from(
        json['contributingFactors'] as List? ?? const [],
      ),
      evidenceSupports: List<dynamic>.from(
        json['evidenceSupports'] as List? ?? const [],
      )
          .map(
            (item) => EvidenceAnswerHint.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      evidenceExcludes: List<dynamic>.from(
        json['evidenceExcludes'] as List? ?? const [],
      )
          .map(
            (item) => EvidenceAnswerHint.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      commonMisdiagnoses: List<String>.from(
        json['commonMisdiagnoses'] as List? ?? const [],
      ),
      firstLineQuestions: List<dynamic>.from(
        json['firstLineQuestions'] as List? ?? const [],
      )
          .map(
            (item) => FirstLineObservation.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      verificationAsk: json['verificationAsk'] as String? ?? '',
      verificationWhy: json['verificationWhy'] as String? ?? '',
      verificationSteps: List<String>.from(
        json['verificationSteps'] as List? ?? const [],
      ),
      safeGuidanceBoundary: splitGuidanceSteps(
        json['safeGuidanceBoundary'],
        expertOkSteps: json['expertOkSteps'] ?? json['expert_ok_steps'],
      ).beginner,
      expertOkSteps: splitGuidanceSteps(
        json['safeGuidanceBoundary'],
        expertOkSteps: json['expertOkSteps'] ?? json['expert_ok_steps'],
      ).expertOk,
      stopProfessionalConditions: List<String>.from(
        json['stopProfessionalConditions'] as List? ?? const [],
      ),
      preventionActions: List<String>.from(
        json['preventionActions'] as List? ?? const [],
      ),
      toolsRequired: List<String>.from(
        json['toolsRequired'] as List? ?? const [],
      ),
      difficultyNotes: json['difficultyNotes'] as String? ?? '',
      commonality: json['commonality'] as String? ?? 'common',
      safetyNotes: json['safetyNotes'] as String? ?? '',
      allowResolvedWhenConfirmed:
          json['allowResolvedWhenConfirmed'] as bool? ?? true,
      preferProfessionalWhenNotConfirmed:
          json['preferProfessionalWhenNotConfirmed'] as bool? ?? true,
      visualGuides: List<dynamic>.from(
        json['visualGuides'] as List? ?? const [],
      )
          .map(
            (item) => visualGuideAnchorFromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      partsEstimates: parsePartsEstimatesJson(json['partsEstimates']),
    );
  }

  FailureMode toFailureMode() {
    return FailureMode(
      id: id,
      label: title,
      description: _composeDescription(),
      commonality: parseFailureModeCommonality(commonality),
      safetyNotes: safetyNotes,
    );
  }

  String _composeDescription() {
    final parts = <String>[
      if (immediateCause.trim().isNotEmpty) immediateCause.trim(),
      if (rootCause.trim().isNotEmpty) 'Root cause: ${rootCause.trim()}',
    ];
    return parts.isEmpty ? title : parts.join(' ');
  }
}

/// Ranking hint: which template answer supports or excludes this mode.
class EvidenceAnswerHint {
  const EvidenceAnswerHint({
    required this.templateId,
    required this.answer,
  });

  final String templateId;
  final String answer;

  Map<String, dynamic> toJson() => {
    'templateId': templateId,
    'answer': answer,
  };

  factory EvidenceAnswerHint.fromJson(Map<String, dynamic> json) {
    return EvidenceAnswerHint(
      templateId: json['templateId'] as String,
      answer: json['answer'] as String,
    );
  }
}

/// Optional first-line observation prompt authored with a mode.
class FirstLineObservation {
  FirstLineObservation({
    required this.templateId,
    required this.promptText,
    List<String> answerChoices = const [],
  }) : answerChoices = List.unmodifiable(answerChoices);

  final String templateId;
  final String promptText;
  final List<String> answerChoices;

  Map<String, dynamic> toJson() => {
    'templateId': templateId,
    'promptText': promptText,
    'answerChoices': answerChoices,
  };

  factory FirstLineObservation.fromJson(Map<String, dynamic> json) {
    return FirstLineObservation(
      templateId: json['templateId'] as String,
      promptText: json['promptText'] as String,
      answerChoices: List<String>.from(
        json['answerChoices'] as List? ?? const [],
      ),
    );
  }

  EvidenceTemplate toEvidenceTemplate({required String failureModeId}) {
    return EvidenceTemplate(
      id: templateId,
      promptText: promptText,
      expectedEvidenceType: EvidenceType.structuredAnswer,
      relatedFailureModeIds: [failureModeId],
      answerChoices: answerChoices,
    );
  }
}

FailureModeCommonality parseFailureModeCommonality(String value) {
  return switch (value.trim().toLowerCase()) {
    'veryhigh' || 'very_high' || 'very-high' => FailureModeCommonality.veryHigh,
    'high' => FailureModeCommonality.high,
    'moderate' => FailureModeCommonality.moderate,
    _ => FailureModeCommonality.common,
  };
}

/// Validation errors for an authoring record (deterministic, no LLM).
class AuthoringValidationException implements Exception {
  AuthoringValidationException(this.errors);

  final List<String> errors;

  @override
  String toString() => 'AuthoringValidationException: ${errors.join('; ')}';
}

/// Validates required Knowledge Factory fields and safety boundaries.
void validateFailureModeAuthoringRecord(
  FailureModeAuthoringRecord record, {
  String expectedApplianceFamily = 'dryer',
}) {
  final errors = <String>[];
  if (!_isSlug(record.id)) {
    errors.add('id must be a non-empty slug (a-z, 0-9, hyphen)');
  }
  if (record.title.trim().isEmpty) {
    errors.add('title is required');
  }
  if (record.applianceFamily.trim().toLowerCase() !=
      expectedApplianceFamily.toLowerCase()) {
    errors.add('applianceFamily must be "$expectedApplianceFamily"');
  }
  if (record.symptomPhrasings.isEmpty) {
    errors.add('symptomPhrasings must include at least one phrasing');
  }
  if (record.immediateCause.trim().isEmpty) {
    errors.add('immediateCause is required');
  }
  if (record.rootCause.trim().isEmpty) {
    errors.add('rootCause is required');
  }
  if (record.safetyNotes.trim().isEmpty) {
    errors.add('safetyNotes is required');
  }
  if (record.safeGuidanceBoundary.isEmpty) {
    errors.add('safeGuidanceBoundary must include at least one boundary step');
  }
  if (record.stopProfessionalConditions.isEmpty) {
    errors.add('stopProfessionalConditions must include at least one condition');
  }
  if (record.verificationAsk.trim().isEmpty) {
    errors.add('verificationAsk is required');
  }
  if (record.preventionActions.isEmpty) {
    errors.add('preventionActions must include at least one action');
  }
  if (record.commonMisdiagnoses.isEmpty) {
    errors.add('commonMisdiagnoses must include at least one misdiagnosis');
  }
  if (record.evidenceSupports.isEmpty) {
    errors.add('evidenceSupports must include at least one support hint');
  }
  if (record.evidenceExcludes.isEmpty) {
    errors.add('evidenceExcludes must include at least one exclude hint');
  }
  if (record.verificationSteps.isEmpty) {
    errors.add('verificationSteps must include at least one step');
  }
  if (errors.isNotEmpty) {
    throw AuthoringValidationException(errors);
  }
}

bool _isSlug(String value) {
  return RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value);
}
