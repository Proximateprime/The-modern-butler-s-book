// ignore_for_file: avoid_print

import '../models/knowledge_graph.dart';
import '../services/knowledge_graph_service.dart';

/// Example queries against the MVP Phase 1 seeded graph.
///
/// Run after applying migration `20260716000003_seed_knowledge_graph_mvp.sql`.
/// These patterns are what the Reasoning Engine will use in a later module.
class KgQueryExamples {
  KgQueryExamples({KnowledgeGraphService? kg})
      : _kg = kg ?? KnowledgeGraphService();

  final KnowledgeGraphService _kg;

  /// Scenario from the Seeding Plan:
  /// "My dishwasher leaves water in the bottom and I hear the pump running."
  ///
  /// Step 1: Look up the observed symptom by stable slug (offline-friendly).
  Future<void> dishwasherStandingWaterScenario() async {
    final symptom = await _kg.getNodeBySlug(
      nodeType: KgNodeType.symptom,
      slug: 'standing-water',
    );
    if (symptom == null) {
      print('Symptom not found — run MVP seed migration first.');
      return;
    }

    // Step 2: Traverse symptom → [suggests] → failure_mode (ranked by weight).
    final hypotheses = await _kg.getFailureModesForSymptom(
      symptom.id,
      applianceCategorySlug: 'dishwasher',
    );

    print('Observed: ${symptom.name}');
    print('Possible explanations (not diagnoses):');
    for (final h in hypotheses) {
      // Filter to dishwasher failure modes only (Phase 1 prefix convention).
      if (!h.node.slug.startsWith('dishwasher-')) continue;
      final pct = (h.edge.weight * 100).toStringAsFixed(0);
      print('  • ${h.node.name} (association: $pct%)');
      print('    ${h.node.description ?? ''}');
    }
  }

  /// Explore appliance anatomy: category → subsystems → components.
  Future<void> exploreDishwasherStructure() async {
    final category = await _kg.getNodeBySlug(
      nodeType: KgNodeType.applianceCategory,
      slug: 'dishwasher',
    );
    if (category == null) return;

    final subsystems = await _kg.getSubsystemsForCategory(category.id);
    print('${category.name} subsystems:');
    for (final sub in subsystems) {
      print('  ▸ ${sub.node.name}');
      final components = await _kg.getComponentsForSubsystem(sub.node.id);
      for (final comp in components) {
        print('      – ${comp.node.name}');
      }
    }
  }

  /// Download full graph for offline storage.
  Future<void> cacheGraphForOffline() async {
    final snapshot = await _kg.fetchGraphSnapshot();
    print('Graph version: ${snapshot.version?.version ?? "unknown"}');
    print('Nodes: ${snapshot.nodes.length}, Edges: ${snapshot.edges.length}');
    // In a later module: write snapshot to local SQLite / Hive using slugs as keys.
  }

  /// Match a user's appliance category to graph categories.
  Future<List<KgNode>> listMvpCategories() =>
      _kg.listNodesByType(KgNodeType.applianceCategory);
}

/// Quick manual test entry point (requires authenticated Supabase session):
///
/// ```dart
/// void main() async {
///   await Supabase.initialize(url: '...', anonKey: '...');
///   final examples = KgQueryExamples();
///   await examples.dishwasherStandingWaterScenario();
///   await examples.exploreDishwasherStructure();
///   await examples.cacheGraphForOffline();
/// }
/// ```
