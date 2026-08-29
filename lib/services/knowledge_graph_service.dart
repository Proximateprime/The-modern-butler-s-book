import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/kg_category_slugs.dart';
import '../helpers/kg_relation_rules.dart';
import '../models/knowledge_graph.dart';

/// Write/read surface used by the seeder and [KnowledgeGraphService].
abstract class KnowledgeGraphPort {
  Future<KgNode?> getNodeBySlug({
    required KgNodeType nodeType,
    required String slug,
  });

  Future<KgNode> createNode({
    required KgNodeType nodeType,
    required String slug,
    required String name,
    String? description,
    Map<String, dynamic> metadata = const {},
    required String graphVersion,
  });

  Future<KgEdge> createEdge({
    required String sourceNodeId,
    required String targetNodeId,
    required KgRelationType relationType,
    double weight = 0.5,
    Map<String, dynamic> metadata = const {},
    required String graphVersion,
  });
}

/// Read/write access to the platform Knowledge Graph.
///
/// Household data never enters these tables. Callers can cache the full graph
/// locally for offline troubleshooting — sync by [graphVersion] in a later module.
///
/// Regular users have read-only access (RLS). Seeding scripts use the service
/// role to call [createNode] and [createEdge].
class KnowledgeGraphService implements KnowledgeGraphPort {
  KnowledgeGraphService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _nodesTable = 'kg_nodes';
  static const _edgesTable = 'kg_edges';
  static const _versionsTable = 'kg_graph_versions';

  // ---------------------------------------------------------------------------
  // Node CRUD (writes intended for seeding / admin — not end-user UI)
  // ---------------------------------------------------------------------------

  /// Creates a graph node. Returns the saved row with server-generated [id].
  @override
  Future<KgNode> createNode({
    required KgNodeType nodeType,
    required String slug,
    required String name,
    String? description,
    Map<String, dynamic> metadata = const {},
    required String graphVersion,
  }) async {
    final payload = KgNode(
      id: '',
      nodeType: nodeType,
      slug: slug,
      name: name,
      description: description,
      metadata: metadata,
      graphVersion: graphVersion,
    ).toJson(forInsert: true);

    final row =
        await _client.from(_nodesTable).insert(payload).select().single();

    return KgNode.fromJson(row);
  }

  /// Fetches a node by UUID.
  Future<KgNode?> getNodeById(String id) async {
    final row = await _client
        .from(_nodesTable)
        .select()
        .eq('id', id)
        .eq('is_active', true)
        .maybeSingle();

    if (row == null) return null;
    return KgNode.fromJson(row);
  }

  /// Fetches a node by its stable [slug] and [nodeType].
  @override
  Future<KgNode?> getNodeBySlug({
    required KgNodeType nodeType,
    required String slug,
  }) async {
    final row = await _client
        .from(_nodesTable)
        .select()
        .eq('node_type', nodeType.value)
        .eq('slug', slug)
        .eq('is_active', true)
        .maybeSingle();

    if (row == null) return null;
    return KgNode.fromJson(row);
  }

  /// Lists all active nodes of a given type.
  Future<List<KgNode>> listNodesByType(KgNodeType nodeType) async {
    final rows = await _client
        .from(_nodesTable)
        .select()
        .eq('node_type', nodeType.value)
        .eq('is_active', true)
        .order('name');

    return rows.map(KgNode.fromJson).toList();
  }

  // ---------------------------------------------------------------------------
  // Edge CRUD
  // ---------------------------------------------------------------------------

  /// Creates a directed relationship between two nodes.
  ///
  /// Rejects illegal source/target types for [relationType]. Create-only.
  @override
  Future<KgEdge> createEdge({
    required String sourceNodeId,
    required String targetNodeId,
    required KgRelationType relationType,
    double weight = 0.5,
    Map<String, dynamic> metadata = const {},
    required String graphVersion,
  }) async {
    final source = await getNodeById(sourceNodeId);
    final target = await getNodeById(targetNodeId);
    if (source == null || target == null) {
      throw StateError(
        'createEdge requires existing source and target nodes',
      );
    }
    assertLegalKgRelation(
      sourceType: source.nodeType,
      relationType: relationType,
      targetType: target.nodeType,
    );

    final payload = KgEdge(
      id: '',
      sourceNodeId: sourceNodeId,
      targetNodeId: targetNodeId,
      relationType: relationType,
      weight: weight,
      metadata: metadata,
      graphVersion: graphVersion,
    ).toJson(forInsert: true);

    final row =
        await _client.from(_edgesTable).insert(payload).select().single();

    return KgEdge.fromJson(row);
  }

  // ---------------------------------------------------------------------------
  // Relationship queries — building blocks for the Reasoning Engine (later)
  // ---------------------------------------------------------------------------

  /// Outgoing edges from [nodeId], optionally filtered by [relationType].
  Future<List<KgEdge>> getOutgoingEdges(
    String nodeId, {
    KgRelationType? relationType,
  }) async {
    var query = _client
        .from(_edgesTable)
        .select()
        .eq('source_node_id', nodeId)
        .eq('is_active', true);

    if (relationType != null) {
      query = query.eq('relation_type', relationType.value);
    }

    final rows = await query.order('weight', ascending: false);
    return rows.map(KgEdge.fromJson).toList();
  }

  /// Incoming edges to [nodeId], optionally filtered by [relationType].
  Future<List<KgEdge>> getIncomingEdges(
    String nodeId, {
    KgRelationType? relationType,
  }) async {
    var query = _client
        .from(_edgesTable)
        .select()
        .eq('target_node_id', nodeId)
        .eq('is_active', true);

    if (relationType != null) {
      query = query.eq('relation_type', relationType.value);
    }

    final rows = await query.order('weight', ascending: false);
    return rows.map(KgEdge.fromJson).toList();
  }

  /// Nodes reachable from [nodeId] via outgoing edges of [relationType].
  Future<List<KgRelatedNode>> getRelatedNodes(
    String nodeId, {
    required KgRelationType relationType,
  }) async {
    final rows = await _client
        .from(_edgesTable)
        .select('*, target:kg_nodes!kg_edges_target_node_id_fkey(*)')
        .eq('source_node_id', nodeId)
        .eq('relation_type', relationType.value)
        .eq('is_active', true)
        .order('weight', ascending: false);

    return rows.map((row) {
      final edge = KgEdge.fromJson(row);
      final node = KgNode.fromJson(row['target'] as Map<String, dynamic>);
      return KgRelatedNode(edge: edge, node: node);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Example queries — patterns the Reasoning Engine will use later
  // ---------------------------------------------------------------------------

  /// Given an observed symptom, return possible failure modes ranked by weight.
  ///
  /// Traversal: symptom -[suggests]-> failure_mode.
  /// When [applianceCategorySlug] is set (app id or graph slug), keeps only
  /// failure modes with `applies_to` that category. Professional/sealed modes
  /// are omitted unless [includeProfessional] is true.
  Future<List<KgRelatedNode>> getFailureModesForSymptom(
    String symptomNodeId, {
    String? applianceCategorySlug,
    bool includeProfessional = false,
  }) async {
    final suggested = await getRelatedNodes(
      symptomNodeId,
      relationType: KgRelationType.suggests,
    );
    if (applianceCategorySlug == null || applianceCategorySlug.trim().isEmpty) {
      if (includeProfessional) {
        return suggested;
      }
      return [
        for (final item in suggested)
          if (!kgFailureModeIsProfessionalGate(item.node)) item,
      ];
    }

    final graphSlug = kgGraphCategorySlug(applianceCategorySlug);
    final category = await getNodeBySlug(
      nodeType: KgNodeType.applianceCategory,
      slug: graphSlug,
    );
    if (category == null) {
      return const [];
    }

    final out = <KgRelatedNode>[];
    for (final item in suggested) {
      if (!includeProfessional && kgFailureModeIsProfessionalGate(item.node)) {
        continue;
      }
      final applies = await getOutgoingEdges(
        item.node.id,
        relationType: KgRelationType.appliesTo,
      );
      var hitsFamily = false;
      for (final edge in applies) {
        if (edge.targetNodeId == category.id) {
          hitsFamily = true;
          break;
        }
      }
      if (hitsFamily) {
        out.add(item);
      }
    }
    return out;
  }

  /// Subsystems inside an appliance category.
  ///
  /// Traversal: appliance_category -[contains]-> subsystem
  Future<List<KgRelatedNode>> getSubsystemsForCategory(
    String categoryNodeId,
  ) =>
      getRelatedNodes(categoryNodeId, relationType: KgRelationType.contains);

  /// Components inside a subsystem.
  ///
  /// Traversal: subsystem -[contains]-> component
  Future<List<KgRelatedNode>> getComponentsForSubsystem(
    String subsystemNodeId,
  ) =>
      getRelatedNodes(subsystemNodeId, relationType: KgRelationType.contains);

  // ---------------------------------------------------------------------------
  // Offline bundle — download full active graph for local storage
  // ---------------------------------------------------------------------------

  /// Returns all active nodes and edges for offline caching.
  ///
  /// Compare [KgGraphVersion.isCurrent] on sync to detect remote updates.
  Future<({List<KgNode> nodes, List<KgEdge> edges, KgGraphVersion? version})>
      fetchGraphSnapshot() async {
    final versionRow = await _client
        .from(_versionsTable)
        .select()
        .eq('is_current', true)
        .maybeSingle();

    final nodeRows = await _client
        .from(_nodesTable)
        .select()
        .eq('is_active', true);

    final edgeRows = await _client
        .from(_edgesTable)
        .select()
        .eq('is_active', true);

    return (
      nodes: nodeRows.map(KgNode.fromJson).toList(),
      edges: edgeRows.map(KgEdge.fromJson).toList(),
      version: versionRow != null ? KgGraphVersion.fromJson(versionRow) : null,
    );
  }
}
