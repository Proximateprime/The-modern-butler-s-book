import 'dryer_close_path.dart';
import 'pro_scope.dart';
import 'safety_stop.dart';
import 'thermal_reset_scope.dart';

/// Display-only part/cost stub from package metadata. Never a payment.
class PartCostEstimate {
  const PartCostEstimate({
    required this.name,
    required this.diyEstimate,
    required this.proEstimate,
  });

  final String name;
  final String diyEstimate;
  final String proEstimate;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'diyEstimate': diyEstimate,
      'proEstimate': proEstimate,
    };
  }

  factory PartCostEstimate.fromJson(Map<String, dynamic> json) {
    return PartCostEstimate(
      name: (json['name'] ?? json['part'] ?? '').toString().trim(),
      diyEstimate: (json['diyEstimate'] ?? json['diy'] ?? '').toString().trim(),
      proEstimate: (json['proEstimate'] ?? json['pro'] ?? '').toString().trim(),
    );
  }
}

/// Built-in package stubs when an authoring record has no `partsEstimates`.
const Map<String, List<PartCostEstimate>> partsCostCatalog = {
  'restricted-exhaust-airflow': [
    PartCostEstimate(
      name: 'Lint filter',
      diyEstimate: r'$8–20',
      proEstimate: r'$80–150',
    ),
    PartCostEstimate(
      name: 'Flexible vent kit',
      diyEstimate: r'$15–40',
      proEstimate: r'$120–250',
    ),
  ],
  'clogged-lint-pathway': [
    PartCostEstimate(
      name: 'Lint filter',
      diyEstimate: r'$8–20',
      proEstimate: r'$70–140',
    ),
  ],
  'accessible-thermal-reset': [
    PartCostEstimate(
      name: 'Lint filter',
      diyEstimate: r'$8–20',
      proEstimate: r'$80–150',
    ),
    PartCostEstimate(
      name: 'Flexible vent kit',
      diyEstimate: r'$15–40',
      proEstimate: r'$120–250',
    ),
  ],
  'thermal-fuse-open': [
    PartCostEstimate(
      name: 'Thermal fuse',
      diyEstimate: r'$10–25',
      proEstimate: r'$150–280',
    ),
  ],
  'broken-drive-belt': [
    PartCostEstimate(
      name: 'Drive belt',
      diyEstimate: r'$12–30',
      proEstimate: r'$140–260',
    ),
  ],
  'heating-element-failed': [
    PartCostEstimate(
      name: 'Heating element',
      diyEstimate: r'$25–70',
      proEstimate: r'$180–350',
    ),
  ],
  'door-switch-failure': [
    PartCostEstimate(
      name: 'Door switch',
      diyEstimate: r'$15–40',
      proEstimate: r'$120–220',
    ),
  ],
  'clogged-washer-drain-filter': [
    PartCostEstimate(
      name: 'Drain filter / pump trap',
      diyEstimate: r'$8–25',
      proEstimate: r'$90–180',
    ),
  ],
  'loose-inlet-hose': [
    PartCostEstimate(
      name: 'Inlet hose',
      diyEstimate: r'$15–35',
      proEstimate: r'$80–150',
    ),
  ],
};

List<PartCostEstimate> parsePartsEstimatesJson(dynamic raw) {
  if (raw is! List) {
    return const [];
  }
  final parts = <PartCostEstimate>[];
  for (final item in raw) {
    if (item is! Map) {
      continue;
    }
    final part = PartCostEstimate.fromJson(Map<String, dynamic>.from(item));
    if (part.name.isEmpty) {
      continue;
    }
    parts.add(part);
  }
  return List.unmodifiable(parts);
}

/// Honest line when the part exists but a household cannot fit it safely.
const String partsCostProOnlyNote =
    'A technician fits this part on this path. The safe checks below still '
    'help — they confirm the problem and give the technician better '
    'information.';

/// True when the selected path cannot be finished as a home DIY repair.
///
/// The card then hides the DIY estimate and the "I'll repair" action so a
/// beginner is never quoted a self-repair price for work we will not walk
/// them through. Gated professional ids stay out of scope even when
/// [closePathForFailureMode] is null. Resettable thermal cutoff stays DIY.
bool partsCostDiyOutOfScope(String? failureModeId) {
  final id = failureModeId?.trim() ?? '';
  if (id.isEmpty) {
    return false;
  }
  if (isResettableThermalPath(id)) {
    final resetPath = closePathForFailureMode(id);
    if (resetPath != null && resetPath.allowResolvedWhenConfirmed) {
      return false;
    }
  }
  if (isGatedProfessionalFailureMode(id) ||
      isHeaterCircuitDiyCannotCompleteLeader(id)) {
    return true;
  }
  final path = closePathForFailureMode(id);
  if (path == null) {
    return false;
  }
  return closePathDiyCannotComplete(path);
}

/// Purchase rows for the selected close path only.
///
/// Catalog rows for other failure modes (washer drain trap, inlet hose, …)
/// never appear on a dryer fuse or vent outcome. Replace/seat steps keep the
/// named part. Cleaning/restriction rows (lint filter, vent kit, drain trap)
/// stay off the card. Estimates only — not a quote.
List<PartCostEstimate> partsEstimatesForSelectedPath({
  required List<PartCostEstimate> parts,
  String? failureModeId,
}) {
  if (parts.isEmpty || failureModeId == null || failureModeId.trim().isEmpty) {
    return const [];
  }
  final scoped = _scopePartsToFailureMode(
    parts: parts,
    failureModeId: failureModeId.trim(),
  );
  if (scoped.isEmpty) {
    return const [];
  }
  final path = closePathForFailureMode(failureModeId);
  final steps = [
    ...path?.safeGuidanceSteps ?? const <String>[],
    ...path?.expertOkSteps ?? const <String>[],
  ];
  final replaceText = [
    for (final step in steps)
      if (_guidanceReplacesAPart(step.toLowerCase())) step.toLowerCase(),
  ].join(' ');
  if (replaceText.isNotEmpty) {
    return List.unmodifiable([
      for (final part in scoped)
        if (_partNamedInGuidance(part.name, replaceText)) part,
    ]);
  }
  return List.unmodifiable([
    for (final part in scoped)
      if (!_isCleaningPurchaseRow(part.name)) part,
  ]);
}

/// Drop rows that belong to a different mode or appliance family.
List<PartCostEstimate> _scopePartsToFailureMode({
  required List<PartCostEstimate> parts,
  required String failureModeId,
}) {
  final catalog = partsCostCatalog[failureModeId];
  if (catalog != null && catalog.isNotEmpty) {
    final names = {
      for (final part in catalog) part.name.trim().toLowerCase(),
    };
    return [
      for (final part in parts)
        if (names.contains(part.name.trim().toLowerCase())) part,
    ];
  }
  final family = _partsFamilyForFailureMode(failureModeId);
  return [
    for (final part in parts)
      if (!_partConflictsWithFamily(part.name, family)) part,
  ];
}

String _partsFamilyForFailureMode(String failureModeId) {
  final id = failureModeId.toLowerCase();
  if (id.contains('dishwasher')) {
    return 'dishwasher';
  }
  if (id.contains('fridge') ||
      id.contains('ice-maker') ||
      id.contains('ice-bin')) {
    return 'fridge';
  }
  if (id.contains('washer') ||
      id == 'loose-inlet-hose' ||
      id == 'closed-taps-or-kinked-inlet') {
    return 'washer';
  }
  return 'dryer';
}

bool _partConflictsWithFamily(String name, String family) {
  final lower = name.toLowerCase();
  final washerNamed = lower.contains('drain filter') ||
      lower.contains('pump trap') ||
      lower.contains('inlet hose');
  final dryerNamed = lower.contains('thermal fuse') ||
      lower.contains('heating element') ||
      lower.contains('lint filter') ||
      lower.contains('vent kit') ||
      lower.contains('drive belt');
  if (family == 'dryer' && washerNamed) {
    return true;
  }
  if (family != 'dryer' && dryerNamed) {
    return true;
  }
  return false;
}

bool _guidanceReplacesAPart(String guidance) {
  return guidance.contains('replace with') ||
      guidance.contains('exact-match') ||
      guidance.contains('seat or replace') ||
      guidance.contains('belt replacement');
}

bool _partNamedInGuidance(String name, String guidance) {
  final lower = name.toLowerCase();
  if (lower.isEmpty) {
    return false;
  }
  if (guidance.contains(lower)) {
    return true;
  }
  final words = lower.split(RegExp(r'[^a-z0-9]+')).where((word) => word.length > 3);
  return words.any((word) => guidance.contains(word));
}

bool _isCleaningPurchaseRow(String name) {
  final lower = name.toLowerCase();
  return lower.contains('lint filter') ||
      lower.contains('vent kit') ||
      lower.contains('drain filter') ||
      lower.contains('pump trap');
}
