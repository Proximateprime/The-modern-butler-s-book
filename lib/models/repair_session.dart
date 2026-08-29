import 'session_objective.dart';

// MVP skeleton only.
// No Reasoning Engine, Conversation Engine, or Knowledge Graph logic is present.
// This state set is intentionally reduced for the MVP skeleton and will later
// map to the full Diagnostic Workflow.

/// The simplified, compatible state set authorized for the MVP skeleton.
enum RepairSessionState {
  newSession,
  selectAppliance,
  problemReported,
  basicConditionVerification,
  evidenceCollection,
  hypothesisBuilding,
  riskCheck,
  safeGuidance,
  verification,
  rootCauseAnalysis,
  preventiveRecommendation,
  sessionClosed,
  escalated,
  abandoned,
  error,
}

/// The actors permitted by the Repair Session data model to trigger a change.
enum SessionTransitionTrigger {
  user,
  system,
  safetyEngine,
}

/// The resolution values defined by the Repair Session data model.
enum SessionResolutionStatus {
  resolved,
  partiallyResolved,
  unresolved,
}

/// One chronological, auditable state entry for a repair session.
class SessionStateHistory {
  const SessionStateHistory({
    required this.id,
    required this.sessionId,
    required this.state,
    required this.enteredAt,
    required this.reasonForTransition,
    required this.triggeredBy,
    this.exitedAt,
  });

  final String id;
  final String sessionId;
  final RepairSessionState state;
  final DateTime enteredAt;
  final DateTime? exitedAt;
  final String reasonForTransition;
  final SessionTransitionTrigger triggeredBy;

  SessionStateHistory closeAt(DateTime time) {
    return SessionStateHistory(
      id: id,
      sessionId: sessionId,
      state: state,
      enteredAt: enteredAt,
      exitedAt: time,
      reasonForTransition: reasonForTransition,
      triggeredBy: triggeredBy,
    );
  }
}

/// The central record for one repair attempt on exactly one appliance.
///
/// Core identity fields are immutable. Lifecycle fields are replaced through
/// [copyWith] by the repository after a legal state transition.
class RepairSession {
  RepairSession({
    required this.id,
    required this.applianceId,
    required this.householdId,
    required this.currentState,
    required this.startedAt,
    required this.lastActivityAt,
    required this.createdByUserId,
    required this.packageId,
    required this.packageVersion,
    required this.schemaVersion,
    required List<SessionStateHistory> stateHistory,
    this.endedAt,
    this.resolutionStatus,
    this.userGoal,
    this.sessionObjective,
    this.overlayPackageId,
    this.overlayPackageVersion,
    this.usingGeneralGuide = true,
    this.guidanceStepIndex = 0,
    List<String> completedGuidanceStepIds = const [],
  }) : stateHistory = List.unmodifiable(stateHistory),
       completedGuidanceStepIds = List.unmodifiable(completedGuidanceStepIds);

  final String id;
  final String applianceId;
  final String householdId;
  final RepairSessionState currentState;
  final DateTime startedAt;
  final DateTime lastActivityAt;
  final DateTime? endedAt;
  final SessionResolutionStatus? resolutionStatus;
  final String? userGoal;
  final SessionObjective? sessionObjective;
  final String createdByUserId;
  final String packageId;
  final String packageVersion;
  final String schemaVersion;
  final List<SessionStateHistory> stateHistory;
  final String? overlayPackageId;
  final String? overlayPackageVersion;
  final bool usingGeneralGuide;

  /// Close-path Safe Guidance index. Local only — not ranking.
  final int guidanceStepIndex;

  /// Completed Safe Guidance step ids for Continue repair. Local only.
  final List<String> completedGuidanceStepIds;

  RepairSession copyWith({
    RepairSessionState? currentState,
    DateTime? lastActivityAt,
    DateTime? endedAt,
    SessionResolutionStatus? resolutionStatus,
    List<SessionStateHistory>? stateHistory,
    SessionObjective? sessionObjective,
    bool clearSessionObjective = false,
    String? overlayPackageId,
    String? overlayPackageVersion,
    bool? usingGeneralGuide,
    bool clearOverlayPackage = false,
    int? guidanceStepIndex,
    List<String>? completedGuidanceStepIds,
    String? packageId,
    String? packageVersion,
  }) {
    return RepairSession(
      id: id,
      applianceId: applianceId,
      householdId: householdId,
      currentState: currentState ?? this.currentState,
      startedAt: startedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      endedAt: endedAt ?? this.endedAt,
      resolutionStatus: resolutionStatus ?? this.resolutionStatus,
      userGoal: userGoal,
      sessionObjective:
          clearSessionObjective
              ? null
              : (sessionObjective ?? this.sessionObjective),
      createdByUserId: createdByUserId,
      packageId: packageId ?? this.packageId,
      packageVersion: packageVersion ?? this.packageVersion,
      schemaVersion: schemaVersion,
      stateHistory: stateHistory ?? this.stateHistory,
      overlayPackageId:
          clearOverlayPackage
              ? null
              : (overlayPackageId ?? this.overlayPackageId),
      overlayPackageVersion:
          clearOverlayPackage
              ? null
              : (overlayPackageVersion ?? this.overlayPackageVersion),
      usingGeneralGuide: usingGeneralGuide ?? this.usingGeneralGuide,
      guidanceStepIndex: guidanceStepIndex ?? this.guidanceStepIndex,
      completedGuidanceStepIds:
          completedGuidanceStepIds ?? this.completedGuidanceStepIds,
    );
  }
}

/// The audit link between a session and one immutable evidence record.
class SessionEvidenceLink {
  const SessionEvidenceLink({
    required this.id,
    required this.sessionId,
    required this.evidenceId,
    required this.addedAt,
    required this.sourceState,
  });

  final String id;
  final String sessionId;
  final String evidenceId;
  final DateTime addedAt;
  final RepairSessionState sourceState;
}
