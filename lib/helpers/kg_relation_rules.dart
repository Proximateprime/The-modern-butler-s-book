import '../models/knowledge_graph.dart';

/// Thrown when [createEdge] would write a relation between incompatible node types.
class IllegalKgRelationException implements Exception {
  IllegalKgRelationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Legal (source type, relation, target type) pairs for MVP graph writes.
bool kgRelationTypesAreLegal({
  required KgNodeType sourceType,
  required KgRelationType relationType,
  required KgNodeType targetType,
}) {
  switch (relationType) {
    case KgRelationType.contains:
      return (sourceType == KgNodeType.applianceCategory &&
              targetType == KgNodeType.subsystem) ||
          (sourceType == KgNodeType.subsystem &&
              targetType == KgNodeType.component);
    case KgRelationType.belongsTo:
      return sourceType == KgNodeType.component &&
          targetType == KgNodeType.subsystem;
    case KgRelationType.produces:
      return sourceType == KgNodeType.failureMode &&
          targetType == KgNodeType.symptom;
    case KgRelationType.suggests:
      return sourceType == KgNodeType.symptom &&
          targetType == KgNodeType.failureMode;
    case KgRelationType.affects:
      return sourceType == KgNodeType.failureMode &&
          targetType == KgNodeType.component;
    case KgRelationType.appliesTo:
      return sourceType == KgNodeType.failureMode &&
          targetType == KgNodeType.applianceCategory;
  }
}

/// Rejects illegal combinations (e.g. symptom → subsystem [contains]).
void assertLegalKgRelation({
  required KgNodeType sourceType,
  required KgRelationType relationType,
  required KgNodeType targetType,
}) {
  if (kgRelationTypesAreLegal(
    sourceType: sourceType,
    relationType: relationType,
    targetType: targetType,
  )) {
    return;
  }
  throw IllegalKgRelationException(
    'Illegal knowledge-graph edge: ${sourceType.value} -[${relationType.value}]-> '
    '${targetType.value}',
  );
}

/// True when a failure-mode node is professional / sealed / not beginner DIY.
bool kgFailureModeIsProfessionalGate(KgNode node) {
  if (node.nodeType != KgNodeType.failureMode) {
    return false;
  }
  return kgFailureModeMetadataIsProfessionalGate(node.metadata);
}

bool kgFailureModeMetadataIsProfessionalGate(Map<String, dynamic> metadata) {
  if (metadata['beginner_diy'] == false) {
    return true;
  }
  final difficulty = '${metadata['difficulty'] ?? ''}'.toLowerCase();
  if (difficulty == 'professional' || difficulty == 'pro') {
    return true;
  }
  final safety = '${metadata['safety'] ?? ''}'.toLowerCase();
  if (safety.contains('sealed') || safety.contains('refrigerant')) {
    return true;
  }
  final gate = '${metadata['safety_gate'] ?? ''}'.toLowerCase();
  return gate.contains('sealed') || gate.contains('professional');
}
