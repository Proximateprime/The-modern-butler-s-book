import 'repair_session.dart';
import 'session_objective.dart';

/// How the household user closed the investigation (v1 memory kinds).
enum SessionCloseKind {
  fixed,
  notFixed,
  stopped,
  calledProfessional,
}

/// Immutable engineering record of what happened at the end of a session.
class SessionOutcome {
  SessionOutcome({
    required this.sessionId,
    required this.resolutionStatus,
    required this.immediateCause,
    required List<String> contributingFactors,
    required List<String> preventiveActions,
    required this.verified,
    required this.schemaVersion,
    this.rootCause,
    SessionCloseKind? closeKind,
    this.userNote,
    this.rankingLeaderFailureModeId,
    this.rankingLeaderLabel,
    this.startSymptom,
    this.heatPathPolarity,
    String? summary,
    this.recordedAt,
    this.diyCostUsd,
    this.sessionObjective,
    this.basePackageId,
    this.basePackageVersion,
    this.overlayPackageId,
    this.overlayPackageVersion,
    this.usingGeneralGuide,
  })  : closeKind = closeKind ?? closeKindFromResolution(resolutionStatus),
        summary = summary ??
            defaultHouseholdMemorySummary(
              closeKind: closeKind ?? closeKindFromResolution(resolutionStatus),
              whatFixedIt: immediateCause,
              rankingLeaderLabel: rankingLeaderLabel,
              startSymptom: startSymptom,
            ),
        contributingFactors = List.unmodifiable(contributingFactors),
        preventiveActions = List.unmodifiable(preventiveActions);

  final String sessionId;
  final SessionResolutionStatus resolutionStatus;
  final SessionCloseKind closeKind;
  final String immediateCause;
  final String? rootCause;
  final List<String> contributingFactors;
  final List<String> preventiveActions;
  final bool verified;
  final String schemaVersion;
  final String? userNote;
  final String? rankingLeaderFailureModeId;
  final String? rankingLeaderLabel;
  final String? startSymptom;
  final String? heatPathPolarity;
  final String summary;
  final DateTime? recordedAt;

  /// Optional household-entered DIY spend. Not a payment and not required.
  final double? diyCostUsd;

  /// Optional session goal. Copy/handoff only — not ranking.
  final SessionObjective? sessionObjective;

  final String? basePackageId;
  final String? basePackageVersion;
  final String? overlayPackageId;
  final String? overlayPackageVersion;
  final bool? usingGeneralGuide;
}

SessionCloseKind closeKindFromResolution(SessionResolutionStatus status) {
  return switch (status) {
    SessionResolutionStatus.resolved => SessionCloseKind.fixed,
    SessionResolutionStatus.unresolved => SessionCloseKind.notFixed,
    SessionResolutionStatus.partiallyResolved =>
      SessionCloseKind.calledProfessional,
  };
}

SessionResolutionStatus resolutionStatusFromCloseKind(SessionCloseKind kind) {
  return switch (kind) {
    SessionCloseKind.fixed => SessionResolutionStatus.resolved,
    SessionCloseKind.notFixed => SessionResolutionStatus.unresolved,
    SessionCloseKind.stopped => SessionResolutionStatus.unresolved,
    SessionCloseKind.calledProfessional =>
      SessionResolutionStatus.partiallyResolved,
  };
}

String sessionCloseKindLabel(SessionCloseKind kind) {
  return switch (kind) {
    SessionCloseKind.fixed => 'Fixed',
    SessionCloseKind.notFixed => 'Not fixed',
    SessionCloseKind.stopped => 'Stopped',
    SessionCloseKind.calledProfessional => 'Calling a professional',
  };
}

String defaultHouseholdMemorySummary({
  required SessionCloseKind closeKind,
  String? whatFixedIt,
  String? rankingLeaderLabel,
  String? startSymptom,
}) {
  final detail = _firstNonEmpty([
    whatFixedIt,
    rankingLeaderLabel,
    startSymptom,
  ]);
  final prefix = sessionCloseKindLabel(closeKind);
  if (detail == null) {
    return prefix;
  }
  return '$prefix — $detail';
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}
