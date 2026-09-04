import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/app_info.dart';
import 'package:modern_butlers_book/helpers/phrasing_request.dart';
import 'package:modern_butlers_book/helpers/phrasing_safety_gate.dart';
import 'package:modern_butlers_book/helpers/user_facing_error.dart';
import 'package:modern_butlers_book/helpers/why_ask_this.dart';
import 'package:modern_butlers_book/services/butler_supabase.dart';
import 'package:modern_butlers_book/services/groq_phrasing_client.dart';
import 'package:modern_butlers_book/services/groq_phrasing_service.dart';

GroqPhrasingRequest _questionRequest() {
  return GroqPhrasingRequest(
    hook: GroqPhrasingHook.questionCard,
    family: 'dryer',
    energy: 'electric',
    state: 'evidence',
    comfort: 'normal',
    evidenceNeeded: 'heat-observed',
    options: const ['Yes', 'No', 'Not sure'],
    lastObs: 'no-heat: clothes stay damp',
    whyEngine: whyAskAuthoredByTemplateId['heat-observed']!,
    safety: 'none',
    packagedTitle: 'Did the dryer blow warm air?',
    packagedWhyOneLine: whyAskAuthoredByTemplateId['heat-observed']!,
    packagedOptionLabels: const {
      'Yes': 'Yes',
      'No': 'No',
      'Not sure': 'Not sure',
    },
  );
}

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('version is 0.1.4+13', () {
    expect(kAppVersion, '0.1.4');
    expect(kAppVersionLabel, '0.1.4+13');
    expect(_read('pubspec.yaml'), contains('version: 0.1.4+13'));
  });

  test('web phrasing client does not import dart:io', () {
    const webSafe = [
      'lib/services/groq_phrasing_client.dart',
      'lib/services/phrase_http.dart',
      'lib/services/phrase_http_browser.dart',
      'lib/services/phrase_http_common.dart',
      'lib/services/phrase_http_stub.dart',
      'lib/config/supabase_public.dart',
      'lib/services/butler_supabase.dart',
      'lib/main.dart',
    ];
    for (final path in webSafe) {
      final src = _read(path);
      expect(src, isNot(contains("import 'dart:io'")), reason: path);
      expect(src, isNot(contains('HttpClient()')), reason: path);
      expect(src, isNot(contains(RegExp(r'gsk_[A-Za-z0-9]{20,}'))), reason: path);
    }
    final barrel = _read('lib/services/phrase_http.dart');
    expect(barrel, contains('if (dart.library.html)'));
    expect(barrel, contains('if (dart.library.io)'));
    expect(barrel, contains('phrase_http_browser.dart'));
    final client = _read('lib/services/groq_phrasing_client.dart');
    expect(client, contains("import 'phrase_http.dart'"));
    expect(client, contains('defaultPhraseHttpPost'));
    expect(client, contains('/functions/v1/phrase'));
    expect(
      _read('lib/services/phrase_http_common.dart'),
      contains("package:http/http.dart"),
    );
  });

  test('hosted tester workflow dart-defines public URL + anon only', () {
    final yml = _read('.github/workflows/publish-testers.yml');
    expect(yml, contains('--dart-define=SUPABASE_URL='));
    expect(yml, contains('--dart-define=SUPABASE_ANON_KEY='));
    expect(
      yml,
      contains('https://zfwmrqnywhspgzqmkokn.supabase.co'),
    );
    expect(yml, contains('cm9sZSI6ImFub24i'));
    expect(yml, isNot(contains('--dart-define=GROQ')));
    expect(yml, isNot(contains('--dart-define=GROQ_API_KEY')));
    expect(yml, isNot(contains(RegExp(r'gsk_[A-Za-z0-9]{8,}'))));
    expect(yml, isNot(contains('SUPABASE_SERVICE_ROLE')));
    expect(yml, isNot(contains('service_role')));
    expect(
      '--dart-define=SUPABASE_URL='.allMatches(yml).length,
      2,
      reason: 'web and APK must both dart-define SUPABASE_URL',
    );
    expect(
      '--dart-define=SUPABASE_ANON_KEY='.allMatches(yml).length,
      2,
      reason: 'web and APK must both dart-define SUPABASE_ANON_KEY',
    );
    expect(yml, contains('flutter build web'));
    expect(yml, contains('flutter build apk'));
  });

  test('assert script refuses GROQ dart-define and allows SUPABASE', () {
    final script = _read('tool/assert_packaged_tester_build.sh');
    expect(script, contains('GROQ_API_KEY'));
    expect(script, contains('SUPABASE_URL'));
    expect(script, contains('SUPABASE_ANON_KEY'));
    expect(script, contains('gsk_'));
    expect(script, contains('keystore'));
    expect(script, contains('SERVICE_ROLE'));
    expect(
      script,
      isNot(contains("dart-define=.?SUPABASE_URL")),
      reason: 'must not refuse SUPABASE_URL dart-defines',
    );
  });

  test('ensureButlerSupabase swallows failures and refuses secrets', () async {
    expect(await ensureButlerSupabase(), isFalse);

    final failed = await ensureButlerSupabase(
      url: 'https://example.supabase.co',
      anonKey: 'sb_publishable_test_anon_not_a_secret',
      initialize: (url, key) async {
        throw StateError('init-failed');
      },
    );
    expect(failed, isFalse);

    var called = 0;
    final ready = await ensureButlerSupabase(
      url: 'https://example.supabase.co',
      anonKey: 'sb_publishable_test_anon_not_a_secret',
      initialize: (url, key) async {
        called += 1;
        expect(url, 'https://example.supabase.co');
        expect(key, isNot(contains('gsk_')));
        expect(key.toLowerCase(), isNot(contains('service_role')));
      },
    );
    expect(ready, isTrue);
    expect(called, 1);

    var forbiddenCalls = 0;
    expect(
      await ensureButlerSupabase(
        url: 'https://example.supabase.co',
        anonKey: 'eyJ.service_role.should-never-ship',
        initialize: (url, key) async {
          forbiddenCalls += 1;
        },
      ),
      isFalse,
    );
    expect(forbiddenCalls, 0);

    final mainSrc = _read('lib/main.dart');
    expect(mainSrc, contains('try {'));
    expect(mainSrc, contains('await ensureButlerSupabase()'));
    expect(mainSrc, contains('runApp'));
  });

  test('seven ON hooks and safety gate still sit in front of paint', () async {
    expect(PhrasingSlot.values, hasLength(7));
    expect(
      PhrasingSlot.values.map((slot) => slot.name).toSet(),
      {
        'questionCard',
        'safetyStop',
        'proHandoff',
        'diagnosisSummary',
        'confirmNotFixed',
        'resume',
        'skillComfort',
      },
    );
    expect(kGoldenChromeFrozenLabels, contains('Call a pro'));
    expect(kGroqPhrasingEnabledDefault, isTrue);

    final leak = FakePhraseFunctionClient(
      rawBody:
          '{"title":"Warmth?","why_one_line":"gsk_${List.filled(24, 'x').join()}"}',
    );
    final leaked =
        await GroqPhrasingService(client: leak).phrase(_questionRequest());
    expect(leaked.fromGroq, isFalse);
    expect(leaked.title, 'Did the dryer blow warm air?');

    final banned = FakePhraseFunctionClient(
      response: const GroqPhrasingJson(
        title: 'Check the gas_train next',
        whyOneLine: 'A look, not a diagnosis.',
      ),
    );
    final rejected =
        await GroqPhrasingService(client: banned).phrase(_questionRequest());
    expect(rejected.fromGroq, isFalse);
    expect(
      acceptGroqPhrasing(
        request: _questionRequest(),
        parsed: const GroqPhrasingJson(title: 'Check the gas_train next'),
      ),
      isNull,
    );

    var posts = 0;
    final edge = SupabasePhraseFunctionClient(
      functionUrl: 'https://example.supabase.co/functions/v1/phrase',
      anonKey: 'sb_publishable_test_anon_not_a_secret',
      httpPost: (uri, headers, body) async {
        posts += 1;
        expect(uri.path, endsWith('/functions/v1/phrase'));
        expect(headers['Authorization'], startsWith('Bearer '));
        expect(headers['Authorization'], isNot(contains('gsk_')));
        expect(body, isNot(contains('GROQ_API_KEY')));
        expect(body, isNot(contains('service_role')));
        return const PhraseFunctionHttpResponse(
          statusCode: 503,
          body: '{"error":"unavailable"}',
        );
      },
    );
    expect(await edge.complete(_questionRequest()), isNull);
    expect(posts, 1);
  });

  test('settings still has no paste-a-key field', () {
    final settings = _read('lib/ui/settings_screen.dart');
    expect(settings, isNot(contains('GROQ_API_KEY')));
    expect(settings, isNot(contains('paste')));
    expect(settings.toLowerCase(), isNot(contains('api key')));
    expect(
      UserFacingCopy.privacyPhrasingBackend.toLowerCase(),
      isNot(contains('paste')),
    );
  });

  test('fixture tree does not embed Groq or service_role secrets', () {
    const shipped = [
      'lib/services/groq_phrasing_client.dart',
      'lib/services/phrase_http_common.dart',
      'lib/config/supabase_public.dart',
      '.github/workflows/publish-testers.yml',
    ];
    for (final path in shipped) {
      final text = _read(path);
      expect(text, isNot(contains(RegExp(r'gsk_[A-Za-z0-9]{20,}'))));
      expect(text.contains('GROQ_API_KEY=' 'gsk_'), isFalse);
    }
    final yml = _read('.github/workflows/publish-testers.yml');
    expect(yml, isNot(contains('SUPABASE_SERVICE_ROLE')));
    expect(yml, isNot(contains('--dart-define=GROQ')));
    expect(yml, contains('--dart-define=SUPABASE_URL='));
    expect(yml, contains('--dart-define=SUPABASE_ANON_KEY='));
  });
}
