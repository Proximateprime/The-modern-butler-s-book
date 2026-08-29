/// Package visual-guide metadata for one beginner-safe part location.
///
/// Fields: [targetId], [label], optional [imageAsset], and a normalized
/// pin ([anchorX], [anchorY]). Display only — never ranking or diagnosis.
class VisualGuideAnchor {
  const VisualGuideAnchor({
    required this.targetId,
    required this.label,
    this.imageAsset,
    this.anchorX = 0.5,
    this.anchorY = 0.38,
    this.whatYouShouldSee,
    this.applianceCategory,
    this.typicalDiagramOnly = false,
  });

  /// Stable package id, e.g. `lint-filter`.
  final String targetId;

  /// Pin caption shown on camera overlay and diagrams.
  final String label;

  /// Optional asset or diagram id (`diagram:dryer-front`).
  final String? imageAsset;

  /// Horizontal pin, 0–1 from the left of the view.
  final double anchorX;

  /// Vertical pin, 0–1 from the top of the view.
  final double anchorY;

  /// Short observational description of the part location.
  final String? whatYouShouldSee;

  /// When set, this pin is only valid for that appliance family.
  final String? applianceCategory;

  /// Static typical-location diagram; never a pose-accurate AR box.
  final bool typicalDiagramOnly;

  VisualGuideAnchor copyWith({
    String? label,
    String? imageAsset,
    double? anchorX,
    double? anchorY,
    String? whatYouShouldSee,
    String? applianceCategory,
    bool? typicalDiagramOnly,
  }) {
    return VisualGuideAnchor(
      targetId: targetId,
      label: label ?? this.label,
      imageAsset: imageAsset ?? this.imageAsset,
      anchorX: anchorX ?? this.anchorX,
      anchorY: anchorY ?? this.anchorY,
      whatYouShouldSee: whatYouShouldSee ?? this.whatYouShouldSee,
      applianceCategory: applianceCategory ?? this.applianceCategory,
      typicalDiagramOnly: typicalDiagramOnly ?? this.typicalDiagramOnly,
    );
  }
}

class _VisualGuideCatalogEntry {
  const _VisualGuideCatalogEntry({
    required this.anchor,
    required this.matchPhrases,
  });

  final VisualGuideAnchor anchor;
  final List<String> matchPhrases;
}

const lintFilterGuide = VisualGuideAnchor(
  targetId: 'lint-filter',
  label: 'Lint filter',
  imageAsset: 'diagram:dryer-front',
  applianceCategory: 'dryer',
  typicalDiagramOnly: true,
  anchorX: 0.50,
  anchorY: 0.22,
  whatYouShouldSee:
      'Typical dryer lint filter at the door opening — a pull-out mesh. '
      'Yours may vary.',
);

const accessPanelGuide = VisualGuideAnchor(
  targetId: 'access-panel',
  label: 'Access panel',
  imageAsset: 'diagram:dryer-front',
  applianceCategory: 'dryer',
  typicalDiagramOnly: true,
  anchorX: 0.50,
  anchorY: 0.62,
  whatYouShouldSee:
      'Typical lower front or rear service-panel region after you unplug. '
      'Yours may vary. Do not probe wiring or measure voltage.',
);

const ventHoodGuide = VisualGuideAnchor(
  targetId: 'vent-hood',
  label: 'Exterior vent',
  imageAsset: 'diagram:dryer-rear',
  applianceCategory: 'dryer',
  typicalDiagramOnly: true,
  anchorX: 0.78,
  anchorY: 0.42,
  whatYouShouldSee:
      'Typical exterior vent hood — yours may vary. The outside hood should '
      'swing freely. With a heat cycle running you should feel airflow at the '
      'opening from a step away.',
);

const dryerVentHoseGuide = VisualGuideAnchor(
  targetId: 'vent-hose',
  label: 'Visible vent hose',
  imageAsset: 'diagram:dryer-rear',
  applianceCategory: 'dryer',
  typicalDiagramOnly: true,
  anchorX: 0.50,
  anchorY: 0.55,
  whatYouShouldSee:
      'Typical flexible exhaust hose behind the dryer — yours may vary. Look '
      'for crush, kinks, packed lint, or a long sagging plastic run.',
);

const drainFilterGuide = VisualGuideAnchor(
  targetId: 'drain-filter',
  label: 'Drain filter',
  imageAsset: 'diagram:washer-front',
  applianceCategory: 'washer',
  typicalDiagramOnly: true,
  anchorX: 0.22,
  anchorY: 0.78,
  whatYouShouldSee:
      'Typical washer drain filter or pump trap at the front lower corner. '
      'Yours may vary. Look from outside first; unplug before opening.',
);

const washerDoorLatchGuide = VisualGuideAnchor(
  targetId: 'washer-door-latch',
  label: 'Door latch',
  imageAsset: 'diagram:washer-front',
  applianceCategory: 'washer',
  typicalDiagramOnly: true,
  anchorX: 0.82,
  anchorY: 0.42,
  whatYouShouldSee:
      'Typical washer door or lid latch. Yours may vary. Close firmly until '
      'you feel or hear a click. Do not bypass the switch.',
);

const inletHoseGuide = VisualGuideAnchor(
  targetId: 'inlet-hose',
  label: 'Inlet hose at the tap',
  imageAsset: 'diagram:washer-rear',
  applianceCategory: 'washer',
  typicalDiagramOnly: true,
  anchorX: 0.80,
  anchorY: 0.28,
  whatYouShouldSee:
      'Typical inlet hose coupling at the wall tap behind the washer. '
      'Yours may vary.',
);

const waterTapsGuide = VisualGuideAnchor(
  targetId: 'water-taps',
  label: 'Water taps',
  imageAsset: 'diagram:washer-rear',
  applianceCategory: 'washer',
  typicalDiagramOnly: true,
  anchorX: 0.82,
  anchorY: 0.16,
  whatYouShouldSee:
      'Typical hot and cold shutoffs behind the washer. Yours may vary.',
);

const washerDrainHoseGuide = VisualGuideAnchor(
  targetId: 'washer-drain-hose',
  label: 'Drain hose at the standpipe',
  imageAsset: 'diagram:washer-rear',
  applianceCategory: 'washer',
  typicalDiagramOnly: true,
  anchorX: 0.78,
  anchorY: 0.55,
  whatYouShouldSee:
      'Typical drain hose into a standpipe behind the washer. Yours may vary.',
);

const dishwasherTubFilterGuide = VisualGuideAnchor(
  targetId: 'dishwasher-tub-filter',
  label: 'Tub filter',
  imageAsset: 'diagram:dishwasher-tub',
  applianceCategory: 'dishwasher',
  typicalDiagramOnly: true,
  anchorX: 0.50,
  anchorY: 0.72,
  whatYouShouldSee:
      'Typical dishwasher filter at the tub bottom under the lower rack. '
      'Yours may vary.',
);

const dishwasherDrainHoseGuide = VisualGuideAnchor(
  targetId: 'dishwasher-drain-hose',
  label: 'Drain hose or air gap',
  imageAsset: 'diagram:dishwasher-sink',
  applianceCategory: 'dishwasher',
  typicalDiagramOnly: true,
  anchorX: 0.72,
  anchorY: 0.38,
  whatYouShouldSee:
      'Typical drain hose, air-gap cap, or disposal inlet under the sink. '
      'Yours may vary.',
);

const dishwasherSprayArmGuide = VisualGuideAnchor(
  targetId: 'dishwasher-spray-arm',
  label: 'Spray arm',
  imageAsset: 'diagram:dishwasher-tub',
  applianceCategory: 'dishwasher',
  typicalDiagramOnly: true,
  anchorX: 0.50,
  anchorY: 0.48,
  whatYouShouldSee:
      'Typical spray arm in the tub — holes along the arm. Yours may vary.',
);

const dishwasherDoorLatchGuide = VisualGuideAnchor(
  targetId: 'dishwasher-door-latch',
  label: 'Door latch',
  imageAsset: 'diagram:dishwasher-tub',
  applianceCategory: 'dishwasher',
  typicalDiagramOnly: true,
  anchorX: 0.50,
  anchorY: 0.18,
  whatYouShouldSee:
      'Typical dishwasher door latch at the top of the tub opening. '
      'Yours may vary.',
);

const dishwasherSupplyGuide = VisualGuideAnchor(
  targetId: 'dishwasher-supply',
  label: 'Supply tap',
  imageAsset: 'diagram:dishwasher-sink',
  applianceCategory: 'dishwasher',
  typicalDiagramOnly: true,
  anchorX: 0.28,
  anchorY: 0.42,
  whatYouShouldSee:
      'Typical under-sink dishwasher supply tap. Yours may vary.',
);

const fridgeCoilsGuide = VisualGuideAnchor(
  targetId: 'fridge-coils',
  label: 'Accessible coils or grille',
  imageAsset: 'diagram:fridge-rear',
  applianceCategory: 'fridge',
  typicalDiagramOnly: true,
  anchorX: 0.50,
  anchorY: 0.78,
  whatYouShouldSee:
      'Typical toe-kick grille or rear accessible condenser coils after you '
      'unplug. Yours may vary.',
);

const fridgeDoorGasketGuide = VisualGuideAnchor(
  targetId: 'fridge-door-gasket',
  label: 'Door gasket',
  imageAsset: 'diagram:fridge-front',
  applianceCategory: 'fridge',
  typicalDiagramOnly: true,
  anchorX: 0.22,
  anchorY: 0.48,
  whatYouShouldSee:
      'Typical fridge door gasket around the door edge. Yours may vary.',
);

const fridgeInternalVentGuide = VisualGuideAnchor(
  targetId: 'fridge-internal-vents',
  label: 'Internal air vents',
  imageAsset: 'diagram:fridge-front',
  applianceCategory: 'fridge',
  typicalDiagramOnly: true,
  anchorX: 0.78,
  anchorY: 0.38,
  whatYouShouldSee:
      'Typical internal air vents on a back or side wall inside the cabinet. '
      'Yours may vary.',
);

const fridgeDripPanGuide = VisualGuideAnchor(
  targetId: 'fridge-drip-pan',
  label: 'Drip pan or drain',
  imageAsset: 'diagram:fridge-rear',
  applianceCategory: 'fridge',
  typicalDiagramOnly: true,
  anchorX: 0.50,
  anchorY: 0.88,
  whatYouShouldSee:
      'Typical slide-out drip pan or visible freezer drain region. Yours may '
      'vary.',
);

const fridgeIceMakerGuide = VisualGuideAnchor(
  targetId: 'fridge-ice-maker',
  label: 'Ice maker or bin',
  imageAsset: 'diagram:fridge-front',
  applianceCategory: 'fridge',
  typicalDiagramOnly: true,
  anchorX: 0.72,
  anchorY: 0.22,
  whatYouShouldSee:
      'Typical ice maker and bin in the freezer. Yours may vary.',
);

const _catalog = <_VisualGuideCatalogEntry>[
  _VisualGuideCatalogEntry(
    anchor: lintFilterGuide,
    matchPhrases: [
      'lint filter',
      'filter screen',
      'filter slot',
      'lint housing',
    ],
  ),
  _VisualGuideCatalogEntry(
    anchor: accessPanelGuide,
    matchPhrases: ['access panel', 'kick plate', 'lower panel'],
  ),
  _VisualGuideCatalogEntry(
    anchor: ventHoodGuide,
    matchPhrases: [
      'exterior vent',
      'vent hood',
      'outside vent',
    ],
  ),
  _VisualGuideCatalogEntry(
    anchor: dryerVentHoseGuide,
    matchPhrases: [
      'vent hose',
      'flexible duct',
      'visible vent',
      'exhaust hose',
    ],
  ),
  _VisualGuideCatalogEntry(
    anchor: drainFilterGuide,
    matchPhrases: [
      'drain filter',
      'pump trap',
      'coin trap',
    ],
  ),
  _VisualGuideCatalogEntry(
    anchor: washerDoorLatchGuide,
    matchPhrases: [
      'washer door',
      'lid latch',
    ],
  ),
  _VisualGuideCatalogEntry(
    anchor: inletHoseGuide,
    matchPhrases: ['inlet hose', 'tap coupling', 'hose coupling'],
  ),
  _VisualGuideCatalogEntry(
    anchor: waterTapsGuide,
    matchPhrases: ['water taps', 'hot and cold taps', 'both taps'],
  ),
  _VisualGuideCatalogEntry(
    anchor: washerDrainHoseGuide,
    matchPhrases: [
      'standpipe',
      'drain hose behind',
      'washer drain hose',
    ],
  ),
  _VisualGuideCatalogEntry(
    anchor: dishwasherTubFilterGuide,
    matchPhrases: [
      'tub filter',
      'tub bottom',
      'accessible filter at the',
    ],
  ),
  _VisualGuideCatalogEntry(
    anchor: dishwasherDrainHoseGuide,
    matchPhrases: [
      'air gap',
      'disposal inlet',
      'dishwasher drain',
    ],
  ),
  _VisualGuideCatalogEntry(
    anchor: dishwasherSprayArmGuide,
    matchPhrases: ['spray-arm', 'spray arm', 'spray holes'],
  ),
  _VisualGuideCatalogEntry(
    anchor: dishwasherDoorLatchGuide,
    matchPhrases: ['dishwasher door', 'door latch', 'door switch'],
  ),
  _VisualGuideCatalogEntry(
    anchor: dishwasherSupplyGuide,
    matchPhrases: [
      'under-sink',
      'supply tap',
      'dishwasher supply',
    ],
  ),
  _VisualGuideCatalogEntry(
    anchor: fridgeCoilsGuide,
    matchPhrases: [
      'condenser coils',
      'toe-kick grille',
      'accessible coils',
    ],
  ),
  _VisualGuideCatalogEntry(
    anchor: fridgeDoorGasketGuide,
    matchPhrases: ['door gasket', 'gasket for gaps'],
  ),
  _VisualGuideCatalogEntry(
    anchor: fridgeInternalVentGuide,
    matchPhrases: ['internal air vents', 'internal vents'],
  ),
  _VisualGuideCatalogEntry(
    anchor: fridgeDripPanGuide,
    matchPhrases: ['drip pan', 'freezer drain'],
  ),
  _VisualGuideCatalogEntry(
    anchor: fridgeIceMakerGuide,
    matchPhrases: ['ice maker switch', 'ice bin', 'dispenser opening'],
  ),
];

/// True when a guidance step must never get an AR / camera overlay.
bool impliesLiveElectricalProbing(String step) {
  final lower = step.toLowerCase();
  if (lower.contains('multimeter') || lower.contains('energized')) {
    return true;
  }
  final mentionsLive = lower.contains('live');
  if (mentionsLive &&
      (lower.contains('voltage') ||
          lower.contains('electrical') ||
          lower.contains('circuit') ||
          lower.contains('testing') ||
          lower.contains('test') ||
          lower.contains('winding') ||
          lower.contains('probe') ||
          lower.contains('measure') ||
          lower.contains('meter'))) {
    return true;
  }
  if (lower.contains('wiring') &&
      (lower.contains('test') || lower.contains('probe'))) {
    return true;
  }
  return false;
}

const _dryerOnlyVisualGuideTargetIds = {
  'lint-filter',
  'vent-hood',
  'vent-hose',
  'access-panel',
};

/// Appliance family for a pin: authored category, else target / diagram id.
String? inferredVisualGuideFamily(VisualGuideAnchor anchor) {
  final own = (anchor.applianceCategory ?? '').trim();
  if (own.isNotEmpty) {
    return own;
  }
  if (_dryerOnlyVisualGuideTargetIds.contains(anchor.targetId)) {
    return 'dryer';
  }
  if (anchor.targetId.startsWith('washer-') ||
      anchor.targetId == 'drain-filter' ||
      anchor.targetId == 'inlet-hose' ||
      anchor.targetId == 'water-taps') {
    return 'washer';
  }
  if (anchor.targetId.startsWith('dishwasher-')) {
    return 'dishwasher';
  }
  if (anchor.targetId.startsWith('fridge-')) {
    return 'fridge';
  }
  final diagram = (anchor.imageAsset ?? '').toLowerCase();
  if (diagram.contains('dishwasher')) {
    return 'dishwasher';
  }
  if (diagram.contains('washer')) {
    return 'washer';
  }
  if (diagram.contains('fridge')) {
    return 'fridge';
  }
  if (diagram.contains('dryer')) {
    return 'dryer';
  }
  return null;
}

/// Lint-filter MVP: schematic only — never a live/stock box that implies pose.
bool visualGuideTypicalDiagramOnly(VisualGuideAnchor anchor) {
  return anchor.typicalDiagramOnly || anchor.targetId == 'lint-filter';
}

/// Dryer-front lint-filter graphic. Never washer or dishwasher.
bool visualGuideUsesDryerLintFilterGraphic(VisualGuideAnchor anchor) {
  if (inferredVisualGuideFamily(anchor) != 'dryer') {
    return false;
  }
  if (anchor.targetId == 'lint-filter') {
    return true;
  }
  final diagram = (anchor.imageAsset ?? '').toLowerCase();
  return diagram.contains('dryer-front') && !diagram.contains('rear');
}

bool visualGuideAnchorFitsCategory(
  VisualGuideAnchor anchor,
  String? applianceCategory,
) {
  final family = (applianceCategory ?? '').trim();
  final implied = inferredVisualGuideFamily(anchor);
  if (family == 'washer' || family == 'dishwasher') {
    if (implied == 'dryer' || anchor.targetId == 'lint-filter') {
      return false;
    }
    final diagram = (anchor.imageAsset ?? '').toLowerCase();
    if (diagram.contains('dryer')) {
      return false;
    }
  }
  if (family.isEmpty) {
    return true;
  }
  if (implied == null || implied.isEmpty) {
    return true;
  }
  return implied == family;
}

List<VisualGuideAnchor> visualGuidesForAppliance({
  required List<VisualGuideAnchor> guides,
  String? applianceCategory,
}) {
  return [
    for (final guide in guides)
      if (visualGuideAnchorFitsCategory(guide, applianceCategory)) guide,
  ];
}

VisualGuideAnchor? catalogAnchorByTargetId(String targetId) {
  for (final entry in _catalog) {
    if (entry.anchor.targetId == targetId) {
      return entry.anchor;
    }
  }
  return null;
}

/// Fills observational copy from the built-in catalog when authoring JSON
/// only stored a pin (target id + coordinates).
VisualGuideAnchor enrichVisualGuideAnchor(VisualGuideAnchor anchor) {
  final catalog = catalogAnchorByTargetId(anchor.targetId);
  if (catalog == null) {
    return anchor;
  }
  final see = (anchor.whatYouShouldSee ?? '').trim();
  final asset = (anchor.imageAsset ?? '').trim();
  return VisualGuideAnchor(
    targetId: anchor.targetId,
    label: anchor.label.trim().isEmpty ? catalog.label : anchor.label,
    imageAsset: asset.isEmpty ? catalog.imageAsset : anchor.imageAsset,
    anchorX: anchor.anchorX,
    anchorY: anchor.anchorY,
    whatYouShouldSee: see.isEmpty ? catalog.whatYouShouldSee : anchor.whatYouShouldSee,
    applianceCategory: (anchor.applianceCategory ?? '').trim().isEmpty
        ? catalog.applianceCategory
        : anchor.applianceCategory,
    typicalDiagramOnly: anchor.typicalDiagramOnly || catalog.typicalDiagramOnly,
  );
}

List<VisualGuideAnchor> enrichVisualGuides(List<VisualGuideAnchor> anchors) {
  return [for (final anchor in anchors) enrichVisualGuideAnchor(anchor)];
}

VisualGuideAnchor visualGuideAnchorFromJson(Map<String, dynamic> json) {
  return enrichVisualGuideAnchor(
    VisualGuideAnchor(
      targetId: (json['target_id'] ?? json['targetId'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      imageAsset: json['imageAsset'] as String? ?? json['image_asset'] as String?,
      anchorX: (json['anchorX'] as num?)?.toDouble() ??
          (json['anchor_x'] as num?)?.toDouble() ??
          0.5,
      anchorY: (json['anchorY'] as num?)?.toDouble() ??
          (json['anchor_y'] as num?)?.toDouble() ??
          0.38,
      whatYouShouldSee: json['whatYouShouldSee'] as String? ??
          json['what_you_should_see'] as String?,
    ),
  );
}

Map<String, dynamic> visualGuideAnchorToJson(VisualGuideAnchor anchor) {
  return {
    'target_id': anchor.targetId,
    'label': anchor.label,
    if (anchor.imageAsset != null) 'imageAsset': anchor.imageAsset,
    'anchorX': anchor.anchorX,
    'anchorY': anchor.anchorY,
    if (anchor.whatYouShouldSee != null)
      'whatYouShouldSee': anchor.whatYouShouldSee,
  };
}

/// Resolves package visual metadata for a Safe Guidance step, if any.
///
/// [packageAnchors] are optional close-path overlays. Catalog phrases fill in
/// when the step names a known part. Live-electrical language never matches.
/// Dryer lint-filter pins never attach to washer or dishwasher steps.
VisualGuideAnchor? visualGuideForSafeStep(
  String step, {
  List<VisualGuideAnchor> packageAnchors = const [],
  String? applianceCategory,
}) {
  if (impliesLiveElectricalProbing(step)) {
    return null;
  }
  final lower = step.toLowerCase();
  for (final anchor in packageAnchors) {
    if (!visualGuideAnchorFitsCategory(anchor, applianceCategory)) {
      continue;
    }
    if (lower.contains(anchor.targetId.replaceAll('-', ' ')) ||
        lower.contains(anchor.label.toLowerCase())) {
      return enrichVisualGuideAnchor(anchor);
    }
  }
  for (final entry in _catalog) {
    if (!visualGuideAnchorFitsCategory(entry.anchor, applianceCategory)) {
      continue;
    }
    for (final phrase in entry.matchPhrases) {
      if (lower.contains(phrase)) {
        return entry.anchor;
      }
    }
  }
  return null;
}
