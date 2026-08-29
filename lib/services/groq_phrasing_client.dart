import 'dart:async';
import 'dart:convert';

import '../config/supabase_public.dart';
import '../helpers/phrasing_request.dart';
import 'phrase_http.dart';

/// OpenAI-compatible / Edge Function phrasing client. Communication only.
///
/// Prefer the Supabase `phrase` Edge Function when URL + anon/publishable
/// are configured. Local `--dart-define=GROQ_API_KEY` is Mark's machine
/// only — never Play, CI, Pages, or GitHub APK.
///
/// Missing function URL / timeout / 4xx / 5xx → null (packaged).
/// The service still runs [acceptGroqPhrasing] before paint.
abstract class GroqPhrasingClient {
  /// True when a function URL or local-only Groq key is present.
  bool get hasApiKey;

  /// One completion. Null = caller keeps packaged. Never streams.
  Future<GroqPhrasingJson?> complete(GroqPhrasingRequest request);
}

/// HTTP status + body from the Edge Function. Tests inject this.
class PhraseFunctionHttpResponse {
  const PhraseFunctionHttpResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;
}

typedef PhraseFunctionPost = Future<PhraseFunctionHttpResponse> Function(
  Uri uri,
  Map<String, String> headers,
  String body,
);

typedef GroqLocalHttpPost = Future<String> Function(
  Uri uri,
  Map<String, String> headers,
  String body,
);

/// Production composer: Edge Function first, then local Groq key, else none.
class GroqPhrasingRuntimeClient implements GroqPhrasingClient {
  GroqPhrasingRuntimeClient({
    SupabasePhraseFunctionClient? edge,
    GroqOpenAiPhrasingClient? local,
  })  : edge = edge ?? SupabasePhraseFunctionClient.fromEnvironment(),
        local = local ?? GroqOpenAiPhrasingClient();

  final SupabasePhraseFunctionClient edge;
  final GroqOpenAiPhrasingClient local;

  bool get prefersEdgeFunction => edge.isConfigured;

  @override
  bool get hasApiKey => edge.isConfigured || local.hasApiKey;

  @override
  Future<GroqPhrasingJson?> complete(GroqPhrasingRequest request) {
    if (edge.isConfigured) {
      return edge.complete(request);
    }
    return local.complete(request);
  }
}

/// POST `{supabaseUrl}/functions/v1/phrase` with the anon/publishable client.
///
/// Never sends `GROQ_API_KEY`. Never uses service_role.
class SupabasePhraseFunctionClient implements GroqPhrasingClient {
  SupabasePhraseFunctionClient({
    this.functionUrl,
    this.anonKey,
    this.httpPost,
    this.timeout = const Duration(milliseconds: 2500),
  });

  factory SupabasePhraseFunctionClient.fromEnvironment() {
    return SupabasePhraseFunctionClient(
      functionUrl: phraseFunctionUrlFromSupabase(kBundledSupabaseUrl),
      anonKey: kBundledSupabaseAnonKey,
    );
  }

  final String? functionUrl;
  final String? anonKey;
  final Duration timeout;
  final PhraseFunctionPost? httpPost;

  bool get isConfigured {
    final url = functionUrl?.trim() ?? '';
    final key = anonKey?.trim() ?? '';
    return url.isNotEmpty && key.isNotEmpty;
  }

  @override
  bool get hasApiKey => isConfigured;

  @override
  Future<GroqPhrasingJson?> complete(GroqPhrasingRequest request) async {
    if (!isConfigured) {
      return null;
    }
    try {
      final payload = jsonEncode(request.toModelJson());
      final response = await (httpPost ?? _defaultHttpPost)(
        Uri.parse(functionUrl!.trim()),
        {
          'Authorization': 'Bearer ${anonKey!.trim()}',
          'apikey': anonKey!.trim(),
          'Content-Type': 'application/json',
        },
        payload,
      ).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      if (_responseLeaksSecret(response)) {
        return null;
      }
      return parseGroqPhrasingJson(response.body);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<PhraseFunctionHttpResponse> _defaultHttpPost(
    Uri uri,
    Map<String, String> headers,
    String body,
  ) async {
    final result = await defaultPhraseHttpPost(uri, headers, body);
    return PhraseFunctionHttpResponse(
      statusCode: result.statusCode,
      body: result.body,
      headers: result.headers,
    );
  }
}

/// Live Groq POST. Local-only fallback. Tests inject [httpPost].
///
/// Play / CI / Pages / GitHub APK must not pass `--dart-define=GROQ_API_KEY`.
class GroqOpenAiPhrasingClient implements GroqPhrasingClient {
  GroqOpenAiPhrasingClient({
    this.apiKey = const String.fromEnvironment('GROQ_API_KEY'),
    this.httpPost,
    this.timeout = const Duration(milliseconds: 2500),
    this.now,
  });

  final String apiKey;
  final Duration timeout;
  final DateTime Function()? now;

  /// Injected HTTP. Default uses package:http (web-safe). Tests stub — no live net.
  final GroqLocalHttpPost? httpPost;

  @override
  bool get hasApiKey => groqPhrasingHasApiKey(apiKey);

  @override
  Future<GroqPhrasingJson?> complete(GroqPhrasingRequest request) async {
    if (!hasApiKey) {
      return null;
    }
    try {
      final payload = jsonEncode({
        'model': kGroqPhrasingModel,
        'temperature': 0.2,
        'max_tokens': 220,
        'stream': false,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': groqPhrasingSystemPrompt()},
          {'role': 'user', 'content': jsonEncode(request.toModelJson())},
        ],
      });
      final raw = await (httpPost ?? _defaultHttpPost)(
        Uri.parse(kGroqChatCompletionsUrl),
        {
          'Authorization': 'Bearer ${apiKey.trim()}',
          'Content-Type': 'application/json',
        },
        payload,
      ).timeout(timeout);
      return parseGroqPhrasingJson(_contentFromChatCompletion(raw));
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String> _defaultHttpPost(
    Uri uri,
    Map<String, String> headers,
    String body,
  ) async {
    final result = await defaultPhraseHttpPost(uri, headers, body);
    return result.body;
  }
}

/// Default install / tests: no key, no function URL, no network, packaged copy.
class MissingKeyGroqPhrasingClient implements GroqPhrasingClient {
  const MissingKeyGroqPhrasingClient();

  @override
  bool get hasApiKey => false;

  @override
  Future<GroqPhrasingJson?> complete(GroqPhrasingRequest request) async {
    return null;
  }
}

/// In-memory test double for local Groq. Never opens a socket.
class FakeGroqPhrasingClient implements GroqPhrasingClient {
  FakeGroqPhrasingClient({
    this.hasApiKey = true,
    this.response,
    this.handler,
    this.throwTimeout = false,
  });

  @override
  bool hasApiKey;

  GroqPhrasingJson? response;
  GroqPhrasingJson? Function(GroqPhrasingRequest request)? handler;
  bool throwTimeout;

  final List<GroqPhrasingRequest> requests = [];
  int completeCalls = 0;

  /// Always zero — this client never performs live I/O.
  int get liveNetworkCalls => 0;

  @override
  Future<GroqPhrasingJson?> complete(GroqPhrasingRequest request) async {
    requests.add(request);
    completeCalls += 1;
    if (throwTimeout) {
      throw TimeoutException('groq-timeout');
    }
    if (handler != null) {
      return handler!(request);
    }
    return response;
  }
}

/// In-memory Edge Function double. Never opens a socket. Never holds a Groq key.
class FakePhraseFunctionClient implements GroqPhrasingClient {
  FakePhraseFunctionClient({
    this.hasFunctionUrl = true,
    this.statusCode = 200,
    this.response,
    this.rawBody,
    this.responseHeaders = const {},
    this.throwTimeout = false,
    this.handler,
  });

  bool hasFunctionUrl;
  int statusCode;
  GroqPhrasingJson? response;
  String? rawBody;
  Map<String, String> responseHeaders;
  bool throwTimeout;
  GroqPhrasingJson? Function(GroqPhrasingRequest request)? handler;

  final List<GroqPhrasingRequest> requests = [];
  int completeCalls = 0;

  /// Always zero — this client never performs live I/O.
  int get liveNetworkCalls => 0;

  @override
  bool get hasApiKey => hasFunctionUrl;

  @override
  Future<GroqPhrasingJson?> complete(GroqPhrasingRequest request) async {
    requests.add(request);
    completeCalls += 1;
    if (!hasFunctionUrl) {
      return null;
    }
    if (throwTimeout) {
      throw TimeoutException('phrase-function-timeout');
    }
    if (statusCode < 200 || statusCode >= 300) {
      return null;
    }
    if (rawBody != null) {
      if (_bodyLeaksSecret(rawBody!)) {
        return null;
      }
      return parseGroqPhrasingJson(rawBody);
    }
    if (handler != null) {
      return handler!(request);
    }
    return response;
  }
}

bool _responseLeaksSecret(PhraseFunctionHttpResponse response) {
  if (_bodyLeaksSecret(response.body)) {
    return true;
  }
  for (final entry in response.headers.entries) {
    if (_bodyLeaksSecret('${entry.key}: ${entry.value}')) {
      return true;
    }
  }
  return false;
}

bool _bodyLeaksSecret(String text) {
  if (RegExp(r'gsk_[A-Za-z0-9]{8,}').hasMatch(text)) {
    return true;
  }
  final lower = text.toLowerCase();
  if (lower.contains('service_role') &&
      RegExp(r'service_role["\s:=]+eyJ').hasMatch(lower)) {
    return true;
  }
  return false;
}

String? _contentFromChatCompletion(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return raw;
    }
    final choices = decoded['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final message = first['message'];
        if (message is Map) {
          final content = message['content']?.toString();
          if (content != null && content.trim().isNotEmpty) {
            return content;
          }
        }
      }
    }
    return raw;
  } catch (_) {
    return raw;
  }
}
