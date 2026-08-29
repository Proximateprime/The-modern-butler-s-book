/// Minimal immutable record of a tool available during a Repair Session.
class Tool {
  const Tool({
    required this.id,
    required this.name,
    required this.category,
    required this.isOwnedByHousehold,
  });

  final String id;
  final String name;
  final String category;
  final bool isOwnedByHousehold;
}
