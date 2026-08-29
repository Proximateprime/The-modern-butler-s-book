import '../models/session_outcome.dart';
import '../ui/app_dependencies.dart';

/// Display-only filter for household repair memory. No ranking.
List<RecentSessionOutcome> filterRepairHistory({
  required List<RecentSessionOutcome> items,
  String query = '',
  SessionCloseKind? closeKind,
  String? applianceId,
}) {
  final needle = query.trim().toLowerCase();
  return [
    for (final item in items)
      if (_matches(
        item: item,
        needle: needle,
        closeKind: closeKind,
        applianceId: applianceId,
      ))
        item,
  ];
}

bool _matches({
  required RecentSessionOutcome item,
  required String needle,
  required SessionCloseKind? closeKind,
  required String? applianceId,
}) {
  if (closeKind != null && item.outcome.closeKind != closeKind) {
    return false;
  }
  if (applianceId != null && item.session.applianceId != applianceId) {
    return false;
  }
  if (needle.isEmpty) {
    return true;
  }
  final outcome = item.outcome;
  final haystack = [
    item.applianceName,
    outcome.summary,
    sessionCloseKindLabel(outcome.closeKind),
    outcome.startSymptom ?? '',
    outcome.userNote ?? '',
    outcome.rankingLeaderLabel ?? '',
    outcome.immediateCause,
    outcome.rootCause ?? '',
    ...outcome.contributingFactors,
    ...outcome.preventiveActions,
  ].join(' ').toLowerCase();
  return haystack.contains(needle);
}
