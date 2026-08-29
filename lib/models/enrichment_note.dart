/// Locally stored research/enrichment — never production package truth.
///
/// Runtime diagnosis still comes from packages + evidence. These notes fill
/// household-specific gaps (model quirk, unmatched free text) after the user
/// accepts them for this home.
class EnrichmentNote {
  const EnrichmentNote({
    required this.id,
    required this.key,
    required this.body,
    required this.createdAt,
    this.applianceId,
    this.sessionId,
    this.source = EnrichmentSource.household,
    this.pending = false,
  });

  final String id;

  /// Stable cache key: appliance/model/symptom hash.
  final String key;
  final String body;
  final DateTime createdAt;
  final String? applianceId;
  final String? sessionId;
  final EnrichmentSource source;

  /// True until the household accepts the note for this home.
  final bool pending;

  EnrichmentNote copyWith({bool? pending, String? body}) {
    return EnrichmentNote(
      id: id,
      key: key,
      body: body ?? this.body,
      createdAt: createdAt,
      applianceId: applianceId,
      sessionId: sessionId,
      source: source,
      pending: pending ?? this.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'source': source.name,
      'pending': pending,
      if (applianceId != null) 'applianceId': applianceId,
      if (sessionId != null) 'sessionId': sessionId,
    };
  }

  factory EnrichmentNote.fromJson(Map<String, dynamic> json) {
    return EnrichmentNote(
      id: json['id'] as String,
      key: json['key'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      applianceId: json['applianceId'] as String?,
      sessionId: json['sessionId'] as String?,
      source: enrichmentSourceFromName(json['source'] as String?),
      pending: json['pending'] as bool? ?? false,
    );
  }
}

enum EnrichmentSource { household, stubProvider, llm }

EnrichmentSource enrichmentSourceFromName(String? raw) {
  for (final value in EnrichmentSource.values) {
    if (value.name == raw) {
      return value;
    }
  }
  return EnrichmentSource.household;
}

/// Gap the Butler may optionally research once. Never a live diagnosis.
class EnrichmentRequest {
  const EnrichmentRequest({
    required this.key,
    required this.freeText,
    this.applianceId,
    this.modelNumber,
    this.symptomIds = const [],
  });

  final String key;
  final String freeText;
  final String? applianceId;
  final String? modelNumber;
  final List<String> symptomIds;
}

/// Hash for cache lookup. Same appliance + model + normalized text → same key.
String enrichmentCacheKey({
  String? applianceId,
  String? modelNumber,
  String? symptomText,
}) {
  final appliance = (applianceId ?? '').trim().toLowerCase();
  final model = (modelNumber ?? '').trim().toLowerCase();
  final text = (symptomText ?? '').trim().toLowerCase().replaceAll(
    RegExp(r'\s+'),
    ' ',
  );
  return 'enr:$appliance|$model|$text';
}
