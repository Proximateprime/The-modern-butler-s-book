import '../helpers/failure_mode_standing.dart' show leadingFailureModeIdForClosePath;
import '../helpers/package_authoring_index.dart';
import '../models/appliance.dart';
import '../models/decision_context.dart';
import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'close_path_policy_service.dart';
import 'question_selection_service.dart';
import 'ranking_service.dart';

export 'close_path_policy_service.dart'
    show
        ClosePathPolicyService,
        CloseResolveEligibility,
        FailureModeClosePath,
        VerificationOutcome,
        closeVerificationChoices,
        closeVerificationTemplateId;
export 'ranking_service.dart'
    show FailureModeRankLabel, FailureModeStanding, RankingService;

/// Thin deterministic Reasoning boundary for the dryer vertical slice.
///
/// Composes ranking, question selection, and close-path policy services.
/// Owns no UI, persistence, learning, or LLM calls.
class DiagnosticReasoning {
  const DiagnosticReasoning({
    this.ranking = const RankingService(),
    this.questions = const QuestionSelectionService(),
    this.closePathPolicy = const ClosePathPolicyService(),
  });

  final RankingService ranking;
  final QuestionSelectionService questions;
  final ClosePathPolicyService closePathPolicy;

  DiagnosticReasoningResult evaluate({
    required KnowledgePackage package,
    required List<Evidence> evidence,
    String? primaryFailureModeId,
    bool safetyStopActive = false,
    PackageAuthoringIndex? authoringIndex,
    ApplianceEnergySource energySource = ApplianceEnergySource.unknown,
    Set<String> starterMatchedSymptomIds = const {},
  }) {
    final ranked = ranking.evaluate(
      package: package,
      evidence: evidence,
      authoringIndex: authoringIndex,
      energySource: energySource,
    );
    final suggested = questions.suggestNext(
      templates: package.evidenceTemplates,
      recordedEvidence: evidence,
      primaryFailureModeId: primaryFailureModeId,
      evidenceMatchedFailureModeIds: ranked.supportedFailureModeIds,
      topFailureModeIds: ranked.topFailureModeIds,
      authoringIndex: authoringIndex,
      starterMatchedSymptomIds: starterMatchedSymptomIds,
      energySource: energySource,
    );
    final authoredModeIds = {
      for (final mode in package.failureModes) mode.id,
    };
    final closePathFailureModeId = leadingFailureModeIdForClosePath(
      standings: ranked.standings,
      evidence: evidence,
      templates: package.evidenceTemplates,
      confirmedPrimaryFailureModeId: primaryFailureModeId,
      rankingLeaderFailureModeId:
          ranked.clearLeaderFailureModeId ??
          ranked.recommendPrimaryFailureModeId,
      commonalityByModeId: {
        for (final mode in package.failureModes) mode.id: mode.commonality,
      },
    );
    final authoredCloseId =
        closePathFailureModeId != null &&
                authoredModeIds.contains(closePathFailureModeId)
            ? closePathFailureModeId
            : null;
    final closePath =
        authoredCloseId == null
            ? null
            : closePathPolicy.pathForFailureMode(authoredCloseId);
    final verificationOutcome = closePathPolicy.outcomeForPrimary(
      evidence: evidence,
      primaryFailureModeId: authoredCloseId,
    );

    return DiagnosticReasoningResult(
      standings: ranked.standings,
      orderedFailureModes: ranked.orderedFailureModes,
      clearLeaderFailureModeId: ranked.clearLeaderFailureModeId,
      recommendPrimaryFailureModeId: ranked.recommendPrimaryFailureModeId,
      topFailureModeIds: ranked.topFailureModeIds,
      suggestedNextTemplateId: suggested?.id,
      closePath: closePath,
      verificationOutcome: verificationOutcome,
      resolveEligibility: closePathPolicy.resolveEligibility(
        safetyStopActive: safetyStopActive,
        primaryFailureModeId: authoredCloseId,
        verificationOutcome: verificationOutcome,
        closePath: closePath,
      ),
    );
  }

  /// Same composition as [evaluate], using one session [DecisionContext].
  DiagnosticReasoningResult? evaluateContext(
    DecisionContext context, {
    bool safetyStopActive = false,
    ApplianceEnergySource energySource = ApplianceEnergySource.unknown,
    Set<String> starterMatchedSymptomIds = const {},
  }) {
    final package = context.package;
    if (package == null) {
      return null;
    }
    return evaluate(
      package: package,
      evidence: context.evidence,
      primaryFailureModeId: context.primaryFailureModeId,
      safetyStopActive: safetyStopActive,
      authoringIndex: context.authoringIndex,
      energySource: energySource,
      starterMatchedSymptomIds: starterMatchedSymptomIds,
    );
  }
}

/// Snapshot returned by [DiagnosticReasoning.evaluate].
class DiagnosticReasoningResult {
  const DiagnosticReasoningResult({
    required this.standings,
    required this.orderedFailureModes,
    required this.clearLeaderFailureModeId,
    required this.recommendPrimaryFailureModeId,
    required this.topFailureModeIds,
    required this.suggestedNextTemplateId,
    required this.closePath,
    required this.verificationOutcome,
    required this.resolveEligibility,
  });

  final Map<String, FailureModeStanding> standings;
  final List<FailureMode> orderedFailureModes;
  final String? clearLeaderFailureModeId;
  final String? recommendPrimaryFailureModeId;
  final List<String> topFailureModeIds;
  final String? suggestedNextTemplateId;
  final FailureModeClosePath? closePath;
  final VerificationOutcome verificationOutcome;
  final CloseResolveEligibility resolveEligibility;

  bool get canResolveAsFixed =>
      resolveEligibility == CloseResolveEligibility.allowResolved;

  bool get prefersProfessional =>
      resolveEligibility == CloseResolveEligibility.needsProfessional ||
      resolveEligibility == CloseResolveEligibility.safetyStop;
}
