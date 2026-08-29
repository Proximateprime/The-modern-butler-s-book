import '../knowledge_factory/fridge_mvp_v01.dart';
import '../knowledge_factory/dishwasher_mvp_v01.dart';
import '../knowledge_factory/washer_mvp_v01.dart';

/// Bundled guide that can be installed from this device. No cloud download.
class BundledKnowledgePackage {
  const BundledKnowledgePackage({
    required this.category,
    required this.id,
    required this.version,
    required this.displayName,
  });

  final String category;
  final String id;
  final String version;
  final String displayName;
}

/// Local catalog of appliance guides shipped with the app.
/// Version bumps still need a human on docs/knowledge/PACKAGE_RELEASE_CHECKLIST.md.
abstract final class BundledKnowledgePackageCatalog {
  static const dryer = BundledKnowledgePackage(
    category: 'dryer',
    id: 'dryer-core',
    version: '1.4.2',
    displayName: 'Dryer guide',
  );

  static const washer = BundledKnowledgePackage(
    category: 'washer',
    id: washerPackageId,
    version: washerPackageVersion,
    displayName: 'Washer guide',
  );

  static const fridge = BundledKnowledgePackage(
    category: 'fridge',
    id: fridgePackageId,
    version: fridgePackageVersion,
    displayName: 'Fridge guide',
  );

  static const dishwasher = BundledKnowledgePackage(
    category: 'dishwasher',
    id: dishwasherPackageId,
    version: dishwasherPackageVersion,
    displayName: 'Dishwasher guide',
  );

  static const List<BundledKnowledgePackage> all = [
    dryer,
    washer,
    fridge,
    dishwasher,
  ];

  static BundledKnowledgePackage? forCategory(String category) {
    for (final item in all) {
      if (item.category == category) {
        return item;
      }
    }
    return null;
  }
}

/// Screenshot-citable `id version`, matching docs/qa/PACKAGE_INVENTORY.md.
String knowledgePackageIdVersionLabel({
  required String id,
  required String version,
}) {
  return '$id $version';
}

/// Package manager / About status line. Display only.
String knowledgePackageStatusLine({
  required String id,
  required String version,
  required bool installed,
}) {
  if (!installed) {
    return 'Not on this device';
  }
  return '${knowledgePackageIdVersionLabel(id: id, version: version)} · Installed';
}

/// Stub “check for updates” copy. Never hits a network.
String packageUpdatesStubMessage({required bool online}) {
  if (!online) {
    return 'You’re offline. Guides already on this device still work.';
  }
  return 'No updates. You’re using the guides installed on this device.';
}
