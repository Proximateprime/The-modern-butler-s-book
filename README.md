# The Modern Butler’s Book

Local-first household repair guidance. Diagnosis is deterministic and stays on this device.

## Feature freeze

**2026-08-17 — bugfixes only.** See [`docs/FEATURE_FREEZE.md`](docs/FEATURE_FREEZE.md).

Agents: start at [`CURSOR_BOOTSTRAP.md`](CURSOR_BOOTSTRAP.md).

## Run

```
flutter test test/regression_binder_v1_test.dart
flutter test
flutter run
```

Run the binder before release. See [`docs/FEATURE_FREEZE.md`](docs/FEATURE_FREEZE.md).

Hosted testers (0.1.4+2; public Supabase URL + anon only — CI never dart-defines Groq):

- Flutter web (phone browser; no rating-plate scan): https://proximateprime.github.io/The-modern-butler-s-book/
- Sideload APK (full tester on a real phone): https://github.com/Proximateprime/The-modern-butler-s-book/releases/download/v0.1.4+2/modern-butlers-book-0.1.4+2.apk

Play Store listing is out. This tree is **0.1.4+2** hosted-tester Groq wiring — no App Bundle upload and no Console listing.

## Groq phrasing (Play-ready)

Nicer wording can come from Groq (`llama-3.1-8b-instant`) behind the butler
`phrase` Edge Function. The engine still decides. Packaged copy paints first.

**The Groq key must not live in the APK.** Set `GROQ_API_KEY` in the Supabase
dashboard (**Project Settings → Edge Functions → Secrets**). Do not paste the
key in git, PRs, or chat.

- Anon/publishable Supabase keys may ship in the app.
- Local `--dart-define=GROQ_API_KEY` is for Mark’s machine only.
- Hosted Pages and the GitHub APK dart-define public `SUPABASE_URL` +
  `SUPABASE_ANON_KEY` only. They must not pass `GROQ_API_KEY`.
- Missing function / timeout / 4xx / 5xx / leak / safety-gate fail → packaged copy.
- Some on-screen wording may be sent to Groq through the butler backend.
  Household records stay on this device. A language model never decides what
  is wrong.

See [`docs/qa/PLAY_READY_GROQ.md`](docs/qa/PLAY_READY_GROQ.md).

## Play signing later (not now)

`applicationId` stays `com.example.modern_butlers_book`. `versionCode` follows
`pubspec.yaml` (`0.1.4+2`).

When a store AAB is wanted later:

1. Create an upload keystore **off git**.
2. Copy [`android/key.properties.example`](android/key.properties.example) to
   `android/key.properties` and point `storeFile` at that keystore.
3. `*.jks`, `*.keystore`, and `key.properties` are gitignored. Do not commit them.
4. Do not run `flutter build appbundle` into Play from this pack.

CI tester APKs stay debug-signed when `key.properties` is absent.
