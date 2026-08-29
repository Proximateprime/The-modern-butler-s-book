import '../models/appliance.dart';
import '../models/decision_context.dart';
import '../models/evidence.dart';
import '../models/hypothesis.dart';
import '../models/knowledge_package.dart';
import '../models/knowledge_package_ref.dart';
import '../models/repair_session.dart';
import '../models/session_outcome.dart';
import '../models/tool.dart';
import 'appliance_repository.dart';
import 'household_repository.dart';
import 'knowledge_package_repository.dart';
import 'repair_session_repository.dart';

/// Thin facade that coordinates in-memory domain repositories.
///
/// This is not an engine. It performs no diagnosis, confidence calculation,
/// question selection, safety decision, or user communication.
class SessionCoordinator {
  SessionCoordinator({
    required HouseholdRepository householdRepository,
    required ApplianceRepository applianceRepository,
    required KnowledgePackageRepository knowledgePackageRepository,
    required RepairSessionRepository repairSessionRepository,
  })  : _householdRepository = householdRepository,
        _applianceRepository = applianceRepository,
        _knowledgePackageRepository = knowledgePackageRepository,
        _repairSessionRepository = repairSessionRepository;

  final HouseholdRepository _householdRepository;
  final ApplianceRepository _applianceRepository;
  final KnowledgePackageRepository _knowledgePackageRepository;
  final RepairSessionRepository _repairSessionRepository;
  final Map<String, KnowledgePackageRef> _packageRefsBySession = {};

  Map<String, KnowledgePackageRef> exportPackageRefs() {
    return Map.unmodifiable(_packageRefsBySession);
  }

  void importPackageRefs(Map<String, KnowledgePackageRef> packageRefs) {
    _packageRefsBySession
      ..clear()
      ..addAll(packageRefs);
  }

  void removePackageRefs(Iterable<String> sessionIds) {
    for (final id in sessionIds) {
      _packageRefsBySession.remove(id);
    }
  }

  RepairSession startSession({
    required String sessionId,
    required String householdId,
    required String applianceId,
    required String createdByUserId,
    required KnowledgePackageRef packageRef,
    required String schemaVersion,
    required String initialHistoryEntryId,
    required DateTime startedAt,
    String? userGoal,
    String? overlayPackageId,
    String? overlayPackageVersion,
    bool usingGeneralGuide = true,
  }) {
    final household = _householdRepository.getById(householdId);
    if (household == null) {
      throw StateError('Household "$householdId" was not found.');
    }

    final appliance = _applianceRepository.getById(applianceId);
    if (appliance == null) {
      throw StateError('Appliance "$applianceId" was not found.');
    }
    if (appliance.householdId != household.id) {
      throw StateError(
        'Appliance "$applianceId" does not belong to household "$householdId".',
      );
    }
    final package = _requirePackageForAppliance(packageRef, appliance);
    final canonicalPackageRef = KnowledgePackageRef.fromPackage(package);

    final session = _repairSessionRepository.createSession(
      id: sessionId,
      applianceId: applianceId,
      householdId: householdId,
      createdByUserId: createdByUserId,
      packageId: canonicalPackageRef.id,
      packageVersion: canonicalPackageRef.version,
      schemaVersion: schemaVersion,
      initialHistoryEntryId: initialHistoryEntryId,
      startedAt: startedAt,
      userGoal: userGoal,
      overlayPackageId: overlayPackageId,
      overlayPackageVersion: overlayPackageVersion,
      usingGeneralGuide: usingGeneralGuide,
    );
    _packageRefsBySession[session.id] = canonicalPackageRef;
    return session;
  }

  Evidence addEvidence({
    required Evidence evidence,
    required String evidenceLinkId,
  }) {
    return _repairSessionRepository.addEvidence(
      evidence: evidence,
      evidenceLinkId: evidenceLinkId,
    );
  }

  Evidence reviseObservationFromTemplate({
    required String sessionId,
    required String fromTemplateId,
    required Evidence replacementEvidence,
    required String evidenceLinkId,
  }) {
    return _repairSessionRepository.reviseObservationFromTemplate(
      sessionId: sessionId,
      fromTemplateId: fromTemplateId,
      replacementEvidence: replacementEvidence,
      evidenceLinkId: evidenceLinkId,
    );
  }

  Hypothesis attachHypothesis(Hypothesis hypothesis) {
    _validateHypothesisForSessionPackage(hypothesis);
    return _repairSessionRepository.addHypothesis(hypothesis);
  }

  Hypothesis updateHypothesis(Hypothesis hypothesis) {
    _validateHypothesisForSessionPackage(hypothesis);
    return _repairSessionRepository.updateHypothesis(hypothesis);
  }

  RepairSession transition({
    required String sessionId,
    required RepairSessionState to,
    required String historyEntryId,
    required String reason,
    required SessionTransitionTrigger triggeredBy,
    required DateTime occurredAt,
  }) {
    return _repairSessionRepository.transition(
      sessionId: sessionId,
      to: to,
      historyEntryId: historyEntryId,
      reason: reason,
      triggeredBy: triggeredBy,
      occurredAt: occurredAt,
    );
  }

  DecisionContext buildDecisionContext({
    required String sessionId,
    String safetyLevel = 'unknown',
    String userComfortLevel = 'unknown',
    List<Tool> availableTools = const [],
  }) {
    final session = _repairSessionRepository.getSession(sessionId);
    if (session == null) {
      throw StateError('Session "$sessionId" was not found.');
    }

    var packageRef = _packageRefsBySession[sessionId];
    final appliance = _applianceRepository.getById(session.applianceId);
    if (packageRef == null && appliance != null) {
      packageRef = KnowledgePackageRef(
        id: session.packageId,
        applianceCategory: appliance.category,
        version: session.packageVersion,
        displayName: session.packageId,
      );
    }
    if (packageRef == null) {
      throw StateError(
        'Knowledge package reference for session "$sessionId" was not found.',
      );
    }

    final package = _knowledgePackageRepository.resolveForResume(
      packageRef,
      applianceCategory: appliance?.category,
    );
    if (package != null &&
        (package.id != packageRef.id ||
            package.version != packageRef.version)) {
      packageRef = KnowledgePackageRef.fromPackage(package);
      _packageRefsBySession[sessionId] = packageRef;
      _repairSessionRepository.rebindPackage(
        sessionId: sessionId,
        packageId: package.id,
        packageVersion: package.version,
      );
    }

    return _repairSessionRepository.buildDecisionContext(
      sessionId: sessionId,
      packageRef: packageRef,
      safetyLevel: safetyLevel,
      userComfortLevel: userComfortLevel,
      availableTools: availableTools,
    ).withResolvedKnowledge(
      package: package,
      authoringIndex:
          package == null
              ? null
              : _knowledgePackageRepository.authoringIndexFor(package.id),
    );
  }

  SessionOutcome closeSession({
    required String sessionId,
    required SessionOutcome outcome,
    required String historyEntryId,
    required String reason,
    required DateTime occurredAt,
  }) {
    if (outcome.sessionId != sessionId) {
      throw StateError('SessionOutcome belongs to a different session.');
    }
    if (outcome.resolutionStatus == SessionResolutionStatus.resolved &&
        !outcome.verified) {
      throw StateError('A resolved outcome must be verified before closing.');
    }
    if (_repairSessionRepository.outcomeForSession(sessionId) != null) {
      throw StateError('Session "$sessionId" already has an outcome.');
    }

    _repairSessionRepository.transition(
      sessionId: sessionId,
      to: RepairSessionState.sessionClosed,
      historyEntryId: historyEntryId,
      reason: reason,
      triggeredBy: SessionTransitionTrigger.system,
      occurredAt: occurredAt,
      resolutionStatus: outcome.resolutionStatus,
    );
    return _repairSessionRepository.recordOutcome(outcome);
  }

  SessionOutcome? outcomeForSession(String sessionId) {
    return _repairSessionRepository.outcomeForSession(sessionId);
  }

  KnowledgePackage _requirePackageForAppliance(
    KnowledgePackageRef packageRef,
    Appliance appliance,
  ) {
    final package = _knowledgePackageRepository.resolveCompatible(packageRef);
    if (package == null) {
      throw StateError(
        'Knowledge package "${packageRef.id}" version '
        '"${packageRef.version}" is not available.',
      );
    }
    if (package.category != appliance.category) {
      throw StateError(
        'Knowledge package category must match the appliance category.',
      );
    }
    return package;
  }

  void _validateHypothesisForSessionPackage(Hypothesis hypothesis) {
    final packageRef = _packageRefsBySession[hypothesis.sessionId];
    final package =
        packageRef == null
            ? null
            : _knowledgePackageRepository.resolveCompatible(packageRef);
    if (package == null) {
      throw StateError(
        'Knowledge package for session "${hypothesis.sessionId}" was not found.',
      );
    }
    final failureModeExists = package.failureModes.any(
      (failureMode) => failureMode.id == hypothesis.failureModeId,
    );
    if (!failureModeExists) {
      throw StateError(
        'Failure mode "${hypothesis.failureModeId}" is not in package '
        '"${package.id}".',
      );
    }
  }
}
