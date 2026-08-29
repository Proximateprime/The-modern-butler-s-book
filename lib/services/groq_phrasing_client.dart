import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../helpers/groq_phrasing.dart';

/// OpenAI-compatible Groq chat client. Communication only.
///
/// Key from `--dart-define=GROQ_API_KEY` / [String.fromEnvironment].
/// Missing key is a required path (packaged copy). Never persist a key.
abstract class GroqPhrasingClient {
  bool get hasApiKey;

  /// One completion. Null = caller keeps packaged. Never streams.
  Future<GroqPhrasingJson?> complete(GroqPhrasingRequest request);
}

/// Live Groq POST. Tests must inject [httpPost] or use [FakeGroqPhrasingClient].
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

  /// Injected HTTP. Default uses [HttpClient]. Tests pass a stub — no live net.
  final Future<String> Function(
    Uri uri,
    Map<String, String> headers,
    String body,
  )? httpPost;

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
    final client = HttpClient();
    try {
      final httpRequest = await client.postUrl(uri).timeout(timeout);
      headers.forEach(httpRequest.headers.set);
      httpRequest.add(utf8.encode(body));
      final response = await httpRequest.close().timeout(timeout);
      return await utf8.decodeStream(response).timeout(timeout);
    } finally {
      client.close(force: true);
    }
  }
}

/// Default install / tests: no key, no network, packaged copy.
class MissingKeyGroqPhrasingClient implements GroqPhrasingClient {
  const MissingKeyGroqPhrasingClient();

  @override
  bool get hasApiKey => false;

  @override
  Future<GroqPhrasingJson?> complete(GroqPhrasingRequest request) async {
    return null;
  }
}

/// In-memory test double. Never opens a socket.
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
