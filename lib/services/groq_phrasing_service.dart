import '../helpers/groq_phrasing.dart';
import 'groq_phrasing_client.dart';

/// Phrasing overlay. Engine already decided — this only swaps wording.
///
/// Testers default ON with hard gates. One Groq call per screen change.
/// Prefetch is the already-chosen next template id only — not a branch cache.
class GroqPhrasingService {
  GroqPhrasingService({
    GroqPhrasingClient? client,
    this.enabled = kGroqPhrasingEnabledDefault,
  }) : client = client ?? GroqOpenAiPhrasingClient();

  final GroqPhrasingClient client;
  final bool enabled;

  final Map<String, GroqPhrasingAccepted> _cache = {};
  String? _lastScreenKey;
  final List<String> _requestedEvidenceIds = [];

  /// True only when a live client would POST. Missing key never networks.
  bool get shouldCallNetwork => enabled && client.hasApiKey;

  List<String> get requestedEvidenceIds =>
      List<String>.unmodifiable(_requestedEvidenceIds);

  int get liveNetworkCalls {
    final fake = client;
    if (fake is FakeGroqPhrasingClient) {
      return fake.liveNetworkCalls;
    }
    return 0;
  }

  void resetForTests() {
    _cache.clear();
    _lastScreenKey = null;
    _requestedEvidenceIds.clear();
  }

  /// Packaged first. Groq swap only when the validator accepts.
  Future<GroqPhrasingAccepted> phrase(GroqPhrasingRequest request) async {
    final packaged = GroqPhrasingAccepted.packaged(request);
    if (!enabled || !client.hasApiKey) {
      return packaged;
    }
    final cached = _cache[request.screenKey];
    if (cached != null && _lastScreenKey == request.screenKey) {
      return cached;
    }
    if (_lastScreenKey != null &&
        _lastScreenKey != request.screenKey &&
        request.prefetchOnly) {
      // Prefetch is allowed in addition to the current screen's one call.
    } else if (_lastScreenKey == request.screenKey && cached != null) {
      return cached;
    }

    if (!request.prefetchOnly) {
      _lastScreenKey = request.screenKey;
    }
    _requestedEvidenceIds.add(request.evidenceNeeded);

    GroqPhrasingJson? parsed;
    try {
      parsed = await client.complete(request);
    } catch (_) {
      return packaged;
    }
    final accepted = acceptGroqPhrasing(request: request, parsed: parsed);
    final result = accepted ?? packaged;
    _cache[request.screenKey] = result;
    return result;
  }

  /// Wording for the already-chosen next template id only.
  Future<GroqPhrasingAccepted> prefetchAlreadyChosenNext(
    GroqPhrasingRequest request,
  ) {
    return phrase(request.copyWith(prefetchOnly: true));
  }
}
