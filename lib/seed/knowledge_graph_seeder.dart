import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/kg_relation_rules.dart';
import '../models/knowledge_graph.dart';
import '../services/knowledge_graph_service.dart';
import 'kg_mvp_seed_data.dart';

/// Seeds MVP Phase 1 Knowledge Graph content via the Supabase service role.
///
/// **Preferred path:** run the SQL migrations
/// `supabase/migrations/20260716000003_seed_knowledge_graph_mvp.sql` and
/// `supabase/migrations/20260828000001_george_graph_seed_fixes.sql`.
///
/// Use this Dart seeder only when you need programmatic seeding (e.g. CI or
/// local dev with a service-role client). Requires bypassing RLS.
class KnowledgeGraphSeeder {
  KnowledgeGraphSeeder({
    SupabaseClient? serviceRoleClient,
    KnowledgeGraphPort? graph,
  }) : _kg =
           graph ??
           KnowledgeGraphService(
             client:
                 serviceRoleClient ??
                 (throw ArgumentError(
                   'KnowledgeGraphSeeder needs a graph port or service-role client',
                 )),
           );

  final KnowledgeGraphPort _kg;

  /// In-memory slug → node id map built during seeding.
  final Map<String, String> _nodeIds = {};

  String _key(String type, String slug) => '$type::$slug';

  /// Inserts all nodes from [kgMvpNodes] and edges from [kgMvpEdges].
  ///
  /// Each edge is written with its authored [KgSeedEdge.relation]. There is no
  /// automatic `suggests` rewrite and no automatic `produces` mirror.
  Future<({int nodes, int edges})> seedMvpPhase1() async {
    var nodeCount = 0;
    var edgeCount = 0;

    for (final seed in kgMvpNodes) {
      final existing = await _kg.getNodeBySlug(
        nodeType: _parseType(seed.type),
        slug: seed.slug,
      );

      if (existing != null) {
        _nodeIds[_key(seed.type, seed.slug)] = existing.id;
        continue;
      }

      final node = await _kg.createNode(
        nodeType: _parseType(seed.type),
        slug: seed.slug,
        name: seed.name,
        description: seed.description,
        metadata: {...kgMvpSourceMeta, ...seed.metadata},
        graphVersion: kgMvpVersion,
      );
      _nodeIds[_key(seed.type, seed.slug)] = node.id;
      nodeCount++;
    }

    for (final seed in kgMvpEdges) {
      final sourceId = _nodeIds[_key(seed.sourceType, seed.sourceSlug)];
      final targetId = _nodeIds[_key(seed.targetType, seed.targetSlug)];
      if (sourceId == null || targetId == null) continue;

      final relation = KgRelationType.fromString(seed.relation);
      assertLegalKgRelation(
        sourceType: _parseType(seed.sourceType),
        relationType: relation,
        targetType: _parseType(seed.targetType),
      );

      await _kg.createEdge(
        sourceNodeId: sourceId,
        targetNodeId: targetId,
        relationType: relation,
        weight: seed.weight,
        metadata: seed.note != null ? {'note': seed.note} : const {},
        graphVersion: kgMvpVersion,
      );
      edgeCount++;
    }

    return (nodes: nodeCount, edges: edgeCount);
  }

  KgNodeType _parseType(String type) {
    switch (type) {
      case 'appliance_category':
        return KgNodeType.applianceCategory;
      case 'subsystem':
        return KgNodeType.subsystem;
      case 'component':
        return KgNodeType.component;
      case 'symptom':
        return KgNodeType.symptom;
      case 'failure_mode':
        return KgNodeType.failureMode;
      default:
        throw ArgumentError('Unknown node type: $type');
    }
  }
}
