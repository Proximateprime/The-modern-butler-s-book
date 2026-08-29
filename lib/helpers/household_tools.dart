import 'repair_readiness.dart';

/// Common household tools the MVP can remember.
///
/// Meters are deliberately absent: no supported dryer, washer, dishwasher, or
/// fridge path asks a beginner to measure a live circuit, so offering one to
/// add would imply work this book will not walk anyone through. A meter saved
/// by an older build still displays via [householdToolLabel].
const catalogHouseholdTools = <HouseholdTool>[
  HouseholdTool(id: 'screwdriver', label: 'Screwdriver'),
  HouseholdTool(id: 'nut-driver', label: 'Nut driver'),
  HouseholdTool(id: 'flashlight', label: 'Flashlight'),
  HouseholdTool(id: 'vacuum', label: 'Vacuum'),
  HouseholdTool(id: 'shallow-pan', label: 'Shallow pan and towel'),
  HouseholdTool(id: 'pliers', label: 'Pliers'),
];

class HouseholdTool {
  const HouseholdTool({required this.id, required this.label});

  final String id;
  final String label;
}

/// Display name for a stored tool id.
String householdToolLabel(String id) {
  for (final tool in catalogHouseholdTools) {
    if (tool.id == id) {
      return tool.label;
    }
  }
  if (id.isEmpty) {
    return id;
  }
  return id
      .split('-')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

/// Normalizes typed inventory names onto the same ids as repair readiness.
String? toolIdFromInventoryLabel(String raw) {
  final label = raw.trim();
  if (label.isEmpty) {
    return null;
  }
  final id = canonicalToolId(label);
  if (id.isEmpty) {
    return null;
  }
  return id;
}
