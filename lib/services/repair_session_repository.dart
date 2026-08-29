// MVP skeleton only.
// No Reasoning Engine, Conversation Engine, or Knowledge Graph logic is present.
// This state set is intentionally reduced for the MVP skeleton and will later
// map to the full Diagnostic Workflow.

import '../models/decision_context.dart';
import '../models/evidence.dart';
import '../models/hypothesis.dart';
import '../models/knowledge_package_ref.dart';
import '../models/repair_session.dart';
import '../models/session_objective.dart';
import '../models/session_outcome.dart';
import '../models/tool.dart';

/// Minimal in-memory session store and deterministic state machine controller.
///
/// This deliberately contains no diagnosis, conversation, knowledge graph, or
/// safety-decision logic. It only enforces the simplified MVP transitions.
/// This repository never attempts to make or override a safety decision.
class RepairSessionRepository {
  RepairSessionRepository({void Function()? onChanged}) : _onChanged = onChanged;

  final void Function()? _onChanged;
  final Map<String, RepairSession> _sessions = {};
  final Map<String, Evidence> _evidence = {};
  final Map<String, List<SessionEvidenceLink>> _evidenceLinks = {};
  final Map<String, Hypothesis> _hypotheses = {};
  final Map<String, List<String>> _hypothesisIds = {};
  final Map<String, SessionOutcome> _outcomes = {};

  static const Set<RepairSessionState> _terminalStates = {
    RepairSessionState.sessionClosed,
    RepairSessionState.escalated,
    RepairSessionState.abandoned,
    RepairSessionState.error,
  };

  static const Map<RepairSessionState, Set<RepairSessionState>>
      _normalTransitions = {
    RepairSessionState.newSession: {
      RepairSessionState.selectAppliance,
    },
    RepairSessionState.selectAppliance: {
      RepairSessionState.problemReported,
    },
    RepairSessionState.problemReported: {
      RepairSessionState.basicConditionVerification,
    },
    RepairSessionState.basicConditionVerification: {
      RepairSessionState.evidenceCollection,
    },
    RepairSessionState.evidenceCollection: {
      RepairSessionState.evidenceCollection,
      RepairSessionState.hypothesisBuilding,
    },
    RepairSessionState.hypothesisBuilding: {
      RepairSessionState.evidenceCollection,
      RepairSessionState.riskCheck,
    },
    RepairSessionState.riskCheck: {
      RepairSessionState.evidenceCollection,
      RepairSessionState.safeGuidance,
    },
    RepairSessionState.safeGuidance: {
      RepairSessionState.verification,
    },
    RepairSessionState.verification: {
      RepairSessionState.evidenceCollection,
      RepairSessionState.rootCauseAnalysis,
    },
    RepairSessionState.rootCauseAnalysis: {
      RepairSessionState.preventiveRecommendation,
    },
    RepairSessionState.preventiveRecommendation: {
      RepairSessionState.sessionClosed,
    },
  };

  RepairSession createSession({
    required String id,
    required String applianceId,
    required String householdId,
    required String createdByUserId,
    required String packageId,
    required String packageVersion,
    required String schemaVersion,
    required String initialHistoryEntryId,
    required DateTime startedAt,
    String? userGoal,
    String? overlayPackageId,
    String? overlayPackageVersion,
    bool usingGeneralGuide = true,
  }) {
    if (_sessions.containsKey(id)) {
      throw StateError('A repair session with id "$id" already exists.');
    }

    final initialHistory = SessionStateHistory(
      id: initialHistoryEntryId,
      sessionId: id,
      state: RepairSessionState.newSession,
      enteredAt: startedAt,
      reasonForTransition: 'Session created',
      triggeredBy: SessionTransitionTrigger.user,
    );

    final session = RepairSession(
      id: id,
      applianceId: applianceId,
      householdId: householdId,
      currentState: RepairSessionState.newSession,
      startedAt: startedAt,
      lastActivityAt: startedAt,
      createdByUserId: createdByUserId,
      packageId: packageId,
      packageVersion: packageVersion,
      schemaVersion: schemaVersion,
      stateHistory: [initialHistory],
      userGoal: userGoal,
      overlayPackageId: overlayPackageId,
      overlayPackageVersion: overlayPackageVersion,
      usingGeneralGuide: usingGeneralGuide,
    );

    _sessions[id] = session;
    _evidenceLinks[id] = [];
    _hypothesisIds[id] = [];
    _onChanged?.call();
    return session;
  }

  RepairSession setSessionObjective({
    required String sessionId,
    SessionObjective? objective,
  }) {
    final session = _requireSession(sessionId);
    if (_terminalStates.contains(session.currentState)) {
      throw StateError(
        'The session objective cannot be changed after the session ends.',
      );
    }
    final updated = session.copyWith(
      sessionObjective: objective,
      clearSessionObjective: objective == null,
    );
    _sessions[sessionId] = updated;
    _onChanged?.call();
    return updated;
  }

  /// Updates the package identity on an open session after a compatible
  /// bundled guide replaces an older saved ref. Does not change evidence.
  RepairSession rebindPackage({
    required String sessionId,
    required String packageId,
    required String packageVersion,
  }) {
    final session = _requireSession(sessionId);
    final updated = session.copyWith(
      packageId: packageId,
      packageVersion: packageVersion,
    );
    _sessions[sessionId] = updated;
    _onChanged?.call();
    return updated;
  }

  /// Stores Safe Guidance progress on the session. Does not change state
  /// machine, evidence, or ranking. Local persist only.
  RepairSession saveGuidanceProgress({
    required String sessionId,
    required int guidanceStepIndex,
    required List<String> completedGuidanceStepIds,
    bool notify = true,
  }) {
    final session = _requireSession(sessionId);
    if (_terminalStates.contains(session.currentState)) {
      return session;
    }
    final updated = session.copyWith(
      guidanceStepIndex: guidanceStepIndex < 0 ? 0 : guidanceStepIndex,
      completedGuidanceStepIds: List<String>.from(completedGuidanceStepIds),
    );
    _sessions[sessionId] = updated;
    if (notify) {
      _onChanged?.call();
    }
    return updated;
  }

  RepairSession? getSession(String sessionId) => _sessions[sessionId];

  bool canTransition({
    required RepairSessionState from,
    required RepairSessionState to,
    required SessionTransitionTrigger triggeredBy,
  }) {
    if (_terminalStates.contains(from)) {
      return false;
    }

    if (to == RepairSessionState.abandoned ||
        to == RepairSessionState.error) {
      return true;
    }

    if (triggeredBy == SessionTransitionTrigger.safetyEngine &&
        to == RepairSessionState.escalated) {
      return true;
    }

    return _normalTransitions[from]?.contains(to) ?? false;
  }

  RepairSession transition({
    required String sessionId,
    required RepairSessionState to,
    required String historyEntryId,
    required String reason,
    required SessionTransitionTrigger triggeredBy,
    required DateTime occurredAt,
    SessionResolutionStatus? resolutionStatus,
  }) {
    final session = _requireSession(sessionId);

    if (!canTransition(
      from: session.currentState,
      to: to,
      triggeredBy: triggeredBy,
    )) {
      throw StateError(
        'Transition from ${session.currentState.name} to ${to.name} '
        'is not allowed.',
      );
    }

    if (occurredAt.isBefore(session.lastActivityAt)) {
      throw ArgumentError.value(
        occurredAt,
        'occurredAt',
        'Cannot be earlier than the session last activity.',
      );
    }

    if (to == RepairSessionState.sessionClosed && resolutionStatus == null) {
      throw StateError(
        'A resolution status is required before closing a session.',
      );
    }

    final history = session.stateHistory.toList();
    history[history.length - 1] = history.last.closeAt(occurredAt);
    history.add(
      SessionStateHistory(
        id: historyEntryId,
        sessionId: sessionId,
        state: to,
        enteredAt: occurredAt,
        reasonForTransition: reason,
        triggeredBy: triggeredBy,
      ),
    );

    final updated = session.copyWith(
      currentState: to,
      lastActivityAt: occurredAt,
      endedAt: _terminalStates.contains(to) ? occurredAt : null,
      resolutionStatus: resolutionStatus,
      stateHistory: history,
    );
    _sessions[sessionId] = updated;
    _onChanged?.call();
    return updated;
  }

  Evidence addEvidence({
    required Evidence evidence,
    required String evidenceLinkId,
  }) {
    final session = _requireSession(evidence.sessionId);

    if (_terminalStates.contains(session.currentState)) {
      throw StateError('Evidence cannot be added to a terminal session.');
    }
    if (evidence.applianceId != session.applianceId) {
      throw StateError(
        'Evidence appliance must match the session appliance.',
      );
    }
    if (evidence.collectedInState != session.currentState) {
      throw StateError(
        'Evidence collection state must match the current session state.',
      );
    }
    if (evidence.collectedAt.isBefore(session.lastActivityAt)) {
      throw ArgumentError.value(
        evidence.collectedAt,
        'evidence.collectedAt',
        'Cannot be earlier than the session last activity.',
      );
    }
    if (_evidence.containsKey(evidence.id)) {
      throw StateError('Evidence with id "${evidence.id}" already exists.');
    }

    _evidence[evidence.id] = evidence;
    _evidenceLinks[evidence.sessionId]!.add(
      SessionEvidenceLink(
        id: evidenceLinkId,
        sessionId: evidence.sessionId,
        evidenceId: evidence.id,
        addedAt: evidence.collectedAt,
        sourceState: evidence.collectedInState,
      ),
    );

    final updatedSession = session.copyWith(
      lastActivityAt: evidence.collectedAt,
    );
    _sessions[session.id] = updatedSession;
    _onChanged?.call();
    return evidence;
  }

  List<Evidence> evidenceForSession(String sessionId) {
    _requireSession(sessionId);
    return List.unmodifiable(
      _evidenceLinks[sessionId]!.map(
        (link) => _evidence[link.evidenceId]!,
      ),
    );
  }

  /// Replaces observation evidence for [fromTemplateId] and removes every
  /// later evidence item in the session timeline.
  ///
  /// Confirmed hypotheses are cleared because ranking and primary selection
  /// must be recomputed from the revised point. Close-path verification tied
  /// to removed evidence is dropped with the truncated links.
  Evidence reviseObservationFromTemplate({
    required String sessionId,
    required String fromTemplateId,
    required Evidence replacementEvidence,
    required String evidenceLinkId,
  }) {
    final session = _requireSession(sessionId);

    if (_terminalStates.contains(session.currentState)) {
      throw StateError('Evidence cannot be revised in a terminal session.');
    }
    if (replacementEvidence.sessionId != sessionId) {
      throw StateError('Replacement evidence must belong to the same session.');
    }
    if (replacementEvidence.templateId != fromTemplateId) {
      throw StateError(
        'Replacement evidence template must match fromTemplateId.',
      );
    }

    final links = _evidenceLinks[sessionId]!;
    var fromIndex = -1;
    for (var i = 0; i < links.length; i++) {
      final existing = _evidence[links[i].evidenceId]!;
      if (existing.templateId == fromTemplateId) {
        fromIndex = i;
        break;
      }
    }

    if (fromIndex >= 0) {
      final removed = links.sublist(fromIndex);
      links.removeRange(fromIndex, links.length);
      for (final link in removed) {
        _evidence.remove(link.evidenceId);
      }
      _clearConfirmedHypotheses(sessionId);
    }

    return addEvidence(
      evidence: replacementEvidence,
      evidenceLinkId: evidenceLinkId,
    );
  }

  void _clearConfirmedHypotheses(String sessionId) {
    for (final hypothesisId in _hypothesisIds[sessionId]!) {
      final hypothesis = _hypotheses[hypothesisId]!;
      if (hypothesis.status == HypothesisStatus.confirmed) {
        _hypotheses[hypothesisId] = hypothesis.copyWith(
          status: HypothesisStatus.ruledOut,
        );
      }
    }
  }

  List<SessionEvidenceLink> evidenceLinksForSession(String sessionId) {
    _requireSession(sessionId);
    return List.unmodifiable(_evidenceLinks[sessionId]!);
  }

  Hypothesis addHypothesis(Hypothesis hypothesis) {
    final session = _requireSession(hypothesis.sessionId);

    if (_terminalStates.contains(session.currentState)) {
      throw StateError('Hypotheses cannot be added to a terminal session.');
    }

    if (_hypotheses.containsKey(hypothesis.id)) {
      throw StateError(
        'Hypothesis with id "${hypothesis.id}" already exists.',
      );
    }

    _hypotheses[hypothesis.id] = hypothesis;
    _hypothesisIds[hypothesis.sessionId]!.add(hypothesis.id);
    _onChanged?.call();
    return hypothesis;
  }

  Hypothesis updateHypothesis(Hypothesis hypothesis) {
    final session = _requireSession(hypothesis.sessionId);
    final existing = _hypotheses[hypothesis.id];

    if (_terminalStates.contains(session.currentState)) {
      throw StateError('Hypotheses cannot be updated in a terminal session.');
    }
    if (existing == null) {
      throw StateError('Hypothesis "${hypothesis.id}" was not found.');
    }
    if (existing.sessionId != hypothesis.sessionId) {
      throw StateError('A hypothesis cannot move between sessions.');
    }
    if (existing.failureModeId != hypothesis.failureModeId ||
        existing.schemaVersion != hypothesis.schemaVersion) {
      throw StateError(
        'Hypothesis identity and schema version cannot be changed.',
      );
    }

    _hypotheses[hypothesis.id] = hypothesis;
    _onChanged?.call();
    return hypothesis;
  }

  List<Hypothesis> hypothesesForSession(String sessionId) {
    _requireSession(sessionId);
    return List.unmodifiable(
      _hypothesisIds[sessionId]!.map(
        (id) => _hypotheses[id]!,
      ),
    );
  }

  DecisionContext buildDecisionContext({
    required String sessionId,
    required KnowledgePackageRef packageRef,
    String safetyLevel = 'unknown',
    String userComfortLevel = 'unknown',
    List<Tool> availableTools = const [],
  }) {
    final session = _requireSession(sessionId);
    return DecisionContext.fromSession(
      session: session,
      evidence: evidenceForSession(sessionId),
      currentHypotheses: hypothesesForSession(sessionId),
      safetyLevel: safetyLevel,
      userComfortLevel: userComfortLevel,
      availableTools: availableTools,
      packageRef: packageRef,
    );
  }

  SessionOutcome recordOutcome(SessionOutcome outcome) {
    final session = _requireSession(outcome.sessionId);

    if (session.currentState != RepairSessionState.sessionClosed) {
      throw StateError(
        'A SessionOutcome can only be recorded for a closed session.',
      );
    }
    if (_outcomes.containsKey(outcome.sessionId)) {
      throw StateError(
        'Session "${outcome.sessionId}" already has an outcome.',
      );
    }
    if (session.resolutionStatus != outcome.resolutionStatus) {
      throw StateError(
        'Outcome resolution status must match the closed session.',
      );
    }
    if (outcome.resolutionStatus == SessionResolutionStatus.resolved &&
        !outcome.verified) {
      throw StateError('A resolved outcome must be verified.');
    }

    _outcomes[outcome.sessionId] = outcome;
    _onChanged?.call();
    return outcome;
  }

  SessionOutcome? outcomeForSession(String sessionId) {
    _requireSession(sessionId);
    return _outcomes[sessionId];
  }

  List<RepairSession> listAllSessions() => List.unmodifiable(_sessions.values);

  List<Evidence> listAllEvidence() => List.unmodifiable(_evidence.values);

  List<SessionEvidenceLink> listAllEvidenceLinks() {
    return List.unmodifiable(
      _evidenceLinks.values.expand((links) => links),
    );
  }

  List<Hypothesis> listAllHypotheses() => List.unmodifiable(_hypotheses.values);

  Map<String, List<String>> hypothesisIdsBySession() {
    return {
      for (final entry in _hypothesisIds.entries)
        entry.key: List<String>.from(entry.value),
    };
  }

  List<SessionOutcome> listAllOutcomes() => List.unmodifiable(_outcomes.values);

  /// Drops sessions and their evidence, hypotheses, and outcomes.
  void removeSessions(Iterable<String> sessionIds) {
    final ids = sessionIds.toSet();
    if (ids.isEmpty) {
      return;
    }
    for (final id in ids) {
      _sessions.remove(id);
      final links = _evidenceLinks.remove(id) ?? const [];
      for (final link in links) {
        _evidence.remove(link.evidenceId);
      }
      final hypothesisIds = _hypothesisIds.remove(id) ?? const [];
      for (final hypothesisId in hypothesisIds) {
        _hypotheses.remove(hypothesisId);
      }
      _outcomes.remove(id);
    }
    _onChanged?.call();
  }

  void replacePersistedState({
    required List<RepairSession> sessions,
    required List<Evidence> evidence,
    required List<SessionEvidenceLink> evidenceLinks,
    required List<Hypothesis> hypotheses,
    required Map<String, List<String>> hypothesisIdsBySession,
    required List<SessionOutcome> outcomes,
  }) {
    _sessions
      ..clear()
      ..addEntries(sessions.map((session) => MapEntry(session.id, session)));
    _evidence
      ..clear()
      ..addEntries(evidence.map((item) => MapEntry(item.id, item)));
    _evidenceLinks
      ..clear()
      ..addEntries(
        sessions.map(
          (session) => MapEntry(session.id, <SessionEvidenceLink>[]),
        ),
      );
    for (final link in evidenceLinks) {
      _evidenceLinks.putIfAbsent(link.sessionId, () => <SessionEvidenceLink>[]);
      _evidenceLinks[link.sessionId]!.add(link);
    }
    _hypotheses
      ..clear()
      ..addEntries(
        hypotheses.map((hypothesis) => MapEntry(hypothesis.id, hypothesis)),
      );
    _hypothesisIds
      ..clear()
      ..addEntries(
        hypothesisIdsBySession.entries.map(
          (entry) => MapEntry(entry.key, List<String>.from(entry.value)),
        ),
      );
    for (final session in sessions) {
      _hypothesisIds.putIfAbsent(session.id, () => <String>[]);
      _evidenceLinks.putIfAbsent(session.id, () => <SessionEvidenceLink>[]);
    }
    _outcomes
      ..clear()
      ..addEntries(
        outcomes.map((outcome) => MapEntry(outcome.sessionId, outcome)),
      );
  }

  RepairSession _requireSession(String sessionId) {
    final session = _sessions[sessionId];
    if (session == null) {
      throw StateError('Repair session "$sessionId" was not found.');
    }
    return session;
  }
}
