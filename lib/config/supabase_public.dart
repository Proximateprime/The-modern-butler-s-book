/// Public Supabase project URL and anon/publishable key.
///
/// These are OK to ship in the app. They are not secrets.
/// `GROQ_API_KEY` must never appear here or in `--dart-define` for Play,
/// CI, Pages, or GitHub APK artifacts.
///
/// Empty compile defaults. Hosted tester CI (publish-testers.yml) passes
/// `--dart-define=SUPABASE_URL` and `--dart-define=SUPABASE_ANON_KEY` only.
/// Never dart-define GROQ or service_role.
const String kBundledSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '',
);

/// Legacy anon JWT or new publishable key. Never a service_role key.
const String kBundledSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
);

const String kPhraseFunctionName = 'phrase';

/// Full Edge Function URL, or null when Supabase is unset.
String? phraseFunctionUrlFromSupabase(String? supabaseUrl) {
  final url = supabaseUrl?.trim() ?? '';
  if (url.isEmpty) {
    return null;
  }
  final trimmed = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  return '$trimmed/functions/v1/$kPhraseFunctionName';
}

bool supabasePhrasingBackendConfigured({
  String? supabaseUrl,
  String? anonKey,
}) {
  final url = (supabaseUrl ?? kBundledSupabaseUrl).trim();
  final key = (anonKey ?? kBundledSupabaseAnonKey).trim();
  return url.isNotEmpty && key.isNotEmpty;
}
