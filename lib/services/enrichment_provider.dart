import '../models/enrichment_note.dart';

/// Optional one-shot research. Must never be the diagnostic authority.
abstract class EnrichmentProvider {
  Future<List<String>> research(EnrichmentRequest request);
}

/// Offline / default: no network, no invented procedures.
class StubEnrichmentProvider implements EnrichmentProvider {
  const StubEnrichmentProvider();

  @override
  Future<List<String>> research(EnrichmentRequest request) async {
    return const [];
  }
}

/// Runtime enrichment is authoring-adjacent storage, not live diagnosis.
/// Keep false unless a real provider is wired and reviewed.
/// [StubEnrichmentProvider] stays the default. [EnrichmentSource.llm] is not
/// diagnosis.
const bool kRuntimeEnrichmentCallsEnabled = false;
