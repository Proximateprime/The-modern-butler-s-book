import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/helpers/dryer_close_path.dart';
import 'package:modern_butlers_book/helpers/failure_mode_standing.dart';
import 'package:modern_butlers_book/helpers/observation_prompt_quality.dart';
import 'package:modern_butlers_book/helpers/safety_stop.dart';
import 'package:modern_butlers_book/helpers/suggest_next_observation.dart';
import 'package:modern_butlers_book/models/evidence.dart';
import 'package:modern_butlers_book/models/repair_session.dart';
import 'package:modern_butlers_book/services/close_path_policy_service.dart';
import 'package:modern_butlers_book/services/diagnostic_reasoning.dart';
import 'package:modern_butlers_book/services/knowledge_package_repository.dart';
import 'package:modern_butlers_book/services/question_selection_service.dart';
import 'package:modern_butlers_book/services/ranking_service.dart';
import 'package:modern_butlers_book/services/safety_decision_service.dart';

/// Proves thin services match the existing helper implementations exactly.
void main() {
  final package = KnowledgePackageRepository().loadById('dryer-core')!;
  const questions = QuestionSelectionService();
  const ranking = RankingService();
  const safety = SafetyDecisionService();
  const closePath = ClosePathPolicyService();
  const reasoning = DiagnosticReasoning();

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
      collectedAt: DateTime.utc(2026, 7, 24),
      collectedInState: RepairSessionState.evidenceCollection,
      source: EvidenceSource.user,
      schemaVersion: '1.0',
    );
  }

  final noHeatEvidence = [
    evidence(
      templateId: 'drum-turns',
      observation: 'Does the drum turn during the cycle?',
      answer: 'Turns normally',
    ),
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
    evidence(
      templateId: 'recent-overheat',
      observation:
          'Has the dryer recently overheated, shut off mid-cycle from '
          'heat, or been used with a badly clogged vent?',
      answer: 'No',
    ),
  ];

  test('RankingService matches helper standings and clear leader', () {
    final repo = KnowledgePackageRepository();
    final authoringIndex = repo.authoringIndexFor('dryer-core');
    final viaHelperStandings = evaluateFailureModeStandings(
      package: package,
      evidence: noHeatEvidence,
    );
    final discriminatingSupport = countDiscriminatingSupportByMode(
      package: package,
      evidence: noHeatEvidence,
    );
    final activeFamilies = inferActiveObservationFamilies(
      recordedEvidence: noHeatEvidence,
      templates: package.evidenceTemplates,
      authoringIndex: authoringIndex,
    );
    final viaHelperOrdered = orderFailureModesByStanding(
      failureModes: package.failureModes,
      standings: viaHelperStandings,
      authoringIndex: authoringIndex,
      activeFamilies: activeFamilies,
      discriminatingSupportCounts: discriminatingSupport,
    );
    final viaService = ranking.evaluate(
      package: package,
      evidence: noHeatEvidence,
      authoringIndex: authoringIndex,
    );

    expect(viaService.standings.keys, viaHelperStandings.keys);
    for (final id in viaHelperStandings.keys) {
      expect(viaService.standings[id]!.supportCount, viaHelperStandings[id]!.supportCount);
      expect(viaService.standings[id]!.excludeCount, viaHelperStandings[id]!.excludeCount);
    }
    expect(
      viaService.orderedFailureModes.map((mode) => mode.id),
      viaHelperOrdered.map((mode) => mode.id),
    );
    expect(
      viaService.clearLeaderFailureModeId,
      clearLeaderFailureModeId(
        standings: viaHelperStandings,
        commonalityByModeId: {
          for (final mode in package.failureModes) mode.id: mode.commonality,
        },
      ),
    );
    expect(
      viaService.topFailureModeIds,
      topSupportedFailureModeIds(
        standings: viaHelperStandings,
        authoringIndex: authoringIndex,
        activeFamilies: activeFamilies,
        discriminatingSupportCounts: discriminatingSupport,
        commonalityByModeId: {
          for (final mode in package.failureModes) mode.id: mode.commonality,
        },
      ),
    );
  });

  test('RankingService session path handles resumed-style evidence without crash', () {
    final repo = KnowledgePackageRepository();
    final authoringIndex = repo.authoringIndexFor('dryer-core');
    final resumedStyleEvidence = [
      evidence(
        templateId: 'dryer-response',
        observation: 'What happens when you start a cycle?',
        answer: 'Runs but no heat',
      ),
      evidence(
        templateId: 'drum-turns',
        observation: 'Does the drum turn during the cycle?',
        answer: 'Turns normally',
      ),
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
      evidence(
        templateId: 'recent-overheat',
        observation:
            'Has the dryer recently overheated, shut off mid-cycle from '
            'heat, or been used with a badly clogged vent?',
        answer: 'No',
      ),
    ];

    expect(countDiscriminatingSupportByMode, isNotNull);

    final viaRanking = ranking.evaluate(
      package: package,
      evidence: resumedStyleEvidence,
      authoringIndex: authoringIndex,
    );
    final viaReasoning = reasoning.evaluate(
      package: package,
      evidence: resumedStyleEvidence,
      primaryFailureModeId: 'heating-element-failed',
      safetyStopActive: false,
      authoringIndex: authoringIndex,
    );

    expect(viaRanking.orderedFailureModes, isNotEmpty);
    expect(viaRanking.standings, isNotEmpty);
    expect(viaReasoning?.orderedFailureModes.map((m) => m.id),
        viaRanking.orderedFailureModes.map((m) => m.id));
  });

  test('QuestionSelectionService matches suggestNextObservation', () {
    final ranked = ranking.evaluate(package: package, evidence: noHeatEvidence);
    final viaHelper = suggestNextObservation(
      templates: package.evidenceTemplates,
      recordedEvidence: noHeatEvidence,
      topFailureModeIds: ranked.topFailureModeIds,
      evidenceMatchedFailureModeIds: ranked.supportedFailureModeIds,
    );
    final viaService = questions.suggestNext(
      templates: package.evidenceTemplates,
      recordedEvidence: noHeatEvidence,
      topFailureModeIds: ranked.topFailureModeIds,
      evidenceMatchedFailureModeIds: ranked.supportedFailureModeIds,
    );
    expect(viaService?.id, viaHelper?.id);
  });

  test('SafetyDecisionService matches evaluateSafetyStop', () {
    final hazard = [
      evidence(
        templateId: 'hazard-observation',
        observation:
            'Do you observe a burning smell or smoke?',
        answer: 'Yes',
      ),
    ];
    expect(
      safety.evaluate(evidence: hazard)?.reason,
      evaluateSafetyStop(evidence: hazard)?.reason,
    );
    expect(
      safety.evaluate(
        evidence: const [],
        primaryFailureModeId: 'thermal-fuse-open',
      ),
      evaluateSafetyStop(
        evidence: const [],
        primaryFailureModeId: 'thermal-fuse-open',
      ),
    );
    expect(
      safety.evaluate(
        evidence: const [],
        primaryFailureModeId: 'electric-supply-connection-fault',
      )?.reason,
      evaluateSafetyStop(
        evidence: const [],
        primaryFailureModeId: 'electric-supply-connection-fault',
      )?.reason,
    );
  });

  test('ClosePathPolicyService matches dryer close-path helpers', () {
    expect(
      closePath.pathForFailureMode('heating-element-failed')?.failureModeId,
      closePathForFailureMode('heating-element-failed')?.failureModeId,
    );
    expect(
      closePath.pathForFailureMode('thermal-fuse-open')?.verificationAsk,
      closePathForFailureMode('thermal-fuse-open')?.verificationAsk,
    );
    expect(
      closePath.outcomeFromAnswer('Confirmed'),
      verificationOutcomeFromCloseAnswer('Confirmed'),
    );
    expect(
      closePath.outcomeFromAnswer('Not confirmed'),
      verificationOutcomeFromCloseAnswer('Not confirmed'),
    );

    final pending = closePath.outcomeForPrimary(
      evidence: noHeatEvidence,
      primaryFailureModeId: 'heating-element-failed',
    );
    expect(pending, VerificationOutcome.pending);

    final withVerify = [
      ...noHeatEvidence,
      Evidence(
        id: 'e-close',
        sessionId: 'session-1',
        applianceId: 'appliance-1',
        type: EvidenceType.structuredAnswer,
        observation: closePathForFailureMode('heating-element-failed')!.verificationAsk,
        answer: 'Confirmed',
        templateId: closeVerificationTemplateId('heating-element-failed'),
        collectedAt: DateTime.utc(2026, 7, 24),
        collectedInState: RepairSessionState.verification,
        source: EvidenceSource.user,
        schemaVersion: '1.0',
      ),
    ];
    expect(
      closePath.outcomeForPrimary(
        evidence: withVerify,
        primaryFailureModeId: 'heating-element-failed',
      ),
      VerificationOutcome.supported,
    );
    expect(
      closePath.resolveEligibility(
        safetyStopActive: false,
        primaryFailureModeId: 'heating-element-failed',
        verificationOutcome: VerificationOutcome.supported,
        closePath: closePath.pathForFailureMode('heating-element-failed'),
      ),
      closeResolveEligibility(
        safetyStopActive: false,
        primaryFailureModeId: 'heating-element-failed',
        verificationOutcome: VerificationOutcome.supported,
        closePath: closePathForFailureMode('heating-element-failed'),
      ),
    );
  });

  test('DiagnosticReasoning composed services match prior evaluate shape', () {
    final result = reasoning.evaluate(
      package: package,
      evidence: noHeatEvidence,
      primaryFailureModeId: 'heating-element-failed',
    );
    final ranked = ranking.evaluate(package: package, evidence: noHeatEvidence);
    final suggested = questions.suggestNext(
      templates: package.evidenceTemplates,
      recordedEvidence: noHeatEvidence,
      primaryFailureModeId: 'heating-element-failed',
      evidenceMatchedFailureModeIds: ranked.supportedFailureModeIds,
      topFailureModeIds: ranked.topFailureModeIds,
    );
    expect(result.clearLeaderFailureModeId, ranked.clearLeaderFailureModeId);
    expect(result.suggestedNextTemplateId, suggested?.id);
    expect(result.closePath?.failureModeId, 'heating-element-failed');
    expect(result.verificationOutcome, VerificationOutcome.pending);
    expect(
      result.resolveEligibility,
      CloseResolveEligibility.pendingVerification,
    );
  });
}
