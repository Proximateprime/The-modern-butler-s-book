/// A person who can use this household on this device. No account, no roles.
class HouseholdMember {
  const HouseholdMember({
    required this.id,
    required this.householdId,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String householdId;
  final String displayName;
  final DateTime createdAt;
}

/// First person created with a household when none were stored.
const String defaultHouseholdMemberDisplayName = 'You';
