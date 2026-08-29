import 'package:http/http.dart' as http;

/// Shared POST used by web and Android. Never imports dart:io.
///
/// Pages must be able to POST `/functions/v1/phrase` from Flutter web.
class PhraseHttpResult {
  const PhraseHttpResult({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;
}

Future<PhraseHttpResult> defaultPhraseHttpPost(
  Uri uri,
  Map<String, String> headers,
  String body,
) async {
  final client = http.Client();
  try {
    final response = await client.post(
      uri,
      headers: headers,
      body: body,
    );
    return PhraseHttpResult(
      statusCode: response.statusCode,
      body: response.body,
      headers: Map<String, String>.from(response.headers),
    );
  } finally {
    client.close();
  }
}
