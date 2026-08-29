import '../models/knowledge_package.dart';

/// Brand/family overlay on top of a universal appliance-family package.
///
/// Display, access hints, and package-authored commonality only.
/// Does not change ranking code.
class BrandPackageOverlay {
  const BrandPackageOverlay({
    required this.id,
    required this.version,
    required this.displayName,
    required this.category,
    required this.brandAliases,
    required this.modelPrefixes,
    this.commonalityOverrides = const {},
    this.accessNotes = const [],
    this.diagramKeysByTargetId = const {},
    this.partsHints = const {},
    this.insufficientCoverageSymptomIds = const [],
  });

  final String id;
  final String version;
  final String displayName;
  final String category;
  final List<String> brandAliases;
  final List<String> modelPrefixes;
  final Map<String, FailureModeCommonality> commonalityOverrides;
  final List<String> accessNotes;
  final Map<String, String> diagramKeysByTargetId;
  final Map<String, String> partsHints;
  final List<String> insufficientCoverageSymptomIds;
}

/// Dryer overlays for major electric-dryer lineages. Observational notes only.
const List<BrandPackageOverlay> dryerBrandOverlays = [
  BrandPackageOverlay(
    id: 'dryer-overlay-whirlpool-maytag-kenmore',
    version: '1.0.0',
    displayName: 'Whirlpool / Maytag / Kenmore dryer notes',
    category: 'dryer',
    brandAliases: [
      'whirlpool',
      'maytag',
      'kenmore',
      'amana',
      'estate',
      'roper',
    ],
    modelPrefixes: [
      'WED',
      'WGD',
      'MED',
      'MGD',
      'YWED',
      'YMED',
      '7MWED',
      '110.',
      '110',
    ],
    commonalityOverrides: {
      'restricted-exhaust-airflow': FailureModeCommonality.veryHigh,
      'clogged-lint-pathway': FailureModeCommonality.veryHigh,
    },
    accessNotes: [
      'Typical lint filter is a screen on top of the drum opening — yours may '
          'vary. Pull it straight up before every load.',
      'The exhaust collar is typically on the rear cabinet. Check the visible '
          'hose for crush or packed lint — do not open sealed cabinets.',
      'If a thermal fuse is suspected, stop DIY after unplug and exterior '
          'vent checks. Panel layouts vary; call a pro rather than probing.',
    ],
    diagramKeysByTargetId: {
      'lint-filter': 'diagram:dryer-front',
      'vent-hood': 'diagram:dryer-rear',
    },
    partsHints: {
      'restricted-exhaust-airflow':
          'Flexible rear vent kit and a replacement lint screen are common.',
    },
  ),
  BrandPackageOverlay(
    id: 'dryer-overlay-ge-hotpoint',
    version: '1.0.0',
    displayName: 'GE / Hotpoint dryer notes',
    category: 'dryer',
    brandAliases: ['ge', 'general electric', 'hotpoint', 'haier'],
    modelPrefixes: ['GTD', 'GFD', 'GUD', 'DSK', 'HTX', 'NWL'],
    commonalityOverrides: {
      'restricted-exhaust-airflow': FailureModeCommonality.veryHigh,
      'thermal-fuse-open': FailureModeCommonality.high,
    },
    accessNotes: [
      'Many GE-family electric dryers put the lint filter in the door opening '
          'or a slot at the top of the drum — check both places.',
      'The rear exhaust outlet is often lower on the back panel. Look at the '
          'hose connection from the outside only.',
      'Heater-housing access is commonly a rear or lower panel after unplug. '
          'Typical location only — yours may vary. Not a live-electrical check.',
    ],
    diagramKeysByTargetId: {
      'lint-filter': 'diagram:dryer-front',
      'access-panel': 'diagram:dryer-rear',
      'vent-hood': 'diagram:dryer-rear',
    },
    partsHints: {
      'thermal-fuse-open':
          'Exact-match thermal fuse after unplug; never bypass. Call a pro '
          'if the panel is unclear.',
    },
  ),
  BrandPackageOverlay(
    id: 'dryer-overlay-samsung',
    version: '1.0.0',
    displayName: 'Samsung dryer notes',
    category: 'dryer',
    brandAliases: ['samsung'],
    modelPrefixes: ['DVE', 'DVG', 'DV42', 'DV45', 'DV48', 'DV50', 'DV22'],
    commonalityOverrides: {
      'restricted-exhaust-airflow': FailureModeCommonality.veryHigh,
      'clogged-lint-pathway': FailureModeCommonality.high,
    },
    accessNotes: [
      'Lint filter is typically a top-of-drum mesh — yours may vary. Also '
          'check the lint housing slot once the screen is out.',
      'Rear vent hose should be as short and straight as you can make it. '
          'Avoid foil accordion crush behind the cabinet.',
      'Do not use moisture-sensor bars or wiring as a DIY test. Exterior '
          'heat and airflow checks only.',
    ],
    diagramKeysByTargetId: {
      'lint-filter': 'diagram:dryer-front',
      'vent-hood': 'diagram:dryer-rear',
    },
    insufficientCoverageSymptomIds: ['squealing-or-thumping'],
    partsHints: {
      'clogged-lint-pathway':
          'Replacement lint screen if the mesh is torn. Housing packing still '
          'needs a beginner-safe clean, not a teardown.',
    },
  ),
  BrandPackageOverlay(
    id: 'dryer-overlay-lg',
    version: '1.0.0',
    displayName: 'LG dryer notes',
    category: 'dryer',
    brandAliases: ['lg'],
    modelPrefixes: ['DLE', 'DLG', 'DLEX', 'DLGX', 'DLHC'],
    accessNotes: [
      'Lint filter is usually in the door opening. Clean the mesh and look '
          'into the slot for packed lint.',
      'Confirm the cycle is a heat cycle, not Air Dry. LG controls can look '
          'like heat is on when it is not.',
      'Stop for gas models: this book does not guide gas-burner DIY.',
    ],
    diagramKeysByTargetId: {
      'lint-filter': 'diagram:dryer-front',
    },
  ),
  BrandPackageOverlay(
    id: 'dryer-overlay-electrolux-frigidaire',
    version: '1.0.0',
    displayName: 'Electrolux / Frigidaire dryer notes',
    category: 'dryer',
    brandAliases: ['electrolux', 'frigidaire'],
    modelPrefixes: ['EFME', 'EFMG', 'FFRE', 'FFRG', 'FAQE', 'FAQG'],
    accessNotes: [
      'Lint screen is commonly in the door well. Check the housing slot after '
          'removing it.',
      'Rear vent connection is a standard 4-inch collar. Inspect crush and '
          'lint at the cabinet, from the outside.',
    ],
    diagramKeysByTargetId: {
      'lint-filter': 'diagram:dryer-front',
      'vent-hood': 'diagram:dryer-rear',
    },
  ),
];

List<BrandPackageOverlay> overlaysForCategory(String category) {
  if (category == 'dryer') {
    return dryerBrandOverlays;
  }
  return const [];
}
