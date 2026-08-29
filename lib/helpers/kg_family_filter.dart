import '../models/knowledge_graph.dart';
import '../seed/kg_mvp_seed_data.dart';
import 'kg_category_slugs.dart';
import 'kg_relation_rules.dart';

/// Whether [failureModeSlug] has an `applies_to` edge for [familySlug].
bool kgFailureModeAppliesToFamily({
  required String failureModeSlug,
  required String familySlug,
  Iterable<KgSeedEdge>? edges,
}) {
  final catalog = edges ?? kgMvpEdges;
  final graph = kgGraphCategorySlug(familySlug);
  for (final edge in catalog) {
    if (edge.relation != 'applies_to') {
      continue;
    }
    if (edge.sourceType != 'failure_mode' ||
        edge.sourceSlug != failureModeSlug) {
      continue;
    }
    if (edge.targetType != 'appliance_category') {
      continue;
    }
    if (kgGraphCategorySlug(edge.targetSlug) == graph) {
      return true;
    }
  }
  return false;
}

/// Symptom → failure-mode slugs, scoped to one appliance family.
List<String> kgSuggestedFailureModeSlugsForFamily({
  required String symptomSlug,
  required String familySlug,
  Iterable<KgSeedEdge>? edges,
  bool includeProfessional = false,
  Iterable<KgSeedNode>? nodes,
}) {
  final catalog = edges ?? kgMvpEdges;
  final nodeCatalog = nodes ?? kgMvpNodes;
  final out = <String>[];
  for (final edge in catalog) {
    if (edge.relation != 'suggests') {
      continue;
    }
    if (edge.sourceType != 'symptom' || edge.sourceSlug != symptomSlug) {
      continue;
    }
    if (edge.targetType != 'failure_mode') {
      continue;
    }
    final slug = edge.targetSlug;
    if (!kgFailureModeAppliesToFamily(
      failureModeSlug: slug,
      familySlug: familySlug,
      edges: catalog,
    )) {
      continue;
    }
    if (!includeProfessional) {
      KgSeedNode? node;
      for (final candidate in nodeCatalog) {
        if (candidate.type == 'failure_mode' && candidate.slug == slug) {
          node = candidate;
          break;
        }
      }
      if (node != null &&
          kgFailureModeMetadataIsProfessionalGate(node.metadata)) {
        continue;
      }
    }
    out.add(slug);
  }
  return out;
}

/// Filters already-loaded suggests results using `applies_to` edges in [allEdges].
List<KgRelatedNode> filterKgFailureModesForFamily({
  required List<KgRelatedNode> suggested,
  required String familySlug,
  required List<KgEdge> allEdges,
  required List<KgNode> allNodes,
  bool includeProfessional = false,
}) {
  final graph = kgGraphCategorySlug(familySlug);
  KgNode? category;
  for (final node in allNodes) {
    if (node.nodeType == KgNodeType.applianceCategory &&
        kgGraphCategorySlug(node.slug) == graph) {
      category = node;
      break;
    }
  }
  if (category == null) {
    return const [];
  }

  final appliesTargets = <String, Set<String>>{};
  for (final edge in allEdges) {
    if (edge.relationType != KgRelationType.appliesTo) {
      continue;
    }
    appliesTargets
        .putIfAbsent(edge.sourceNodeId, () => <String>{})
        .add(edge.targetNodeId);
  }

  final nodesById = {for (final node in allNodes) node.id: node};
  final out = <KgRelatedNode>[];
  for (final item in suggested) {
    final targets = appliesTargets[item.node.id];
    if (targets == null || !targets.contains(category.id)) {
      continue;
    }
    if (!includeProfessional && kgFailureModeIsProfessionalGate(item.node)) {
      continue;
    }
    final resolved = nodesById[item.node.id] ?? item.node;
    out.add(KgRelatedNode(edge: item.edge, node: resolved));
  }
  return out;
}
