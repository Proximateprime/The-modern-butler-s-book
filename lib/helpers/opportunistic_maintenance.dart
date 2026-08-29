import '../knowledge_factory/failure_mode_authoring_registry.dart';
import 'visual_guide.dart';

/// Optional while-you-are-here check from package prevention. Not ranking.
class OpportunisticMaintenanceItem {
  const OpportunisticMaintenanceItem({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

/// Package prevention lines that are nearby when a filter, vent, or panel is
/// already open. Copied from authored prevention — not a new scoring signal.
const List<String> packageWhileHerePrevention = [
  'Vacuum accessible lint around the filter slot periodically',
  'Keep the exterior vent hood clear of lint and nests',
  'Inspect the visible vent hose periodically for crush and lint',
  'Clean the lint filter before every load',
  'Clean the accessible drain filter about every 30 days',
  'Rinse the accessible tub filter about every 30 days',
  'Vacuum accessible coils or the grille about every 90 days',
];

bool guidanceAccessAlreadyOpen({
  required List<String> safeGuidanceSteps,
  List<VisualGuideAnchor> visualGuides = const [],
}) {
  return _accessKinds(
    steps: safeGuidanceSteps,
    visualGuides: visualGuides,
  ).isNotEmpty;
}

/// Optional extras when Safe Guidance already has a panel, filter, or vent
/// open. Empty when there is nothing extra, or when access is not open.
List<OpportunisticMaintenanceItem> opportunisticMaintenanceItems({
  required List<String> safeGuidanceSteps,
  List<VisualGuideAnchor> visualGuides = const [],
  String? failureModeId,
}) {
  final kinds = _accessKinds(
    steps: safeGuidanceSteps,
    visualGuides: visualGuides,
  );
  if (kinds.isEmpty) {
    return const [];
  }

  final guidance = _normalize(safeGuidanceSteps.join(' '));
  final seen = <String>{};
  final items = <OpportunisticMaintenanceItem>[];
  final authored =
      FailureModeAuthoringRegistry.lookup(failureModeId)?.preventionActions ??
      const <String>[];
  for (final raw in [...authored, ...packageWhileHerePrevention]) {
    final label = raw.trim();
    if (label.isEmpty) {
      continue;
    }
    final key = label.toLowerCase();
    if (!seen.add(key)) {
      continue;
    }
    if (!_matchesOpenAccess(label, kinds)) {
      continue;
    }
    if (_coveredByGuidance(label, guidance)) {
      continue;
    }
    items.add(
      OpportunisticMaintenanceItem(
        id: _itemId(label),
        label: label,
      ),
    );
    if (items.length >= 3) {
      break;
    }
  }
  return List.unmodifiable(items);
}

enum _AccessKind { lint, vent, panel, drainFilter, coils }

Set<_AccessKind> _accessKinds({
  required List<String> steps,
  required List<VisualGuideAnchor> visualGuides,
}) {
  final blob = _normalize(
    [
      ...steps,
      for (final guide in visualGuides) '${guide.targetId} ${guide.label}',
    ].join(' '),
  );
  final kinds = <_AccessKind>{};
  if (blob.contains('lint housing') ||
      blob.contains('lint filter') ||
      blob.contains('filter slot') ||
      blob.contains('lint-filter')) {
    kinds.add(_AccessKind.lint);
  }
  if (blob.contains('vent hood') ||
      blob.contains('vent hose') ||
      blob.contains('exterior vent') ||
      blob.contains('vent-hood')) {
    kinds.add(_AccessKind.vent);
  }
  if (blob.contains('access panel') ||
      blob.contains('service panel') ||
      blob.contains('access-panel') ||
      blob.contains('heater service panel') ||
      blob.contains('front lower panel') ||
      blob.contains('rear panel')) {
    kinds.add(_AccessKind.panel);
  }
  if (blob.contains('drain filter') ||
      blob.contains('tub filter') ||
      blob.contains('drain-filter')) {
    kinds.add(_AccessKind.drainFilter);
  }
  if (blob.contains('condenser coils') ||
      blob.contains('accessible coils') ||
      blob.contains('toe-kick') ||
      blob.contains('fridge-coils')) {
    kinds.add(_AccessKind.coils);
  }
  return kinds;
}

bool _matchesOpenAccess(String action, Set<_AccessKind> kinds) {
  final text = _normalize(action);
  if (kinds.contains(_AccessKind.lint) || kinds.contains(_AccessKind.panel)) {
    if (text.contains('lint') ||
        text.contains('filter slot') ||
        text.contains('vent hood') ||
        text.contains('vent hose')) {
      return true;
    }
  }
  if (kinds.contains(_AccessKind.vent)) {
    if (text.contains('vent') ||
        text.contains('lint filter') ||
        text.contains('filter slot')) {
      return true;
    }
  }
  if (kinds.contains(_AccessKind.drainFilter)) {
    if (text.contains('drain filter') || text.contains('tub filter')) {
      return true;
    }
  }
  if (kinds.contains(_AccessKind.coils)) {
    if (text.contains('coil') || text.contains('grille')) {
      return true;
    }
  }
  return false;
}

bool _coveredByGuidance(String action, String guidance) {
  final normalizedAction = _normalize(action)
      .replaceAll('before every load', '')
      .replaceAll('periodically', '')
      .replaceAll('on a regular schedule', '')
      .trim();
  if (normalizedAction.length >= 18 && guidance.contains(normalizedAction)) {
    return true;
  }
  const parts = [
    'lint filter',
    'vent hood',
    'vent hose',
    'filter slot',
    'lint housing',
    'drain filter',
    'tub filter',
  ];
  const verbs = [
    'clean',
    'vacuum',
    'inspect',
    'check',
    'clear',
    'keep',
    'confirm',
    'rinse',
  ];
  for (final part in parts) {
    if (!normalizedAction.contains(part) || !guidance.contains(part)) {
      continue;
    }
    final actionVerbs = verbs.where(normalizedAction.contains).toSet();
    final stepVerbs = verbs.where(guidance.contains).toSet();
    if (actionVerbs.isNotEmpty &&
        actionVerbs.intersection(stepVerbs).isNotEmpty) {
      return true;
    }
  }
  return false;
}

String _normalize(String raw) {
  return raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

String _itemId(String label) {
  final slug = label
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.length <= 48) {
    return slug;
  }
  return slug.substring(0, 48);
}
