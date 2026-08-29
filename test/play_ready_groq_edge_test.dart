import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:modern_butlers_book/config/supabase_public.dart';
import 'package:modern_butlers_book/helpers/groq_phrasing.dart';
import 'package:modern_butlers_book/helpers/phrasing_safety_gate.dart';
import 'package:modern_butlers_book/helpers/why_ask_this.dart';
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

void main() {
  test('missing function URL stays packaged and never posts', () async {
    var posts = 0;
    final edge = SupabasePhraseFunctionClient(
      functionUrl: '',
      anonKey: 'sb_publishable_test_anon_not_a_secret',
      httpPost: (uri, headers, body) async {
        posts += 1;
        return const PhraseFunctionHttpResponse(statusCode: 200, body: '{}');
      },
    );
    expect(edge.isConfigured, isFalse);
    expect(edge.hasApiKey, isFalse);
    expect(await edge.complete(_questionRequest()), isNull);
    expect(posts, 0);

    final missing = FakePhraseFunctionClient(hasFunctionUrl: false);
    final service = GroqPhrasingService(client: missing);
    expect(service.shouldCallNetwork, isFalse);
    final accepted = await service.phrase(_questionRequest());
    expect(accepted.fromGroq, isFalse);
    expect(accepted.title, 'Did the dryer blow warm air?');
    expect(missing.completeCalls, 0);
    expect(missing.liveNetworkCalls, 0);
  });

  test('function timeout 4xx and 5xx fall back to packaged', () async {
    final timeoutClient = FakePhraseFunctionClient(throwTimeout: true);
    final timedOut = await GroqPhrasingService(client: timeoutClient)
        .phrase(_questionRequest());
    expect(timedOut.fromGroq, isFalse);
    expect(timedOut.title, 'Did the dryer blow warm air?');

    for (final code in [400, 401, 404, 429, 500, 502, 503]) {
      final client = FakePhraseFunctionClient(
        statusCode: code,
        response: const GroqPhrasingJson(title: 'should not paint'),
      );
      final accepted =
          await GroqPhrasingService(client: client).phrase(_questionRequest());
      expect(accepted.fromGroq, isFalse, reason: 'status $code');
      expect(accepted.title, 'Did the dryer blow warm air?');
      expect(client.liveNetworkCalls, 0);
    }
  });

  test('function JSON still runs safety gate before paint', () async {
    final banned = FakePhraseFunctionClient(
      response: const GroqPhrasingJson(
        title: 'Check the gas_train next',
        whyOneLine: 'A look, not a diagnosis.',
      ),
    );
    final rejected =
        await GroqPhrasingService(client: banned).phrase(_questionRequest());
    expect(rejected.fromGroq, isFalse);
    expect(rejected.title, 'Did the dryer blow warm air?');
    expect(
      acceptGroqPhrasing(
        request: _questionRequest(),
        parsed: const GroqPhrasingJson(title: 'Check the gas_train next'),
      ),
      isNull,
    );

    final ok = FakePhraseFunctionClient(
      response: const GroqPhrasingJson(
        title: 'Any warmth from the clothes?',
        whyOneLine: 'Warm air versus cold air splits vent from heater.',
      ),
    );
    final swapped =
        await GroqPhrasingService(client: ok).phrase(_questionRequest());
    expect(swapped.fromGroq, isTrue);
    expect(swapped.title, 'Any warmth from the clothes?');
    expect(ok.liveNetworkCalls, 0);

    final unsafeHowTo = FakePhraseFunctionClient(
      response: const GroqPhrasingJson(
        title: 'Bypass the thermal fuse with a jumper.',
        whyOneLine: 'This splits heat from airflow.',
      ),
    );
    final blocked = await GroqPhrasingService(client: unsafeHowTo)
        .phrase(_questionRequest());
    expect(blocked.fromGroq, isFalse);
    expect(
      groqStringPassesSafetyGate(
        'Bypass the thermal fuse with a jumper.',
        requireOfficialStop: false,
      ),
      isFalse,
    );
  });

  test('runtime client prefers configured function over local Groq key',
      () async {
    var groqPosts = 0;
    final edge = SupabasePhraseFunctionClient(
      functionUrl: 'https://example.supabase.co/functions/v1/phrase',
      anonKey: 'sb_publishable_test_anon_not_a_secret',
      httpPost: (uri, headers, body) async {
        expect(uri.path, endsWith('/phrase'));
        expect(headers['Authorization'], startsWith('Bearer '));
        expect(headers['Authorization'], isNot(contains('gsk_')));
        expect(body, isNot(contains('GROQ_API_KEY')));
        expect(body, isNot(contains('gsk_')));
        return const PhraseFunctionHttpResponse(
          statusCode: 200,
          body:
              '{"title":"Any warmth from the drum?","why_one_line":"Warmth versus none splits airflow from no heat."}',
        );
      },
    );
    final local = GroqOpenAiPhrasingClient(
      apiKey: 'local-only-placeholder-not-a-real-key',
      httpPost: (uri, headers, body) async {
        groqPosts += 1;
        return '{}';
      },
    );
    final runtime = GroqPhrasingRuntimeClient(edge: edge, local: local);
    expect(runtime.prefersEdgeFunction, isTrue);
    expect(runtime.hasApiKey, isTrue);
    final parsed = await runtime.complete(_questionRequest());
    expect(parsed?.title, 'Any warmth from the drum?');
    expect(groqPosts, 0);
  });

  test('local Groq fallback is unused when function URL is missing', () async {
    final edge = SupabasePhraseFunctionClient(
      functionUrl: null,
      anonKey: '',
    );
    var groqPosts = 0;
    final local = GroqOpenAiPhrasingClient(
      apiKey: 'local-only-placeholder-not-a-real-key',
      httpPost: (uri, headers, body) async {
        groqPosts += 1;
        return '{"title":"Local machine line","why_one_line":"Warmth versus none splits heat from airflow."}';
      },
    );
    final runtime = GroqPhrasingRuntimeClient(edge: edge, local: local);
    expect(runtime.prefersEdgeFunction, isFalse);
    expect(runtime.hasApiKey, isTrue);
    final parsed = await runtime.complete(_questionRequest());
    expect(parsed?.title, 'Local machine line');
    expect(groqPosts, 1);
  });

  test('function response that leaks a Groq-shaped secret is dropped', () async {
    final shaped = 'gsk_${List.filled(24, 'x').join()}';
    final leak = FakePhraseFunctionClient(
      rawBody: '{"title":"Warmth?","why_one_line":"$shaped"}',
    );
    final accepted =
        await GroqPhrasingService(client: leak).phrase(_questionRequest());
    expect(accepted.fromGroq, isFalse);
    expect(accepted.title, 'Did the dryer blow warm air?');
  });

  test('phrase function source never embeds or logs the Groq secret', () {
    final src = File('supabase/functions/phrase/index.ts').readAsStringSync();
    expect(src, contains("Deno.env.get('GROQ_API_KEY')"));
    expect(src, contains('llama-3.1-8b-instant'));
    expect(src, contains("'service_role'"));
    expect(src, isNot(contains('SUPABASE_SERVICE_ROLE')));
    expect(src, isNot(contains('createClient')));
    expect(src, isNot(contains(RegExp(r'gsk_[A-Za-z0-9]{8,}'))));
    expect(src, isNot(contains('console.log(groqKey)')));
    expect(src, isNot(contains('console.log(GROQ')));
    expect(src, contains('Never return it'));
    expect(kPhraseFunctionName, 'phrase');
    expect(
      phraseFunctionUrlFromSupabase('https://example.supabase.co'),
      'https://example.supabase.co/functions/v1/phrase',
    );
    expect(phraseFunctionUrlFromSupabase(''), isNull);
    expect(supabasePhrasingBackendConfigured(supabaseUrl: '', anonKey: 'x'), isFalse);
  });

  test('fixture tree does not contain a Groq key or Play keystore', () {
    final tracked = Process.runSync('git', ['ls-files']);
    expect(tracked.exitCode, 0);
    final files = tracked.stdout.toString().split('\n').where((line) {
      return line.trim().isNotEmpty;
    });
    final bannedName = RegExp(r'\.(jks|keystore)$');
    for (final path in files) {
      expect(bannedName.hasMatch(path), isFalse, reason: path);
      expect(
        path == 'key.properties' || path == 'android/key.properties',
        isFalse,
        reason: path,
      );
    }
    const fixtures = [
      'test/play_ready_groq_edge_test.dart',
      'test/george_ui_groq_phrasing_test.dart',
      'supabase/functions/phrase/index.ts',
    ];
    for (final path in fixtures) {
      final text = File(path).readAsStringSync();
      expect(text, isNot(contains(RegExp(r'gsk_[A-Za-z0-9]{20,}'))));
      expect(text.contains('GROQ_API_KEY=' 'gsk_'), isFalse);
    }
  });
}
