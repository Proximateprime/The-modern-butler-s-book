import '../models/decision_context.dart';

/// Repair-readiness checklist item parsed from package `toolsRequired` metadata.
class RepairReadinessItem {
  const RepairReadinessItem({
    required this.id,
    required this.label,
    required this.optional,
    required this.liveElectrical,
  });

  final String id;
  final String label;
  final bool optional;
  final bool liveElectrical;

  bool get isCritical => !optional;
}

/// Parses authored `toolsRequired` strings into checklist items.
///
/// Placeholder lines ("None", "no tools", pro-only notes) are skipped.
/// Does not change ranking, polarity, or Safe Guidance copy.
List<RepairReadinessItem> readinessItemsFromToolsRequired(
  List<String> toolsRequired,
) {
  final items = <RepairReadinessItem>[];
  final seen = <String>{};
  for (final raw in toolsRequired) {
    final label = raw.trim();
    if (label.isEmpty || _isPlaceholderTool(label)) {
      continue;
    }
    final id = canonicalToolId(label);
    if (!seen.add(id)) {
      continue;
    }
    items.add(
      RepairReadinessItem(
        id: id,
        label: label,
        optional: _isOptionalTool(label),
        liveElectrical: isLiveElectricalTool(label),
      ),
    );
  }
  return List.unmodifiable(items);
}

/// Stable household-memory id for a tool label.
String canonicalToolId(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('multimeter')) {
    return 'multimeter';
  }
  if (lower.contains('voltage tester') || lower.contains('volt meter')) {
    return 'voltage-tester';
  }
  if (lower.contains('screwdriver')) {
    return 'screwdriver';
  }
  if (lower.contains('nut driver') || lower.contains('nut-driver')) {
    return 'nut-driver';
  }
  if (lower.contains('flashlight')) {
    return 'flashlight';
  }
  if (lower.contains('vacuum')) {
    return 'vacuum';
  }
  if (lower.contains('shallow pan') ||
      (lower.contains('pan') && lower.contains('towel'))) {
    return 'shallow-pan';
  }
  if (lower.contains('pliers')) {
    return 'pliers';
  }
  return lower
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

bool isLiveElectricalTool(String label) {
  final lower = label.toLowerCase();
  return lower.contains('multimeter') ||
      lower.contains('voltage') ||
      lower.contains('ammeter') ||
      lower.contains('live probe') ||
      lower.contains('live electrical');
}

/// Continue-with-caution is allowed only when missing tools are not live-electrical.
bool allowContinueWithCaution(Iterable<RepairReadinessItem> missingCritical) {
  return missingCritical.every((item) => !item.liveElectrical);
}

/// Short checklist label. Prefers “screwdriver” over a driver-gun implication.
String readinessDisplayLabel(RepairReadinessItem item) {
  if (item.id == 'screwdriver') {
    return 'Screwdriver';
  }
  if (item.id == 'flashlight') {
    return 'Flashlight';
  }
  if (item.id == 'vacuum') {
    return 'Vacuum';
  }
  if (item.id == 'shallow-pan') {
    return 'Shallow pan and towel';
  }
  return item.label
      .replaceAll(RegExp(r'\s*\(optional\)\s*', caseSensitive: false), '')
      .trim();
}

bool _isPlaceholderTool(String label) {
  final lower = label.toLowerCase();
  if (lower == 'none' || lower.startsWith('none')) {
    return true;
  }
  if (lower.contains('no tools')) {
    return true;
  }
  if (lower.contains('only for pros') || lower.contains('only for a pro')) {
    return true;
  }
  return false;
}

bool _isOptionalTool(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('optional')) {
    return true;
  }
  if (RegExp(r'\bflashlight\b').hasMatch(lower)) {
    return true;
  }
  if (RegExp(r'\bgloves\b').hasMatch(lower)) {
    return true;
  }
  return false;
}

/// Whether the household already marked [toolId] as owned on [context].
bool decisionOwnsTool(DecisionContext context, String toolId) {
  for (final tool in context.availableTools) {
    if (tool.id == toolId && tool.isOwnedByHousehold) {
      return true;
    }
  }
  return false;
}
