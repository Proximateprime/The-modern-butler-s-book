import '../helpers/failure_mode_standing.dart';
import '../helpers/observation_prompt_quality.dart';
import '../helpers/package_authoring_index.dart';
import '../models/appliance.dart';
import '../models/decision_context.dart';
import '../models/evidence.dart';
import '../models/knowledge_package.dart';

export '../helpers/failure_mode_standing.dart'
    show
        FailureModeRankLabel,
        FailureModeStanding,
        countDiscriminatingSupportByMode,
        leadingFailureModeIdForClosePath;

/// Immutable ranking snapshot from package answer effects.
class RankingSnapshot {
  const RankingSnapshot({
    required this.standings,
    required this.orderedFailureModes,
    required this.clearLeaderFailureModeId,
    required this.recommendPrimaryFailureModeId,
    required this.topFailureModeIds,
    required this.supportedFailureModeIds,
  });

  final Map<String, FailureModeStanding> standings;
  final List<FailureMode> orderedFailureModes;
  final String? clearLeaderFailureModeId;
  final String? recommendPrimaryFailureModeId;
  final List<String> topFailureModeIds;
  final Set<String> supportedFailureModeIds;
}

/// Thin deterministic boundary for failure-mode ranking / standing.
///
/// Wraps existing standing helpers. Does not select Primary, read photos,
/// or call LLMs.
class RankingService {
  const RankingService();

  RankingSnapshot evaluate({
    required KnowledgePackage package,
    required List<Evidence> evidence,
    PackageAuthoringIndex? authoringIndex,
    ApplianceEnergySource energySource = ApplianceEnergySource.unknown,
  }) {
    final standings = evaluateFailureModeStandings(
      package: package,
      evidence: evidence,
      energySource: energySource,
    );
    final activeFamilies = inferActiveObservationFamilies(
      recordedEvidence: evidence,
      templates: package.evidenceTemplates,
      authoringIndex: authoringIndex,
    );
    final discriminatingSupport = countDiscriminatingSupportByMode(
      package: package,
      evidence: evidence,
    );
    final commonalityById = {
      for (final mode in package.failureModes) mode.id: mode.commonality,
    };
    final ordered = orderFailureModesByStanding(
      failureModes: package.failureModes,
      standings: standings,
      authoringIndex: authoringIndex,
      activeFamilies: activeFamilies,
      discriminatingSupportCounts: discriminatingSupport,
    );
    final topIds = topSupportedFailureModeIds(
      standings: standings,
      authoringIndex: authoringIndex,
      activeFamilies: activeFamilies,
      discriminatingSupportCounts: discriminatingSupport,
      commonalityByModeId: commonalityById,
    );
    final supportedIds = {
      for (final entry in standings.entries)
        if (entry.value.isSupported) entry.key,
    };
    return RankingSnapshot(
      standings: standings,
      orderedFailureModes: ordered,
      clearLeaderFailureModeId: clearLeaderFailureModeId(
        standings: standings,
        commonalityByModeId: commonalityById,
      ),
      recommendPrimaryFailureModeId: recommendPrimaryFailureModeId(
        standings: standings,
        evidence: evidence,
        templates: package.evidenceTemplates,
        commonalityByModeId: commonalityById,
      ),
      topFailureModeIds: topIds,
      supportedFailureModeIds: supportedIds,
    );
  }

  /// Same ranking math as [evaluate], using one session [DecisionContext].
  RankingSnapshot evaluateContext(DecisionContext context) {
    final package = context.package;
    if (package == null) {
      return const RankingSnapshot(
        standings: {},
        orderedFailureModes: [],
        clearLeaderFailureModeId: null,
        recommendPrimaryFailureModeId: null,
        topFailureModeIds: [],
        supportedFailureModeIds: {},
      );
    }
    return evaluate(
      package: package,
      evidence: context.evidence,
      authoringIndex: context.authoringIndex,
    );
  }
}
