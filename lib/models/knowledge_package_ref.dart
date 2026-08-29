import 'knowledge_package.dart';

/// Minimal immutable reference to the versioned knowledge used by a session.
///
/// This is an identity record only. It contains no Knowledge Graph data or
/// traversal behavior.
class KnowledgePackageRef {
  const KnowledgePackageRef({
    required this.id,
    required this.applianceCategory,
    required this.version,
    required this.displayName,
  });

  final String id;
  final String applianceCategory;
  final String version;
  final String displayName;

  factory KnowledgePackageRef.fromPackage(KnowledgePackage package) {
    return KnowledgePackageRef(
      id: package.id,
      applianceCategory: package.category,
      version: package.version,
      displayName: package.displayName,
    );
  }
}
