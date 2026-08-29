import '../models/repair_session.dart';

/// Hours after last activity before an open session is treated as stale.
///
/// On resume, the household is warned that evidence may be outdated and can
/// continue or start fresh. Change this single constant to retune the warning.
const int staleOpenSessionHours = 48;

const Duration staleOpenSessionAfter = Duration(hours: staleOpenSessionHours);

/// True when [session] has had no activity for [staleOpenSessionAfter].
bool sessionIsStale(RepairSession session, DateTime now) {
  final last = session.lastActivityAt.toUtc();
  final asOf = now.toUtc();
  return !asOf.difference(last).isNegative &&
      asOf.difference(last) >= staleOpenSessionAfter;
}
