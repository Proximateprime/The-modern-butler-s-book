# Play-ready Groq via Supabase Edge Function (not a Store listing)

App **0.1.4+1**. Play Console listing and store upload stay **OUT**. This pack
does not reopen leftover 1–12 / +5…+9. `GOLDEN_LABELS` **Call a pro** stays
frozen. Voice-as-required stays locked.

Groq still changes how we talk, not what we conclude. Same seven ON hooks,
JSON-only `title` / `why_one_line` / `option_labels_only`, same ids, one call
per screen, prefetch already-chosen next template id only.

## Hard gates (Auditor John)

- Client still runs `phrasing_safety_gate` / `visibleHouseholdHowTo` **before
  paint**. The Edge Function is not an escape hatch and is not a diagnosis
  engine. Painting Groq JSON without the existing safety gate is a REJECT.
- Edge Function secret is server-only; never returned in JSON, headers, or logs.
- Missing function URL / timeout / 4xx / 5xx / validator fail → packaged copy.
- REJECT if a Groq key or Play keystore lands in git.
- Anon/publishable Supabase key is OK in the app.
- Local `--dart-define=GROQ_API_KEY` is Mark’s machine only — not CI, Pages,
  GitHub APK, or Play artifacts.
- Play Console listing / store upload still OUT.

## Where the Groq key lives

Set `GROQ_API_KEY` in the **Supabase dashboard**, not in chat and not in a PR:

1. Open the project at [https://supabase.com/dashboard](https://supabase.com/dashboard).
2. **Project Settings → Edge Functions → Secrets**.
3. Add `GROQ_API_KEY`. Do not paste the value into git, PRs, or agent chat.

The Flutter app never sees that secret. Hosted testers stay packaged until the
function URL + anon/publishable client are configured.

## Tests

Fake function + fake Groq. Zero live Groq calls. Fixtures must not contain a
Groq key.
