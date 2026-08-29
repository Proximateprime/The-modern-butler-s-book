import 'package:modern_butlers_book/helpers/kg_relation_rules.dart';
import 'package:modern_butlers_book/models/knowledge_graph.dart';
import 'package:modern_butlers_book/services/knowledge_graph_service.dart';

/// In-memory graph for seeder / createEdge tests (no Supabase).
class InMemoryKnowledgeGraph implements KnowledgeGraphPort {
  final Map<String, KgNode> nodesById = {};
  final Map<String, KgNode> nodesByTypeSlug = {};
  final List<KgEdge> edges = [];
  var _n = 0;
  var _e = 0;

  String _nodeKey(KgNodeType type, String slug) => '${type.value}::$slug';

  @override
  Future<KgNode?> getNodeBySlug({
    required KgNodeType nodeType,
    required String slug,
  }) async {
    return nodesByTypeSlug[_nodeKey(nodeType, slug)];
  }

  @override
  Future<KgNode> createNode({
    required KgNodeType nodeType,
    required String slug,
    required String name,
    String? description,
    Map<String, dynamic> metadata = const {},
    required String graphVersion,
  }) async {
    _n += 1;
    final node = KgNode(
      id: 'n-$_n',
      nodeType: nodeType,
      slug: slug,
      name: name,
      description: description,
      metadata: metadata,
      graphVersion: graphVersion,
    );
    nodesById[node.id] = node;
    nodesByTypeSlug[_nodeKey(nodeType, slug)] = node;
    return node;
  }

  @override
  Future<KgEdge> createEdge({
    required String sourceNodeId,
    required String targetNodeId,
    required KgRelationType relationType,
    double weight = 0.5,
    Map<String, dynamic> metadata = const {},
    required String graphVersion,
  }) async {
    final source = nodesById[sourceNodeId];
    final target = nodesById[targetNodeId];
    if (source == null || target == null) {
      throw StateError('createEdge requires existing source and target nodes');
    }
    assertLegalKgRelation(
      sourceType: source.nodeType,
      relationType: relationType,
      targetType: target.nodeType,
    );
    _e += 1;
    final edge = KgEdge(
      id: 'e-$_e',
      sourceNodeId: sourceNodeId,
      targetNodeId: targetNodeId,
      relationType: relationType,
      weight: weight,
      metadata: metadata,
      graphVersion: graphVersion,
    );
    edges.add(edge);
    return edge;
  }
}
