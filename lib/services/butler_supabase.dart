import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_public.dart';

/// Initializes the public Supabase client when URL + anon/publishable are set.
///
/// Never reads or stores `GROQ_API_KEY`. Never uses service_role.
/// Failures are swallowed — the app still starts on packaged copy.
Future<bool> ensureButlerSupabase({
  String? url,
  String? anonKey,
  Future<void> Function(String url, String anonKey)? initialize,
}) async {
  try {
    final resolvedUrl = (url ?? kBundledSupabaseUrl).trim();
    final resolvedKey = (anonKey ?? kBundledSupabaseAnonKey).trim();
    if (resolvedUrl.isEmpty || resolvedKey.isEmpty) {
      return false;
    }
    if (_looksLikeForbiddenClientKey(resolvedKey)) {
      return false;
    }
    final init = initialize ?? _initializeSupabase;
    await init(resolvedUrl, resolvedKey);
    return true;
  } catch (_) {
    return false;
  }
}

bool _looksLikeForbiddenClientKey(String key) {
  if (RegExp(r'gsk_[A-Za-z0-9]{8,}').hasMatch(key)) {
    return true;
  }
  return key.toLowerCase().contains('service_role');
}

Future<void> _initializeSupabase(String url, String anonKey) async {
  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );
}
