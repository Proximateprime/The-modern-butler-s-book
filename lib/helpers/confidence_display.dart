import '../models/knowledge_package.dart';
import 'failure_mode_standing.dart';

/// Where household-facing standing copy may appear.
///
/// Early questions never show live rank chrome or percentages.
enum ConfidenceDisplaySurface {
  earlyQuestion,
  recommendation,
  diagnosisSummary,
}

/// One honest alternative for a recommendation or diagnosis summary.
class RankedPossibility {
  const RankedPossibility({
    required this.failureMode,
    required this.standing,
    required this.caption,
  });

  final FailureMode failureMode;
  final FailureModeStanding standing;
  final String? caption;
}

/// Household standing phrase. Never a percentage. Null = do not show chrome.
String? householdStandingPhrase({
  required FailureModeStanding standing,
  required ConfidenceDisplaySurface surface,
}) {
  if (surface == ConfidenceDisplaySurface.earlyQuestion) {
    return null;
  }
  return switch (standing.rankLabel) {
    FailureModeRankLabel.strongerMatch =>
      'High — more of your answers match this than the others',
    FailureModeRankLabel.lessLikely => 'Low — less likely given your answers',
    FailureModeRankLabel.possible
        when surface == ConfidenceDisplaySurface.diagnosisSummary =>
      'Medium — also consistent with some of your answers',
    FailureModeRankLabel.possible || FailureModeRankLabel.unset => null,
  };
}

/// Supported alternatives for a recommendation or diagnosis summary.
///
/// Skips the current leader. Does not invent scores. Empty when nothing else
/// has net support.
List<RankedPossibility> rankedPossibilitiesForDisplay({
  required List<FailureMode> orderedFailureModes,
  required Map<String, FailureModeStanding> standings,
  String? excludeFailureModeId,
  required ConfidenceDisplaySurface surface,
  int limit = 3,
}) {
  if (surface == ConfidenceDisplaySurface.earlyQuestion) {
    return const [];
  }
  final items = <RankedPossibility>[];
  for (final mode in orderedFailureModes) {
    if (items.length >= limit) {
      break;
    }
    if (mode.id == excludeFailureModeId) {
      continue;
    }
    final standing = standings[mode.id];
    if (standing == null || !standing.isSupported) {
      continue;
    }
    items.add(
      RankedPossibility(
        failureMode: mode,
        standing: standing,
        caption: householdStandingPhrase(
          standing: standing,
          surface: surface,
        ),
      ),
    );
  }
  return List.unmodifiable(items);
}

bool standingLooksLikePercentage(String text) {
  return RegExp(r'\d+\s*%').hasMatch(text);
}
