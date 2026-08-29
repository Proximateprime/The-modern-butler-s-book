/// Lifecycle status of a hypothesis recorded during a Repair Session.
enum HypothesisStatus {
  active,
  ruledOut,
  confirmed,
}

/// Immutable hypothesis data record.
///
/// This model stores a confidence value but does not calculate or change it.
class Hypothesis {
  Hypothesis({
    required this.id,
    required this.sessionId,
    required this.failureModeId,
    required this.label,
    required this.currentConfidence,
    required this.status,
    required this.schemaVersion,
  }) {
    if (currentConfidence < 0 || currentConfidence > 1) {
      throw ArgumentError.value(
        currentConfidence,
        'currentConfidence',
        'Must be between 0 and 1.',
      );
    }
  }

  final String id;
  final String sessionId;
  final String failureModeId;
  final String label;
  final double currentConfidence;
  final HypothesisStatus status;
  final String schemaVersion;

  /// Returns a replacement data record with explicitly supplied changes.
  ///
  /// No confidence calculation or status decision is performed here.
  Hypothesis copyWith({
    String? label,
    double? currentConfidence,
    HypothesisStatus? status,
  }) {
    return Hypothesis(
      id: id,
      sessionId: sessionId,
      failureModeId: failureModeId,
      label: label ?? this.label,
      currentConfidence: currentConfidence ?? this.currentConfidence,
      status: status ?? this.status,
      schemaVersion: schemaVersion,
    );
  }
}
