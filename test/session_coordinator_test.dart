import 'package:flutter_test/flutter_test.dart';

import '../lib/demo/session_happy_path.dart';
import '../lib/models/appliance.dart';
import '../lib/models/evidence.dart';
import '../lib/models/household.dart';
import '../lib/models/hypothesis.dart';
import '../lib/models/knowledge_package_ref.dart';
import '../lib/models/repair_session.dart';
import '../lib/models/session_outcome.dart';
import '../lib/models/tool.dart';
import '../lib/services/appliance_repository.dart';
import '../lib/services/household_repository.dart';
import '../lib/services/knowledge_package_repository.dart';
import '../lib/services/repair_session_repository.dart';
import '../lib/services/session_coordinator.dart';

void main() {
  final startedAt = DateTime.utc(2026, 7, 22, 12);

  late HouseholdRepository householdRepository;
  late ApplianceRepository applianceRepository;
  late KnowledgePackageRepository knowledgePackageRepository;
  late RepairSessionRepository sessionRepository;
  late SessionCoordinator coordinator;
  late KnowledgePackageRef packageRef;

  setUp(() {
    householdRepository = HouseholdRepository();
    applianceRepository = ApplianceRepository();
    knowledgePackageRepository = KnowledgePackageRepository();
    sessionRepository = RepairSessionRepository();
    packageRef = KnowledgePackageRef.fromPackage(
      knowledgePackageRepository.loadByCategory('dryer').single,
    );
    coordinator = SessionCoordinator(
      householdRepository: householdRepository,
      applianceRepository: applianceRepository,
      knowledgePackageRepository: knowledgePackageRepository,
      repairSessionRepository: sessionRepository,
    );

    householdRepository.create(
      Household(
        id: 'household-1',
        name: 'Test Household',
        ownerUserId: 'user-1',
        createdAt: startedAt,
        schemaVersion: '1.0',
      ),
    );
    applianceRepository.create(
      Appliance(
        id: 'appliance-1',
        householdId: 'household-1',
        name: 'Test Dryer',
        category: 'dryer',
        manufacturer: 'Test Manufacturer',
        modelNumber: 'TEST-1',
        location: 'Laundry Room',
        status: ApplianceStatus.active,
        schemaVersion: '1.0',
        createdAt: startedAt,
        updatedAt: startedAt,
      ),
    );
  });

  RepairSession startSession() {
    return coordinator.startSession(
      sessionId: 'session-1',
      householdId: 'household-1',
      applianceId: 'appliance-1',
      createdByUserId: 'user-1',
      packageRef: packageRef,
      schemaVersion: '1.0',
      initialHistoryEntryId: 'history-0',
      startedAt: startedAt,
    );
  }

  test('Tool and KnowledgePackageRef are immutable data records', () {
    const tool = Tool(
      id: 'tool-1',
      name: 'Flashlight',
      category: 'inspection',
      isOwnedByHousehold: true,
    );

    expect(tool.name, 'Flashlight');
    expect(tool.isOwnedByHousehold, isTrue);
    expect(packageRef.applianceCategory, 'dryer');
    expect(packageRef.version, '1.4.2');
  });

  test('session start requires an available package reference', () {
    expect(
      () => coordinator.startSession(
        sessionId: 'session-1',
        householdId: 'household-1',
        applianceId: 'appliance-1',
        createdByUserId: 'user-1',
        packageRef: const KnowledgePackageRef(
          id: 'missing-package',
          applianceCategory: 'dryer',
          version: '1.0.0',
          displayName: 'Missing Package',
        ),
        schemaVersion: '1.0',
        initialHistoryEntryId: 'history-0',
        startedAt: startedAt,
      ),
      throwsStateError,
    );
  });

  test('coordinator completes and records a deterministic happy path', () {
    final session = startSession();
    expect(session.packageId, packageRef.id);
    expect(session.packageVersion, packageRef.version);

    const statesToEvidence = [
      RepairSessionState.selectAppliance,
      RepairSessionState.problemReported,
      RepairSessionState.basicConditionVerification,
      RepairSessionState.evidenceCollection,
    ];
    for (var index = 0; index < statesToEvidence.length; index++) {
      coordinator.transition(
        sessionId: session.id,
        to: statesToEvidence[index],
        historyEntryId: 'history-${index + 1}',
        reason: 'Reach evidence collection',
        triggeredBy: SessionTransitionTrigger.system,
        occurredAt: startedAt.add(Duration(minutes: index + 1)),
      );
    }

    coordinator.addEvidence(
      evidence: Evidence(
        id: 'evidence-1',
        sessionId: session.id,
        applianceId: 'appliance-1',
        type: EvidenceType.textObservation,
        observation: 'The drum turns, but the clothes remain cool.',
        collectedAt: startedAt.add(const Duration(minutes: 5)),
        collectedInState: RepairSessionState.evidenceCollection,
        source: EvidenceSource.user,
        schemaVersion: '1.0',
      ),
      evidenceLinkId: 'evidence-link-1',
    );

    final hypothesis = coordinator.attachHypothesis(
      Hypothesis(
        id: 'hypothesis-1',
        sessionId: session.id,
        failureModeId: 'restricted-exhaust-airflow',
        label: 'Restricted airflow',
        currentConfidence: 0.4,
        status: HypothesisStatus.active,
        schemaVersion: '1.0',
      ),
    );
    coordinator.updateHypothesis(
      hypothesis.copyWith(
        currentConfidence: 0.7,
        status: HypothesisStatus.confirmed,
      ),
    );
    expect(
      () => coordinator.updateHypothesis(
        Hypothesis(
          id: hypothesis.id,
          sessionId: hypothesis.sessionId,
          failureModeId: 'heating-element-failed',
          label: hypothesis.label,
          currentConfidence: hypothesis.currentConfidence,
          status: hypothesis.status,
          schemaVersion: hypothesis.schemaVersion,
        ),
      ),
      throwsStateError,
    );

    final context = coordinator.buildDecisionContext(
      sessionId: session.id,
      safetyLevel: 'clear',
      userComfortLevel: 'beginner',
      availableTools: const [
        Tool(
          id: 'tool-1',
          name: 'Flashlight',
          category: 'inspection',
          isOwnedByHousehold: true,
        ),
      ],
    );
    expect(context.session.id, session.id);
    expect(context.evidenceIds, ['evidence-1']);
    expect(context.currentHypotheses.single.currentConfidence, 0.7);
    expect(context.packageRef.id, packageRef.id);
    expect(context.packageRef.version, packageRef.version);

    const remainingStates = [
      RepairSessionState.hypothesisBuilding,
      RepairSessionState.riskCheck,
      RepairSessionState.safeGuidance,
      RepairSessionState.verification,
      RepairSessionState.rootCauseAnalysis,
      RepairSessionState.preventiveRecommendation,
    ];
    for (var index = 0; index < remainingStates.length; index++) {
      coordinator.transition(
        sessionId: session.id,
        to: remainingStates[index],
        historyEntryId: 'history-${index + 5}',
        reason: 'Continue verified path',
        triggeredBy: SessionTransitionTrigger.system,
        occurredAt: startedAt.add(Duration(minutes: index + 6)),
      );
    }

    final outcome = SessionOutcome(
      sessionId: session.id,
      resolutionStatus: SessionResolutionStatus.resolved,
      immediateCause: 'Airflow was restricted.',
      rootCause: 'The lint filter was blocked.',
      contributingFactors: const ['Cleaning was overdue.'],
      preventiveActions: const ['Clean the lint filter after each load.'],
      verified: true,
      schemaVersion: '1.0',
    );
    coordinator.closeSession(
      sessionId: session.id,
      outcome: outcome,
      historyEntryId: 'history-11',
      reason: 'Outcome verified and recorded',
      occurredAt: startedAt.add(const Duration(minutes: 12)),
    );

    expect(
      sessionRepository.getSession(session.id)!.currentState,
      RepairSessionState.sessionClosed,
    );
    expect(coordinator.outcomeForSession(session.id), same(outcome));
  });

  test('safety escalation is terminal and blocks later evidence', () {
    final session = startSession();

    expect(
      () => coordinator.transition(
        sessionId: session.id,
        to: RepairSessionState.escalated,
        historyEntryId: 'history-rejected',
        reason: 'Non-safety escalation attempt',
        triggeredBy: SessionTransitionTrigger.system,
        occurredAt: startedAt.add(const Duration(minutes: 1)),
      ),
      throwsStateError,
    );
    coordinator.transition(
      sessionId: session.id,
      to: RepairSessionState.escalated,
      historyEntryId: 'history-1',
      reason: 'Safety hard stop',
      triggeredBy: SessionTransitionTrigger.safetyEngine,
      occurredAt: startedAt.add(const Duration(minutes: 1)),
    );

    expect(
      () => coordinator.addEvidence(
        evidence: Evidence(
          id: 'evidence-1',
          sessionId: session.id,
          applianceId: 'appliance-1',
          type: EvidenceType.textObservation,
          observation: 'A burning smell is present.',
          collectedAt: startedAt.add(const Duration(minutes: 2)),
          collectedInState: RepairSessionState.escalated,
          source: EvidenceSource.user,
          schemaVersion: '1.0',
        ),
        evidenceLinkId: 'evidence-link-1',
      ),
      throwsStateError,
    );
    expect(
      () => coordinator.transition(
        sessionId: session.id,
        to: RepairSessionState.selectAppliance,
        historyEntryId: 'history-2',
        reason: 'Illegal continuation',
        triggeredBy: SessionTransitionTrigger.system,
        occurredAt: startedAt.add(const Duration(minutes: 2)),
      ),
      throwsStateError,
    );
  });

  test('developer happy-path demo reaches a verified closed outcome', () {
    final summary = runSessionHappyPathDemo();

    expect(summary, contains('Final state: sessionClosed'));
    expect(summary, contains('Outcome: resolved, verified=true'));
    expect(summary, contains('Root cause: The lint filter was blocked.'));
  });
}
