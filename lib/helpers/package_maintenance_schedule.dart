import '../models/knowledge_package.dart';

/// Authored manufacturer upkeep rows for one installed package.
///
/// Empty when the package has no schedule. Callers must omit the section
/// entirely — no "coming soon" card.
List<String> manufacturerMaintenanceSchedule(KnowledgePackage? package) {
  if (package == null) {
    return const [];
  }
  return const [];
}

/// Community / "what others noticed" rows. Household pattern hints are separate
/// and already require verified N>=2 history. This list stays empty unless a
/// package authors verified community notes (none do in MVP).
List<String> communityMaintenanceNotices(KnowledgePackage? package) {
  if (package == null) {
    return const [];
  }
  return const [];
}
