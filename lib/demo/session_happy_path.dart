import '../models/appliance.dart';
import '../models/evidence.dart';
import '../models/household.dart';
import '../models/hypothesis.dart';
import '../models/knowledge_package_ref.dart';
import '../models/repair_session.dart';
import '../models/session_outcome.dart';
import '../models/tool.dart';
import '../services/appliance_repository.dart';
import '../services/household_repository.dart';
import '../services/knowledge_package_repository.dart';
import '../services/repair_session_repository.dart';
import '../services/session_coordinator.dart';

/// Runs a deterministic, developer-only dryer session through the MVP path.
///
/// No UI, persistence, network, or engine behavior is involved.
String runSessionHappyPathDemo() {
  final householdRepository = HouseholdRepository();
  final applianceRepository = ApplianceRepository();
  final knowledgePackageRepository = KnowledgePackageRepository();
  final sessionRepository = RepairSessionRepository();
  final coordinator = SessionCoordinator(
    householdRepository: householdRepository,
    applianceRepository: applianceRepository,
    knowledgePackageRepository: knowledgePackageRepository,
    repairSessionRepository: sessionRepository,
  );
  final startedAt = DateTime.utc(2026, 7, 22, 12);

  final household = householdRepository.create(
    Household(
      id: 'household-demo',
      name: 'Demo Household',
      ownerUserId: 'user-demo',
      createdAt: startedAt,
      schemaVersion: '1.0',
    ),
  );
  final appliance = applianceRepository.create(
    Appliance(
      id: 'appliance-dryer',
      householdId: household.id,
      name: 'Laundry Room Dryer',
      category: 'dryer',
      manufacturer: 'Demo Manufacturer',
      modelNumber: 'DRY-100',
      location: 'Laundry Room',
      status: ApplianceStatus.active,
      schemaVersion: '1.0',
      createdAt: startedAt,
      updatedAt: startedAt,
    ),
  );
  final packageRef = KnowledgePackageRef.fromPackage(
    knowledgePackageRepository.loadByCategory('dryer').single,
  );

  final session = coordinator.startSession(
    sessionId: 'session-demo',
    householdId: household.id,
    applianceId: appliance.id,
    createdByUserId: household.ownerUserId,
    packageRef: packageRef,
    schemaVersion: '1.0',
    initialHistoryEntryId: 'history-0',
    startedAt: startedAt,
    userGoal: 'Understand why the dryer is not heating.',
  );

  var minute = 1;
  var historyIndex = 1;
  void transition(RepairSessionState state, String reason) {
    coordinator.transition(
      sessionId: session.id,
      to: state,
      historyEntryId: 'history-${historyIndex++}',
      reason: reason,
      triggeredBy: SessionTransitionTrigger.system,
      occurredAt: startedAt.add(Duration(minutes: minute++)),
    );
  }

  transition(RepairSessionState.selectAppliance, 'Dryer selected');
  transition(RepairSessionState.problemReported, 'No-heat problem reported');
  transition(
    RepairSessionState.basicConditionVerification,
    'Basic conditions ready for observation',
  );
  transition(
    RepairSessionState.evidenceCollection,
    'Collect observable facts',
  );

  final observations = [
    'The drum turns during the cycle.',
    'The clothes remain wet and cool.',
    'No burning smell or smoke is present.',
  ];
  for (var index = 0; index < observations.length; index++) {
    coordinator.addEvidence(
      evidence: Evidence(
        id: 'evidence-${index + 1}',
        sessionId: session.id,
        applianceId: appliance.id,
        type: EvidenceType.textObservation,
        observation: observations[index],
        collectedAt: startedAt.add(Duration(minutes: minute++)),
        collectedInState: RepairSessionState.evidenceCollection,
        source: EvidenceSource.user,
        schemaVersion: '1.0',
      ),
      evidenceLinkId: 'evidence-link-${index + 1}',
    );
  }

  final airflowHypothesis = coordinator.attachHypothesis(
    Hypothesis(
      id: 'hypothesis-airflow',
      sessionId: session.id,
      failureModeId: 'restricted-exhaust-airflow',
      label: 'Restricted airflow',
      currentConfidence: 0.4,
      status: HypothesisStatus.active,
      schemaVersion: '1.0',
    ),
  );
  final heatingHypothesis = coordinator.attachHypothesis(
    Hypothesis(
      id: 'hypothesis-heating',
      sessionId: session.id,
      failureModeId: 'heating-element-failed',
      label: 'Heating system is not operating',
      currentConfidence: 0.4,
      status: HypothesisStatus.active,
      schemaVersion: '1.0',
    ),
  );

  const availableTools = [
    Tool(
      id: 'tool-flashlight',
      name: 'Flashlight',
      category: 'inspection',
      isOwnedByHousehold: true,
    ),
  ];
  final context = coordinator.buildDecisionContext(
    sessionId: session.id,
    safetyLevel: 'clear',
    userComfortLevel: 'beginner',
    availableTools: availableTools,
  );

  transition(
    RepairSessionState.hypothesisBuilding,
    'Candidate records attached',
  );
  transition(RepairSessionState.riskCheck, 'Risk status recorded');
  transition(RepairSessionState.safeGuidance, 'Safe guidance recorded');
  transition(RepairSessionState.verification, 'Verify observed result');

  coordinator.addEvidence(
    evidence: Evidence(
      id: 'evidence-verification',
      sessionId: session.id,
      applianceId: appliance.id,
      type: EvidenceType.textObservation,
      observation: 'The dryer now produces warm air during the cycle.',
      collectedAt: startedAt.add(Duration(minutes: minute++)),
      collectedInState: RepairSessionState.verification,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    ),
    evidenceLinkId: 'evidence-link-verification',
  );
  coordinator.updateHypothesis(
    airflowHypothesis.copyWith(
      currentConfidence: 0.8,
      status: HypothesisStatus.confirmed,
    ),
  );
  coordinator.updateHypothesis(
    heatingHypothesis.copyWith(
      currentConfidence: 0.1,
      status: HypothesisStatus.ruledOut,
    ),
  );

  transition(
    RepairSessionState.rootCauseAnalysis,
    'Root cause record prepared',
  );
  transition(
    RepairSessionState.preventiveRecommendation,
    'Preventive action recorded',
  );

  final outcome = coordinator.closeSession(
    sessionId: session.id,
    outcome: SessionOutcome(
      sessionId: session.id,
      resolutionStatus: SessionResolutionStatus.resolved,
      immediateCause: 'Dryer airflow was restricted.',
      rootCause: 'The lint filter was blocked.',
      contributingFactors: const ['Lint filter cleaning was overdue.'],
      preventiveActions: const ['Clean the lint filter after every load.'],
      verified: true,
      schemaVersion: '1.0',
    ),
    historyEntryId: 'history-${historyIndex++}',
    reason: 'Verified outcome recorded',
    occurredAt: startedAt.add(Duration(minutes: minute)),
  );

  return [
    'Household: ${household.name}',
    'Appliance: ${appliance.name}',
    'Session: ${session.id}',
    'Context evidence: ${context.evidence.length}',
    'Context hypotheses: ${context.currentHypotheses.length}',
    'Package: ${context.packageRef.displayName} ${context.packageRef.version}',
    'Final state: ${sessionRepository.getSession(session.id)!.currentState.name}',
    'Outcome: ${outcome.resolutionStatus.name}, verified=${outcome.verified}',
    'Root cause: ${outcome.rootCause}',
    'Prevention: ${outcome.preventiveActions.join(', ')}',
  ].join('\n');
}

void main() {
  print(runSessionHappyPathDemo());
}
