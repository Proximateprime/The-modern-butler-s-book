import 'repair_session.dart';

/// Observation formats supported by the current evidence model.
enum EvidenceType {
  textObservation,
  structuredAnswer,
  photo,
  video,
  measurement,
  basicConditionCheck,
  maintenanceRecord,
  previousRepair,
}

/// Where an observation came from.
enum EvidenceSource {
  user,
  photo,
  system,
}

/// An immutable observation collected during a Repair Session.
///
/// [observation] stores the prompt / observation context (not a diagnosis).
/// [answer] stores the user's selected choice when collected from a prompt.
/// [templateId] links to a package [EvidenceTemplate] id when available.
class Evidence {
  const Evidence({
    required this.id,
    required this.sessionId,
    required this.applianceId,
    required this.type,
    required this.observation,
    required this.collectedAt,
    required this.collectedInState,
    required this.source,
    required this.schemaVersion,
    this.answer,
    this.templateId,
    this.confidenceContribution,
    this.localPhotoPath,
  });

  final String id;
  final String sessionId;
  final String applianceId;
  final EvidenceType type;
  final String observation;
  final String? answer;
  final String? templateId;
  final DateTime collectedAt;
  final RepairSessionState collectedInState;
  final EvidenceSource source;
  final double? confidenceContribution;

  /// Local file path or ref only. Never sent to ranking or LLM diagnosis.
  final String? localPhotoPath;
  final String schemaVersion;
}
