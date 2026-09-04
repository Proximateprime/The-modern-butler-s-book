import '../knowledge/dryer_brand_overlays.dart';
import '../models/appliance.dart';
import '../models/knowledge_package.dart';
import '../services/knowledge_package_repository.dart';
import 'visual_guide.dart';

/// Honest UI copy when no brand overlay matched.
///
/// Says what it means for the household, not just which package loaded.
const String generalDryerGuideNotice =
    'General dryer guide — the checks below apply to most dryers, but panel '
    'and part locations on your model may differ.';

/// Result of resolving a base family package plus an optional brand overlay.
///
/// Overlay may tweak package-authored commonality and access notes.
/// Ranking algorithms are unchanged.
class PackageResolution {
  const PackageResolution({
    required this.basePackage,
    required this.package,
    this.overlay,
    this.usingGeneralGuide = true,
  });

  final KnowledgePackage basePackage;
  final KnowledgePackage package;
  final BrandPackageOverlay? overlay;
  final bool usingGeneralGuide;

  String get basePackageId => basePackage.id;
  String get basePackageVersion => basePackage.version;
  String? get overlayId => overlay?.id;
  String? get overlayVersion => overlay?.version;

  String? get coverageNotice =>
      usingGeneralGuide && basePackage.category == 'dryer'
          ? generalDryerGuideNotice
          : null;

  List<String> get accessNotes => overlay?.accessNotes ?? const [];
}

/// Maps manufacturer + model onto the bundled family package and overlay.
///
/// Unknown model → universal base, no crash. Washer/fridge/dishwasher return
/// their thin universal package with no brand tree in this mission.
PackageResolution resolveKnowledgePackage({
  required KnowledgePackageRepository repository,
  required String category,
  String? manufacturer,
  String? modelNumber,
  KnowledgePackage? baseOverride,
}) {
  final base =
      baseOverride ??
      _basePackageForCategory(repository, category);
  if (base == null) {
    throw StateError('No knowledge package is installed for $category.');
  }

  final overlay = matchBrandOverlay(
    category: category,
    manufacturer: manufacturer,
    modelNumber: modelNumber,
  );
  if (overlay == null) {
    return PackageResolution(
      basePackage: base,
      package: base,
      usingGeneralGuide: true,
    );
  }

  return PackageResolution(
    basePackage: base,
    package: applyBrandOverlay(base, overlay),
    overlay: overlay,
    usingGeneralGuide: false,
  );
}

PackageResolution resolveKnowledgePackageForAppliance({
  required KnowledgePackageRepository repository,
  required Appliance appliance,
}) {
  return resolveKnowledgePackage(
    repository: repository,
    category: appliance.category,
    manufacturer: appliance.manufacturer,
    modelNumber: appliance.modelNumber,
  );
}

/// Same as [resolveKnowledgePackage], or null when no family package is installed.
PackageResolution? tryResolveKnowledgePackage({
  required KnowledgePackageRepository repository,
  required String category,
  String? manufacturer,
  String? modelNumber,
  KnowledgePackage? baseOverride,
}) {
  try {
    return resolveKnowledgePackage(
      repository: repository,
      category: category,
      manufacturer: manufacturer,
      modelNumber: modelNumber,
      baseOverride: baseOverride,
    );
  } on StateError {
    return null;
  }
}

PackageResolution? tryResolveKnowledgePackageForAppliance({
  required KnowledgePackageRepository repository,
  required Appliance appliance,
}) {
  return tryResolveKnowledgePackage(
    repository: repository,
    category: appliance.category,
    manufacturer: appliance.manufacturer,
    modelNumber: appliance.modelNumber,
  );
}

BrandPackageOverlay? matchBrandOverlay({
  required String category,
  String? manufacturer,
  String? modelNumber,
}) {
  final overlays = overlaysForCategory(category);
  if (overlays.isEmpty) {
    return null;
  }
  final model = (modelNumber ?? '').trim().toUpperCase();
  final brand = (manufacturer ?? '').trim().toLowerCase();

  if (model.isNotEmpty) {
    for (final overlay in overlays) {
      for (final prefix in overlay.modelPrefixes) {
        final token = prefix.toUpperCase();
        if (token.isEmpty) {
          continue;
        }
        if (model.startsWith(token)) {
          return overlay;
        }
      }
    }
  }

  if (brand.isEmpty) {
    return null;
  }
  for (final overlay in overlays) {
    for (final alias in overlay.brandAliases) {
      if (brand.contains(alias.toLowerCase())) {
        return overlay;
      }
    }
  }
  return null;
}

KnowledgePackage applyBrandOverlay(
  KnowledgePackage base,
  BrandPackageOverlay overlay,
) {
  if (overlay.category != base.category) {
    return base;
  }
  if (overlay.commonalityOverrides.isEmpty) {
    return base;
  }
  return base.withFailureModes([
    for (final mode in base.failureModes)
      mode.copyWith(
        commonality: overlay.commonalityOverrides[mode.id],
      ),
  ]);
}

/// Pins for Safe Guidance, with catalog copy and overlay diagram keys.
List<VisualGuideAnchor> visualGuidesForOverlay({
  required List<VisualGuideAnchor> guides,
  BrandPackageOverlay? overlay,
}) {
  return [
    for (final guide in enrichVisualGuides(guides))
      guide.copyWith(
        imageAsset:
            overlay?.diagramKeysByTargetId[guide.targetId] ?? guide.imageAsset,
      ),
  ];
}

KnowledgePackage? _basePackageForCategory(
  KnowledgePackageRepository repository,
  String category,
) {
  final matches = repository.loadByCategory(category);
  if (matches.isEmpty) {
    return null;
  }
  for (final package in matches) {
    if (category == 'dryer' && package.id == 'dryer-core') {
      return package;
    }
  }
  return matches.first;
}
