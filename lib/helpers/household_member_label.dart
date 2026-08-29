import '../models/household.dart';
import '../models/household_member.dart';

export '../models/household_member.dart';

/// Display name for a session’s [createdByUserId]. No roles.
String householdMemberDisplayName({
  required Household? household,
  required String? userId,
}) {
  final id = userId?.trim() ?? '';
  if (id.isEmpty) {
    return defaultHouseholdMemberDisplayName;
  }
  final members = household?.members ?? const [];
  for (final member in members) {
    if (member.id == id) {
      final name = member.displayName.trim();
      if (name.isNotEmpty) {
        return name;
      }
    }
  }
  if (household != null && household.ownerUserId == id) {
    return defaultHouseholdMemberDisplayName;
  }
  return defaultHouseholdMemberDisplayName;
}
