import 'package:flutter_test/flutter_test.dart';

import '../lib/models/evidence.dart';
import '../lib/models/hypothesis.dart';
import '../lib/models/knowledge_package_ref.dart';
import '../lib/models/repair_session.dart';
import '../lib/models/session_outcome.dart';
import '../lib/models/tool.dart';
import '../lib/services/repair_session_repository.dart';

void main() {
  final startedAt = DateTime.utc(2026, 7, 22, 12);

  RepairSession createSession(RepairSessionRepository repository) {
    return repository.createSession(
      id: 'session-1',
      applianceId: 'appliance-1',
      householdId: 'household-1',
      createdByUserId: 'user-1',
      packageId: 'package-1',
      packageVersion: '1.0.0',
      schemaVersion: '1.0',
      initialHistoryEntryId: 'history-0',
      startedAt: startedAt,
    );
  }

  test('Evidence stores an observation without adding a diagnosis', () {
    final evidence = Evidence(
      id: 'evidence-1',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.textObservation,
      observation: 'The dryer drum turns, but the clothes remain wet.',
      collectedAt: startedAt,
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      confidenceContribution: 0.2,
      schemaVersion: '1.0',
    );

    expect(
      evidence.observation,
      'The dryer drum turns, but the clothes remain wet.',
    );
    expect(evidence.source, EvidenceSource.user);
    expect(evidence.confidenceContribution, 0.2);
  });

  test('Hypothesis stores supplied data without calculating confidence', () {
    final hypothesis = Hypothesis(
      id: 'hypothesis-1',
      sessionId: 'session-1',
      failureModeId: 'restricted-airflow',
      label: 'Restricted airflow',
      currentConfidence: 0.4,
      status: HypothesisStatus.active,
      schemaVersion: '1.0',
    );

    expect(hypothesis.failureModeId, 'restricted-airflow');
    expect(hypothesis.currentConfidence, 0.4);
    expect(hypothesis.status, HypothesisStatus.active);
  });

  test('SessionOutcome is an immutable data record', () {
    final outcome = SessionOutcome(
      sessionId: 'session-1',
      resolutionStatus: SessionResolutionStatus.resolved,
      immediateCause: 'Airflow was restricted.',
      rootCause: 'The lint filter was blocked.',
      contributingFactors: const ['Filter had not been cleaned recently.'],
      preventiveActions: const ['Clean the lint filter after each load.'],
      verified: true,
      schemaVersion: '1.0',
    );

    expect(outcome.verified, isTrue);
    expect(outcome.rootCause, 'The lint filter was blocked.');
    expect(
      () => outcome.preventiveActions.add('Another action'),
      throwsUnsupportedError,
    );
  });

  group('RepairSessionRepository', () {
    test('creating a session starts in newSession', () {
      final repository = RepairSessionRepository();

      final session = createSession(repository);

      expect(session.currentState, RepairSessionState.newSession);
      expect(session.stateHistory, hasLength(1));
      expect(
        session.stateHistory.single.state,
        RepairSessionState.newSession,
      );
    });

    test('normal happy-path transitions work', () {
      final repository = RepairSessionRepository();
      createSession(repository);

      const states = [
        RepairSessionState.selectAppliance,
        RepairSessionState.problemReported,
        RepairSessionState.basicConditionVerification,
        RepairSessionState.evidenceCollection,
        RepairSessionState.hypothesisBuilding,
        RepairSessionState.riskCheck,
        RepairSessionState.safeGuidance,
        RepairSessionState.verification,
        RepairSessionState.rootCauseAnalysis,
        RepairSessionState.preventiveRecommendation,
        RepairSessionState.sessionClosed,
      ];

      for (var index = 0; index < states.length; index++) {
        repository.transition(
          sessionId: 'session-1',
          to: states[index],
          historyEntryId: 'history-${index + 1}',
          reason: 'Test transition',
          triggeredBy: SessionTransitionTrigger.system,
          occurredAt: startedAt.add(Duration(minutes: index + 1)),
          resolutionStatus:
              states[index] == RepairSessionState.sessionClosed
                  ? SessionResolutionStatus.resolved
                  : null,
        );
      }

      final session = repository.getSession('session-1')!;
      expect(session.currentState, RepairSessionState.sessionClosed);
      expect(session.resolutionStatus, SessionResolutionStatus.resolved);
      expect(session.stateHistory, hasLength(states.length + 1));
    });

    test('attaches hypotheses and builds a DecisionContext', () {
      final repository = RepairSessionRepository();
      createSession(repository);

      const states = [
        RepairSessionState.selectAppliance,
        RepairSessionState.problemReported,
        RepairSessionState.basicConditionVerification,
        RepairSessionState.evidenceCollection,
      ];
      for (var index = 0; index < states.length; index++) {
        repository.transition(
          sessionId: 'session-1',
          to: states[index],
          historyEntryId: 'history-${index + 1}',
          reason: 'Reach evidence collection',
          triggeredBy: SessionTransitionTrigger.system,
          occurredAt: startedAt.add(Duration(minutes: index + 1)),
        );
      }

      repository.addEvidence(
        evidence: Evidence(
          id: 'evidence-1',
          sessionId: 'session-1',
          applianceId: 'appliance-1',
          type: EvidenceType.textObservation,
          observation: 'The dryer drum turns without producing heat.',
          collectedAt: startedAt.add(const Duration(minutes: 5)),
          collectedInState: RepairSessionState.evidenceCollection,
          source: EvidenceSource.user,
          schemaVersion: '1.0',
        ),
        evidenceLinkId: 'evidence-link-1',
      );
      repository.addHypothesis(
        Hypothesis(
          id: 'hypothesis-1',
          sessionId: 'session-1',
          failureModeId: 'restricted-airflow',
          label: 'Restricted airflow',
          currentConfidence: 0.4,
          status: HypothesisStatus.active,
          schemaVersion: '1.0',
        ),
      );

      final context = repository.buildDecisionContext(
        sessionId: 'session-1',
        packageRef: const KnowledgePackageRef(
          id: 'package-1',
          applianceCategory: 'dryer',
          version: '1.0.0',
          displayName: 'Dryer Package',
        ),
        safetyLevel: 'unknown',
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

      expect(context.currentState, RepairSessionState.evidenceCollection);
      expect(context.evidenceIds, ['evidence-1']);
      expect(context.currentHypotheses.single.id, 'hypothesis-1');
      expect(context.availableTools.single.name, 'Flashlight');
    });

    test('illegal transitions are rejected', () {
      final repository = RepairSessionRepository();
      createSession(repository);

      expect(
        () => repository.transition(
          sessionId: 'session-1',
          to: RepairSessionState.verification,
          historyEntryId: 'history-1',
          reason: 'Illegal skip',
          triggeredBy: SessionTransitionTrigger.system,
          occurredAt: startedAt.add(const Duration(minutes: 1)),
        ),
        throwsStateError,
      );

      expect(
        repository.getSession('session-1')!.currentState,
        RepairSessionState.newSession,
      );
    });

    test('Safety Engine can escalate from an active state', () {
      final repository = RepairSessionRepository();
      createSession(repository);

      final escalated = repository.transition(
        sessionId: 'session-1',
        to: RepairSessionState.escalated,
        historyEntryId: 'history-1',
        reason: 'Safety hard stop',
        triggeredBy: SessionTransitionTrigger.safetyEngine,
        occurredAt: startedAt.add(const Duration(minutes: 1)),
      );

      expect(escalated.currentState, RepairSessionState.escalated);
      expect(escalated.endedAt, isNotNull);
    });

    test('evidence cannot be added after a terminal state', () {
      final repository = RepairSessionRepository();
      createSession(repository);

      repository.transition(
        sessionId: 'session-1',
        to: RepairSessionState.abandoned,
        historyEntryId: 'history-1',
        reason: 'User left',
        triggeredBy: SessionTransitionTrigger.user,
        occurredAt: startedAt.add(const Duration(minutes: 1)),
      );

      final evidence = Evidence(
        id: 'evidence-1',
        sessionId: 'session-1',
        applianceId: 'appliance-1',
        type: EvidenceType.textObservation,
        observation: 'The dryer is not heating.',
        collectedAt: startedAt.add(const Duration(minutes: 2)),
        collectedInState: RepairSessionState.abandoned,
        source: EvidenceSource.user,
        schemaVersion: '1.0',
      );

      expect(
        () => repository.addEvidence(
          evidence: evidence,
          evidenceLinkId: 'evidence-link-1',
        ),
        throwsStateError,
      );
      expect(repository.evidenceForSession('session-1'), isEmpty);
    });

    test('reviseObservationFromTemplate truncates downstream evidence', () {
      final repository = RepairSessionRepository();
      createSession(repository);
      for (var index = 0; index < 4; index++) {
        repository.transition(
          sessionId: 'session-1',
          to: const [
            RepairSessionState.selectAppliance,
            RepairSessionState.problemReported,
            RepairSessionState.basicConditionVerification,
            RepairSessionState.evidenceCollection,
          ][index],
          historyEntryId: 'history-${index + 1}',
          reason: 'Reach evidence collection',
          triggeredBy: SessionTransitionTrigger.system,
          occurredAt: startedAt.add(Duration(minutes: index + 1)),
        );
      }

      Evidence add({
        required String id,
        required String templateId,
        required String answer,
        required Duration offset,
      }) {
        return repository.addEvidence(
          evidence: Evidence(
            id: id,
            sessionId: 'session-1',
            applianceId: 'appliance-1',
            type: EvidenceType.structuredAnswer,
            observation: templateId,
            answer: answer,
            templateId: templateId,
            collectedAt: startedAt.add(offset),
            collectedInState: RepairSessionState.evidenceCollection,
            source: EvidenceSource.user,
            schemaVersion: '1.0',
          ),
          evidenceLinkId: 'link-$id',
        );
      }

      add(
        id: 'evidence-1',
        templateId: 'drum-turns',
        answer: 'Turns normally',
        offset: const Duration(minutes: 5),
      );
      add(
        id: 'evidence-2',
        templateId: 'heat-observed',
        answer: 'No warmth',
        offset: const Duration(minutes: 6),
      );
      add(
        id: 'evidence-3',
        templateId: 'close-verify-thermal-fuse-open',
        answer: 'Confirmed',
        offset: const Duration(minutes: 7),
      );

      repository.addHypothesis(
        Hypothesis(
          id: 'hypothesis-1',
          sessionId: 'session-1',
          failureModeId: 'thermal-fuse-open',
          label: 'Thermal fuse open',
          currentConfidence: 0,
          status: HypothesisStatus.confirmed,
          schemaVersion: '1.0',
        ),
      );

      repository.reviseObservationFromTemplate(
        sessionId: 'session-1',
        fromTemplateId: 'drum-turns',
        replacementEvidence: Evidence(
          id: 'evidence-1b',
          sessionId: 'session-1',
          applianceId: 'appliance-1',
          type: EvidenceType.structuredAnswer,
          observation: 'drum-turns',
          answer: 'Does not turn',
          templateId: 'drum-turns',
          collectedAt: startedAt.add(const Duration(minutes: 8)),
          collectedInState: RepairSessionState.evidenceCollection,
          source: EvidenceSource.user,
          schemaVersion: '1.0',
        ),
        evidenceLinkId: 'link-evidence-1b',
      );

      final evidence = repository.evidenceForSession('session-1');
      expect(evidence, hasLength(1));
      expect(evidence.single.templateId, 'drum-turns');
      expect(evidence.single.answer, 'Does not turn');
      expect(
        evidence.map((item) => item.templateId),
        isNot(contains('close-verify-thermal-fuse-open')),
      );

      final hypothesis = repository.hypothesesForSession('session-1').single;
      expect(hypothesis.status, HypothesisStatus.ruledOut);
    });
  });
}
