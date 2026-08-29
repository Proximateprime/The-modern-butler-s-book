import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_public.dart';

/// Initializes the public Supabase client when URL + anon/publishable are set.
///
/// Never reads or stores `GROQ_API_KEY`. Never uses service_role.
Future<bool> ensureButlerSupabase() async {
  if (!supabasePhrasingBackendConfigured()) {
    return false;
  }
  try {
    // Throws when initialize() has not run. Never reads GROQ_API_KEY.
    if (Supabase.instance.client.supabaseUrl.isNotEmpty) {
      return true;
    }
  } catch (_) {
    // Not initialized yet.
  }
  await Supabase.initialize(
    url: kBundledSupabaseUrl.trim(),
    anonKey: kBundledSupabaseAnonKey.trim(),
  );
  return true;
}
