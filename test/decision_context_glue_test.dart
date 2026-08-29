import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/models/decision_context.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/knowledge_package_ref.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/diagnostic_reasoning.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/ranking_service.dart';
import 'package:modern_butlers_book/services/safety_decision_service.dart';

void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;
  const ranking = RankingService();
  const reasoning = DiagnosticReasoning();
  const safety = SafetyDecisionService();

  Evidence evidence({
    required String templateId,
    required String observation,
    required String answer,
  }) {
    return Evidence(
      id: 'e-$templateId-$answer',
      sessionId: 'session-1',
      applianceId: 'appliance-1',
      type: EvidenceType.structuredAnswer,
      observation: observation,
      answer: answer,
      templateId: templateId,
      collectedAt: DateTime.utc(2026, 8, 17),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  final recorded = [
    evidence(
      templateId: 'heat-observed',
      observation: 'Is there any warmth after the dryer has run briefly?',
      answer: 'No warmth',
    ),
    evidence(
      templateId: 'cycle-heat-setting',
      observation:
          'Is the dryer set to a heat cycle rather than air-only / fluff?',
      answer: 'Yes, heat cycle',
    ),
  ];

  DecisionContext contextFor(List<Evidence> items) {
    final session = RepairSession(
      id: 'session-1',
      applianceId: 'appliance-1',
      householdId: 'household-1',
      currentState: RepairSessionState.evidenceCollection,
      startedAt: DateTime.utc(2026, 8, 17),
      lastActivityAt: DateTime.utc(2026, 8, 17),
      createdByUserId: 'user-1',
      packageId: package.id,
      packageVersion: package.version,
      schemaVersion: '1.0',
      stateHistory: const [],
    );
    return DecisionContext.fromSession(
      session: session,
      evidence: items,
      packageRef: KnowledgePackageRef.fromPackage(package),
      package: package,
      authoringIndex: KnowledgePackageRepository().authoringIndexFor(package.id),
    );
  }

  test('evaluateContext matches evaluate ranking outputs', () {
    final repo = KnowledgePackageRepository();
    final authoring = repo.authoringIndexFor(package.id);
    final context = contextFor(recorded);
    final viaParts = ranking.evaluate(
      package: package,
      evidence: recorded,
      authoringIndex: authoring,
    );
    final viaContext = ranking.evaluateContext(context);
    expect(viaContext.clearLeaderFailureModeId, viaParts.clearLeaderFailureModeId);
    expect(
      viaContext.recommendPrimaryFailureModeId,
      viaParts.recommendPrimaryFailureModeId,
    );
    expect(viaContext.topFailureModeIds, viaParts.topFailureModeIds);
    expect(viaContext.supportedFailureModeIds, viaParts.supportedFailureModeIds);
    expect(viaContext.orderedFailureModes.map((mode) => mode.id).toList(),
        viaParts.orderedFailureModes.map((mode) => mode.id).toList());
    for (final id in viaParts.standings.keys) {
      expect(viaContext.standings[id]!.supportCount, viaParts.standings[id]!.supportCount);
      expect(viaContext.standings[id]!.excludeCount, viaParts.standings[id]!.excludeCount);
    }
  });

  test('reasoning evaluateContext matches evaluate', () {
    final authoring = KnowledgePackageRepository().authoringIndexFor(package.id);
    final context = contextFor(recorded);
    final viaParts = reasoning.evaluate(
      package: package,
      evidence: recorded,
      authoringIndex: authoring,
    );
    final viaContext = reasoning.evaluateContext(context)!;
    expect(viaContext.suggestedNextTemplateId, viaParts.suggestedNextTemplateId);
    expect(viaContext.clearLeaderFailureModeId, viaParts.clearLeaderFailureModeId);
    expect(viaContext.closePath?.failureModeId, viaParts.closePath?.failureModeId);
  });

  test('safety evaluateContext matches evaluate', () {
    final context = contextFor(recorded);
    expect(
      safety.evaluateContext(context)?.reason,
      safety.evaluate(evidence: recorded)?.reason,
    );
  });
}
