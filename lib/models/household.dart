import 'household_member.dart';

/// Minimal immutable parent record for household-owned data.
class Household {
  const Household({
    required this.id,
    required this.name,
    required this.ownerUserId,
    required this.createdAt,
    required this.schemaVersion,
    this.ownedToolIds = const [],
    this.ownedToolsGeneration = 0,
    this.members = const [],
  });

  final String id;
  final String name;
  final String ownerUserId;
  final DateTime createdAt;
  final String schemaVersion;
  final List<String> ownedToolIds;
  /// Bumped on every add/remove so restore can ignore a stale tools overlay.
  final int ownedToolsGeneration;
  /// People who share this house’s appliances, tools, and House Book.
  final List<HouseholdMember> members;

  Household copyWith({
    List<String>? ownedToolIds,
    int? ownedToolsGeneration,
    List<HouseholdMember>? members,
  }) {
    return Household(
      id: id,
      name: name,
      ownerUserId: ownerUserId,
      createdAt: createdAt,
      schemaVersion: schemaVersion,
      ownedToolIds: ownedToolIds ?? this.ownedToolIds,
      ownedToolsGeneration: ownedToolsGeneration ?? this.ownedToolsGeneration,
      members: members ?? this.members,
    );
  }
}
