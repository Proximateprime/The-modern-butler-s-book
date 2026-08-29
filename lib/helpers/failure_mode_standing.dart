import '../models/appliance.dart';
import '../models/evidence.dart';
import '../models/knowledge_package.dart';
import 'dryer_energy_source.dart';
import 'dryer_problem_starter.dart';
import 'evidence_prompt_match.dart';
import 'observation_prompt_quality.dart';
import 'package_authoring_index.dart';
import 'power_steering.dart';

export 'evidence_prompt_match.dart' show normalizeObservationAnswer;

/// Deterministic presentation bucket for one failure mode.
enum FailureModeRankLabel {
  strongerMatch,
  possible,
  lessLikely,
  unset,
}

/// Deterministic support/exclude standing for one failure mode.
///
/// Integer counts only — not probabilities or confidence scores.
class FailureModeStanding {
  const FailureModeStanding({
    required this.supportCount,
    required this.excludeCount,
  });

  final int supportCount;
  final int excludeCount;

  int get net => supportCount - excludeCount;

  bool get isSupported => supportCount > excludeCount;

  bool get isWeakened => excludeCount > supportCount;

  /// Visible rank label. No percentages.
  FailureModeRankLabel get rankLabel {
    if (net >= 2) {
      return FailureModeRankLabel.strongerMatch;
    }
    if (isSupported) {
      return FailureModeRankLabel.possible;
    }
    if (isWeakened) {
      return FailureModeRankLabel.lessLikely;
    }
    return FailureModeRankLabel.unset;
  }

  String get rankLabelText {
    return switch (rankLabel) {
      FailureModeRankLabel.strongerMatch => 'Stronger match',
      FailureModeRankLabel.possible => 'Possible',
      FailureModeRankLabel.lessLikely =>
        'Less likely given current evidence',
      FailureModeRankLabel.unset => 'Possible',
    };
  }
}

/// Applies package answer effects to accumulate support/exclude counts.
///
/// For each recorded answer, looks up the matching template's
/// [EvidenceTemplate.supportByAnswer] / [excludeByAnswer] for that answer
/// label (base choice before an optional "Other / describe: ..." note).
/// Missing maps or unmapped answers are neutral.
Map<String, FailureModeStanding> evaluateFailureModeStandings({
  required KnowledgePackage package,
  required List<Evidence> evidence,
  ApplianceEnergySource energySource = ApplianceEnergySource.unknown,
}) {
  final support = <String, int>{
    for (final mode in package.failureModes) mode.id: 0,
  };
  final exclude = <String, int>{
    for (final mode in package.failureModes) mode.id: 0,
  };

  for (final item in evidence) {
    if (item.type == EvidenceType.photo) {
      continue;
    }
    EvidenceTemplate? template;
    for (final candidate in package.evidenceTemplates) {
      if (evidenceMatchesTemplate(item, candidate)) {
        template = candidate;
        break;
      }
    }
    if (template == null) {
      continue;
    }

    final answerKey = normalizeObservationAnswer(item.answer);
    if (answerKey == null) {
      continue;
    }

    for (final id in template.supportByAnswer[answerKey] ?? const <String>[]) {
      if (support.containsKey(id)) {
        support[id] = support[id]! + 1;
      }
    }
    for (final id in template.excludeByAnswer[answerKey] ?? const <String>[]) {
      if (exclude.containsKey(id)) {
        exclude[id] = exclude[id]! + 1;
      }
    }
  }

  _applyStarterNoHeatAsNoWarmth(
    package: package,
    evidence: evidence,
    support: support,
    exclude: exclude,
  );

  return applyFuelTypeSteering(
    standings: applyHeatPolaritySteering(
      standings: applyPowerFineSteering(
        standings: {
          for (final mode in package.failureModes)
            mode.id: FailureModeStanding(
              supportCount: support[mode.id]!,
              excludeCount: exclude[mode.id]!,
            ),
        },
        evidence: evidence,
      ),
      evidence: evidence,
    ),
    evidence: evidence,
    energySource: energySource,
  );
}

/// Applies contextual down-ranking when live evidence contradicts dead-supply
/// narratives (panel alive, breaker on, machine runs).
Map<String, FailureModeStanding> applyPowerFineSteering({
  required Map<String, FailureModeStanding> standings,
  required List<Evidence> evidence,
}) {
  if (!shouldDeemphasizeDeadPowerModes(evidence)) {
    return standings;
  }

  return {
    for (final entry in standings.entries)
      entry.key: deadPowerFailureModeIds.contains(entry.key)
          ? FailureModeStanding(
              supportCount: entry.value.supportCount,
              excludeCount: entry.value.excludeCount + 2,
            )
          : entry.value,
  };
}

/// Down-ranks no-heat modes when the live path is ongoing excess heat.
Map<String, FailureModeStanding> applyHeatPolaritySteering({
  required Map<String, FailureModeStanding> standings,
  required List<Evidence> evidence,
}) {
  if (!shouldDeemphasizeNoHeatModes(evidence)) {
    return standings;
  }

  return {
    for (final entry in standings.entries)
      entry.key: noHeatFailureModeIds.contains(entry.key)
          ? FailureModeStanding(
              supportCount: entry.value.supportCount,
              excludeCount: entry.value.excludeCount + 2,
            )
          : entry.value,
  };
}

/// Down-ranks electric heat-generation modes on a confirmed gas dryer.
///
/// Does not rewrite ranking math: extra exclude counts only. Thermal fuse is
/// included so it is not treated as the default heating-element path on gas.
Map<String, FailureModeStanding> applyFuelTypeSteering({
  required Map<String, FailureModeStanding> standings,
  required List<Evidence> evidence,
  ApplianceEnergySource energySource = ApplianceEnergySource.unknown,
}) {
  var fuel = normalizeObservationAnswer(
    answerForTemplate(
      recordedEvidence: evidence,
      templateId: gasDryerTypeTemplateId,
    ),
  );
  fuel ??= gasDryerTypeAnswerFor(energySource);
  if (fuel == gasDryerTypeGasAnswer) {
    return {
      for (final entry in standings.entries)
        entry.key: electricHeatGenerationModeIds.contains(entry.key)
            ? FailureModeStanding(
                supportCount: entry.value.supportCount,
                excludeCount: entry.value.excludeCount + 3,
              )
            : entry.value,
    };
  }
  if (fuel == gasDryerTypeElectricAnswer) {
    const gasMode = 'gas-dryer-no-ignition-professional-only';
    final current = standings[gasMode];
    if (current == null) {
      return standings;
    }
    return {
      ...standings,
      gasMode: FailureModeStanding(
        supportCount: current.supportCount,
        excludeCount: current.excludeCount + 2,
      ),
    };
  }
  return standings;
}

/// Counts support hits from non-generic interview templates only.
Map<String, int> countDiscriminatingSupportByMode({
  required KnowledgePackage package,
  required List<Evidence> evidence,
}) {
  final counts = <String, int>{
    for (final mode in package.failureModes) mode.id: 0,
  };

  for (final item in evidence) {
    if (item.type == EvidenceType.photo) {
      continue;
    }
    final templateId = _interviewTemplateId(item, package.evidenceTemplates);
    if (templateId == null ||
        genericInterviewTemplateIds.contains(templateId)) {
      continue;
    }

    EvidenceTemplate? template;
    for (final candidate in package.evidenceTemplates) {
      if (evidenceMatchesTemplate(item, candidate)) {
        template = candidate;
        break;
      }
    }
    if (template == null) {
      continue;
    }

    final answerKey = normalizeObservationAnswer(item.answer);
    if (answerKey == null) {
      continue;
    }

    for (final id in template.supportByAnswer[answerKey] ?? const <String>[]) {
      if (counts.containsKey(id)) {
        counts[id] = counts[id]! + 1;
      }
    }
  }

  _applyStarterNoHeatAsNoWarmth(
    package: package,
    evidence: evidence,
    support: counts,
    exclude: <String, int>{},
  );

  return counts;
}

/// Session-start "No heat" applies the same package effects as "No warmth".
void _applyStarterNoHeatAsNoWarmth({
  required KnowledgePackage package,
  required List<Evidence> evidence,
  required Map<String, int> support,
  required Map<String, int> exclude,
}) {
  if (!isNoHeatEstablishedFromStarter(recordedEvidence: evidence)) {
    return;
  }
  if (isTemplateRecordedById(
    templateId: 'heat-observed',
    recordedEvidence: evidence,
  )) {
    return;
  }

  EvidenceTemplate? heatObserved;
  for (final template in package.evidenceTemplates) {
    if (template.id == 'heat-observed') {
      heatObserved = template;
      break;
    }
  }
  if (heatObserved == null) {
    return;
  }

  for (final id in heatObserved.supportByAnswer['No warmth'] ?? const <String>[]) {
    if (support.containsKey(id)) {
      support[id] = support[id]! + 1;
    }
  }
  for (final id in heatObserved.excludeByAnswer['No warmth'] ?? const <String>[]) {
    if (exclude.containsKey(id)) {
      exclude[id] = exclude[id]! + 1;
    }
  }
}

/// Orders failure modes by net support (desc), then commonality prior, then
/// stronger buckets, then package order.
List<FailureMode> orderFailureModesByStanding({
  required List<FailureMode> failureModes,
  required Map<String, FailureModeStanding> standings,
  PackageAuthoringIndex? authoringIndex,
  Set<ObservationFamily>? activeFamilies,
  Map<String, int>? discriminatingSupportCounts,
}) {
  final commonalityById = {
    for (final mode in failureModes) mode.id: mode.commonality,
  };
  final indexed = [
    for (var i = 0; i < failureModes.length; i++) (i, failureModes[i]),
  ];
  indexed.sort((a, b) {
    final standingA = standings[a.$2.id];
    final standingB = standings[b.$2.id];
    final netA = standingA?.net ?? 0;
    final netB = standingB?.net ?? 0;
    final byNet = netB.compareTo(netA);
    if (byNet != 0) {
      return byNet;
    }
    final byCommonality = _commonalityRank(commonalityById[b.$2.id])
        .compareTo(_commonalityRank(commonalityById[a.$2.id]));
    if (byCommonality != 0) {
      return byCommonality;
    }
    final bucketA = _bucketRank(standingA);
    final bucketB = _bucketRank(standingB);
    final byBucket = bucketA.compareTo(bucketB);
    if (byBucket != 0) {
      return byBucket;
    }
    if (discriminatingSupportCounts != null) {
      final byDisc = (discriminatingSupportCounts[b.$2.id] ?? 0)
          .compareTo(discriminatingSupportCounts[a.$2.id] ?? 0);
      if (byDisc != 0) {
        return byDisc;
      }
    }
    if (authoringIndex != null &&
        activeFamilies != null &&
        activeFamilies.isNotEmpty) {
      final byFamily = authoringIndex
          .familyOverlapScore(b.$2.id, activeFamilies)
          .compareTo(
            authoringIndex.familyOverlapScore(a.$2.id, activeFamilies),
          );
      if (byFamily != 0) {
        return byFamily;
      }
    }
    return a.$1.compareTo(b.$1);
  });
  return [for (final item in indexed) item.$2];
}

/// Top supported mode ids (net > 0), strongest first, capped by [limit].
List<String> topSupportedFailureModeIds({
  required Map<String, FailureModeStanding> standings,
  int limit = 3,
  PackageAuthoringIndex? authoringIndex,
  Set<ObservationFamily>? activeFamilies,
  Map<String, int>? discriminatingSupportCounts,
  Map<String, FailureModeCommonality>? commonalityByModeId,
}) {
  final ranked =
      standings.entries.where((entry) => entry.value.net > 0).toList()
        ..sort((a, b) {
          final byNet = b.value.net.compareTo(a.value.net);
          if (byNet != 0) {
            return byNet;
          }
          if (commonalityByModeId != null) {
            final byCommonality = _commonalityRank(commonalityByModeId[b.key])
                .compareTo(_commonalityRank(commonalityByModeId[a.key]));
            if (byCommonality != 0) {
              return byCommonality;
            }
          }
          if (discriminatingSupportCounts != null) {
            final byDisc = (discriminatingSupportCounts[b.key] ?? 0)
                .compareTo(discriminatingSupportCounts[a.key] ?? 0);
            if (byDisc != 0) {
              return byDisc;
            }
          }
          if (authoringIndex != null &&
              activeFamilies != null &&
              activeFamilies.isNotEmpty) {
            final byFamily = authoringIndex
                .familyOverlapScore(b.key, activeFamilies)
                .compareTo(
                  authoringIndex.familyOverlapScore(a.key, activeFamilies),
                );
            if (byFamily != 0) {
              return byFamily;
            }
          }
          return a.key.compareTo(b.key);
        });
  return [
    for (final entry in ranked.take(limit)) entry.key,
  ];
}

/// Minimum meaningful interview answers before offering a soft primary recommendation.
const int minMeaningfulAnswersForRecommendPrimary = 4;

/// Minimum answers from non-generic templates (discriminating evidence).
const int minDiscriminatingAnswersForRecommendPrimary = 2;

/// Leader net must exceed runner-up net by at least this much to recommend Primary.
const int minRecommendPrimaryLeadMargin = 2;

/// Broad early prompts that alone rarely justify a recommendation.
const Set<String> genericInterviewTemplateIds = {
  'dryer-response',
  'drum-turns',
  'panel-lights',
};

/// Counts package interview answers with a mapped choice (excludes starter/hazard/verify).
int countMeaningfulInterviewAnswers({
  required List<Evidence> evidence,
  required List<EvidenceTemplate> templates,
}) {
  var count = 0;
  for (final item in evidence) {
    if (_interviewTemplateId(item, templates) != null) {
      count += 1;
    }
  }
  return count;
}

/// Counts meaningful answers on templates that narrow failure-mode families.
int countDiscriminatingInterviewAnswers({
  required List<Evidence> evidence,
  required List<EvidenceTemplate> templates,
}) {
  var count = 0;
  for (final item in evidence) {
    final templateId = _interviewTemplateId(item, templates);
    if (templateId == null) {
      continue;
    }
    if (genericInterviewTemplateIds.contains(templateId)) {
      continue;
    }
    count += 1;
  }
  return count;
}

/// Whether a soft primary recommendation may be shown (stricter than [clearLeaderFailureModeId]).
String? recommendPrimaryFailureModeId({
  required Map<String, FailureModeStanding> standings,
  required List<Evidence> evidence,
  required List<EvidenceTemplate> templates,
  Map<String, FailureModeCommonality>? commonalityByModeId,
}) {
  if (countMeaningfulInterviewAnswers(
        evidence: evidence,
        templates: templates,
      ) <
      minMeaningfulAnswersForRecommendPrimary) {
    return null;
  }
  if (countDiscriminatingInterviewAnswers(
        evidence: evidence,
        templates: templates,
      ) <
      minDiscriminatingAnswersForRecommendPrimary) {
    return null;
  }
  return clearLeaderFailureModeId(
    standings: standings,
    minLeadMargin: minRecommendPrimaryLeadMargin,
    commonalityByModeId: commonalityByModeId,
  );
}

/// Failure mode id that Safe Guidance and verification should follow.
///
/// Prefers the current ranking leader over a confirmed Primary when they
/// diverge, so close-path content cannot drift to a secondary mode.
String? leadingFailureModeIdForClosePath({
  required Map<String, FailureModeStanding> standings,
  required List<Evidence> evidence,
  required List<EvidenceTemplate> templates,
  String? confirmedPrimaryFailureModeId,
  String? rankingLeaderFailureModeId,
  Map<String, FailureModeCommonality>? commonalityByModeId,
}) {
  final rankingLeader =
      rankingLeaderFailureModeId ??
      clearLeaderFailureModeId(
        standings: standings,
        commonalityByModeId: commonalityByModeId,
      ) ??
      recommendPrimaryFailureModeId(
        standings: standings,
        evidence: evidence,
        templates: templates,
        commonalityByModeId: commonalityByModeId,
      );
  final fallbackIds = topSupportedFailureModeIds(
    standings: standings,
    limit: 5,
    commonalityByModeId: commonalityByModeId,
  );
  if (inferHeatPathPolarity(recordedEvidence: evidence) ==
      HeatPathPolarity.excessHeat) {
    for (final id in [
      if (rankingLeader != null) rankingLeader,
      if (confirmedPrimaryFailureModeId != null) confirmedPrimaryFailureModeId,
      ...fallbackIds,
    ]) {
      if (!noHeatFailureModeIds.contains(id)) {
        return id;
      }
    }
  }
  if (rankingLeader != null) {
    return rankingLeader;
  }
  if (confirmedPrimaryFailureModeId != null) {
    return confirmedPrimaryFailureModeId;
  }
  if (fallbackIds.isNotEmpty) {
    return fallbackIds.first;
  }
  return null;
}

String? _interviewTemplateId(
  Evidence item,
  List<EvidenceTemplate> templates,
) {
  if (normalizeObservationAnswer(item.answer) == null) {
    return null;
  }
  final explicitId = item.templateId;
  if (explicitId == problemStarterComplaintTemplateId ||
      explicitId == 'hazard-observation' ||
      explicitId == 'free-observation-note' ||
      (explicitId != null && explicitId.startsWith('close-verify-'))) {
    return null;
  }
  for (final template in templates) {
    if (evidenceMatchesTemplate(item, template)) {
      return template.id;
    }
  }
  return null;
}

/// A mode that is clearly ahead after meaningful supporting evidence.
///
/// Rules (all required):
/// - supportCount >= 2
/// - net >= 2
/// - not weakened
/// - leads the next mode by net gap >= [minLeadMargin] (strictly ahead, not tied)
///
/// Returns null when evidence is weak or tied. Does not itself mutate Primary.
String? clearLeaderFailureModeId({
  required Map<String, FailureModeStanding> standings,
  int minLeadMargin = 1,
  Map<String, FailureModeCommonality>? commonalityByModeId,
}) {
  if (standings.isEmpty) {
    return null;
  }
  final ranked =
      standings.entries.toList()..sort((a, b) {
        final byNet = b.value.net.compareTo(a.value.net);
        if (byNet != 0) {
          return byNet;
        }
        if (commonalityByModeId != null) {
          final byCommonality = _commonalityRank(commonalityByModeId[b.key])
              .compareTo(_commonalityRank(commonalityByModeId[a.key]));
          if (byCommonality != 0) {
            return byCommonality;
          }
        }
        return a.key.compareTo(b.key);
      });
  final leader = ranked.first;
  if (leader.value.supportCount < 2 ||
      leader.value.net < 2 ||
      leader.value.isWeakened) {
    return null;
  }
  if (ranked.length == 1) {
    return leader.key;
  }
  final runnerUpNet = ranked[1].value.net;
  final margin = leader.value.net - runnerUpNet;
  if (margin < minLeadMargin) {
    if (margin == 0 && commonalityByModeId != null) {
      final tied =
          ranked
              .where((entry) => entry.value.net == leader.value.net)
              .toList();
      tied.sort((a, b) {
        final byCommonality = _commonalityRank(commonalityByModeId[b.key])
            .compareTo(_commonalityRank(commonalityByModeId[a.key]));
        if (byCommonality != 0) {
          return byCommonality;
        }
        return a.key.compareTo(b.key);
      });
      final winner = tied.first;
      if (winner.value.supportCount >= 2 &&
          winner.value.net >= 2 &&
          !winner.value.isWeakened) {
        return winner.key;
      }
    }
    return null;
  }
  return leader.key;
}

int _commonalityRank(FailureModeCommonality? commonality) {
  return switch (commonality) {
    FailureModeCommonality.veryHigh => 3,
    FailureModeCommonality.high => 2,
    FailureModeCommonality.common => 1,
    FailureModeCommonality.moderate => 0,
    null => 0,
  };
}

int _bucketRank(FailureModeStanding? standing) {
  if (standing == null) {
    return 3;
  }
  return switch (standing.rankLabel) {
    FailureModeRankLabel.strongerMatch => 0,
    FailureModeRankLabel.possible => 1,
    FailureModeRankLabel.unset => 2,
    FailureModeRankLabel.lessLikely => 3,
  };
}
