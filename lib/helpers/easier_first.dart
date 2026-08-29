import '../models/knowledge_package.dart';
import 'dryer_close_path.dart';
import 'failure_mode_standing.dart';
import 'pro_scope.dart';
import 'repair_stakes.dart';
import 'thermal_reset_scope.dart';

/// Presentation overlay: pursue the easier / safer path first when two (or
/// more) modes remain plausible. Does not change ranking math.
const String easierFirstNotice =
    'Two things still fit. We’re checking the simpler, lower-risk possibility '
    'first. The other stays listed as also possible.';

const String easierFirstContinueNotice =
    'The simpler check did not restore function. Next we’ll look at the harder '
    'possibility. Completing one check does not mean both causes are fixed.';

/// Lower is easier / safer / lower brick-risk. Ranking scores are unused.
int easierFirstRank(String failureModeId) {
  if (isResettableThermalPath(failureModeId)) {
    return 0;
  }
  final path = closePathForFailureMode(failureModeId);
  if (path != null && !closePathDiyCannotComplete(path)) {
    if (closePathHasBrickRisk(path)) {
      return 2;
    }
    return 1;
  }
  if (path != null && closePathDiyCannotComplete(path)) {
    return 4;
  }
  return 3;
}

bool _isPlausible(FailureModeStanding? standing) {
  return standing?.isSupported ?? false;
}

/// Modes still standing after evidence, easiest first.
List<FailureMode> plausibleModesEasiestFirst({
  required List<FailureMode> orderedFailureModes,
  required Map<String, FailureModeStanding> standings,
  Set<String> exhaustedModeIds = const {},
}) {
  final remaining = [
    for (final mode in orderedFailureModes)
      if (!exhaustedModeIds.contains(mode.id) && _isPlausible(standings[mode.id]))
        mode,
  ];
  remaining.sort((a, b) {
    final byEase = easierFirstRank(a.id).compareTo(easierFirstRank(b.id));
    if (byEase != 0) {
      return byEase;
    }
    final netA = standings[a.id]?.net ?? 0;
    final netB = standings[b.id]?.net ?? 0;
    return netB.compareTo(netA);
  });
  return remaining;
}

/// Mode to pursue now. Ranking leader is kept when it is already the easiest
/// plausible, or when only one mode remains.
String? easierFirstPursuitId({
  required List<FailureMode> orderedFailureModes,
  required Map<String, FailureModeStanding> standings,
  String? rankingLeaderId,
  String? confirmedPrimaryId,
  Set<String> exhaustedModeIds = const {},
}) {
  final remaining = plausibleModesEasiestFirst(
    orderedFailureModes: orderedFailureModes,
    standings: standings,
    exhaustedModeIds: exhaustedModeIds,
  );
  if (remaining.isEmpty) {
    return confirmedPrimaryId ?? rankingLeaderId;
  }
  if (confirmedPrimaryId != null &&
      remaining.any((mode) => mode.id == confirmedPrimaryId)) {
    return confirmedPrimaryId;
  }
  if (remaining.length == 1) {
    return remaining.first.id;
  }
  return remaining.first.id;
}

bool easierFirstDualFaultActive({
  required List<FailureMode> orderedFailureModes,
  required Map<String, FailureModeStanding> standings,
  Set<String> exhaustedModeIds = const {},
}) {
  return plausibleModesEasiestFirst(
        orderedFailureModes: orderedFailureModes,
        standings: standings,
        exhaustedModeIds: exhaustedModeIds,
      ).length >=
      2;
}
