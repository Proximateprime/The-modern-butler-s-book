/// Knowledge Graph models — platform engineering knowledge, not household data.
///
/// Aligned with Volume VIII, Chapter 7. Symptoms are observations; failure modes
/// are hypotheses the Reasoning Engine will evaluate later.
///
/// JSON keys use snake_case to match Supabase column names.

/// Node types in the Knowledge Graph.
enum KgNodeType {
  applianceCategory('appliance_category'),
  subsystem('subsystem'),
  component('component'),
  symptom('symptom'),
  failureMode('failure_mode');

  const KgNodeType(this.value);
  final String value;

  static KgNodeType fromString(String value) {
    return KgNodeType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => throw ArgumentError('Unknown KgNodeType: $value'),
    );
  }
}

/// Directed relationship types between nodes.
///
/// Example traversal for reasoning (later module):
/// symptom -[suggests]-> failure_mode -[produces]-> symptom (verify loop)
enum KgRelationType {
  /// category → subsystem, subsystem → component
  contains('contains'),

  /// component → subsystem
  belongsTo('belongs_to'),

  /// failure_mode → symptom
  produces('produces'),

  /// symptom → failure_mode — primary entry point for hypothesis generation
  suggests('suggests'),

  /// failure_mode → component
  affects('affects'),

  /// failure_mode → appliance_category
  appliesTo('applies_to');

  const KgRelationType(this.value);
  final String value;

  static KgRelationType fromString(String value) {
    return KgRelationType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => throw ArgumentError('Unknown KgRelationType: $value'),
    );
  }
}

/// A version tag for a batch of graph content (reversible updates).
class KgGraphVersion {
  const KgGraphVersion({
    required this.version,
    this.description,
    this.publishedAt,
    this.isCurrent = false,
  });

  final String version;
  final String? description;
  final DateTime? publishedAt;
  final bool isCurrent;

  factory KgGraphVersion.fromJson(Map<String, dynamic> json) {
    return KgGraphVersion(
      version: json['version'] as String,
      description: json['description'] as String?,
      publishedAt: _parseDateTime(json['published_at']),
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'description': description,
        if (publishedAt != null)
          'published_at': publishedAt!.toIso8601String(),
        'is_current': isCurrent,
      };

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }
}

/// A single node in the Knowledge Graph.
class KgNode {
  const KgNode({
    required this.id,
    required this.nodeType,
    required this.slug,
    required this.name,
    this.description,
    this.metadata = const {},
    required this.graphVersion,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final KgNodeType nodeType;

  /// Stable key for offline bundles, e.g. `standing-water`.
  final String slug;

  /// Beginner-friendly label, e.g. "Standing water in the bottom".
  final String name;
  final String? description;
  final Map<String, dynamic> metadata;
  final String graphVersion;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory KgNode.fromJson(Map<String, dynamic> json) {
    return KgNode(
      id: json['id'] as String,
      nodeType: KgNodeType.fromString(json['node_type'] as String),
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      graphVersion: json['graph_version'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final map = <String, dynamic>{
      'node_type': nodeType.value,
      'slug': slug,
      'name': name,
      'description': description,
      'metadata': metadata,
      'graph_version': graphVersion,
      'is_active': isActive,
    };
    if (!forInsert) {
      map['id'] = id;
      if (createdAt != null) map['created_at'] = createdAt!.toIso8601String();
      if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    }
    return map;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }
}

/// A directed edge between two nodes.
class KgEdge {
  const KgEdge({
    required this.id,
    required this.sourceNodeId,
    required this.targetNodeId,
    required this.relationType,
    this.weight = 0.5,
    this.metadata = const {},
    required this.graphVersion,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String sourceNodeId;
  final String targetNodeId;
  final KgRelationType relationType;

  /// Association strength 0–1. Ranking hint, not a diagnosis.
  final double weight;
  final Map<String, dynamic> metadata;
  final String graphVersion;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory KgEdge.fromJson(Map<String, dynamic> json) {
    return KgEdge(
      id: json['id'] as String,
      sourceNodeId: json['source_node_id'] as String,
      targetNodeId: json['target_node_id'] as String,
      relationType: KgRelationType.fromString(json['relation_type'] as String),
      weight: (json['weight'] as num?)?.toDouble() ?? 0.5,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      graphVersion: json['graph_version'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson({bool forInsert = false}) {
    final map = <String, dynamic>{
      'source_node_id': sourceNodeId,
      'target_node_id': targetNodeId,
      'relation_type': relationType.value,
      'weight': weight,
      'metadata': metadata,
      'graph_version': graphVersion,
      'is_active': isActive,
    };
    if (!forInsert) {
      map['id'] = id;
      if (createdAt != null) map['created_at'] = createdAt!.toIso8601String();
      if (updatedAt != null) map['updated_at'] = updatedAt!.toIso8601String();
    }
    return map;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }
}

/// An edge with its target node attached — common query result shape.
class KgRelatedNode {
  const KgRelatedNode({required this.edge, required this.node});

  final KgEdge edge;
  final KgNode node;
}
