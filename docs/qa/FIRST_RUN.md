# First-run greeting

Three short pages. **Skip** or a tap on the last page both finish it for good. Legal **Safety disclaimer** is a separate screen after this — **Skip** never bypasses **I understand**. There is no “1 of 3” page-counter chrome and no bottom Continue button.

Read from code on **2026-09-04**. Tests: `test/first_run_tap_v1_test.dart`, `test/first_run_empty_states_test.dart`, `test/natural_ui_v1_test.dart`, `test/session_scroll_skip_test.dart`. Flag: `modern_butler_first_run_complete_v1`.

---

## Pages

| Page | Title | Point |
|---|---|---|
| 1 | Greeting + **What Butler does** | Observe → guide safe checks → remember House Book |
| 2 | **What it doesn’t do** | No gas / live electrical / sealed cooling DIY. **The camera never diagnoses.** |
| 3 | **Your household stays here** | Names, appliances, photos, tools, repair notes stay on this device. Diagnosis stays on this device. Groq / backend disclosure lives in Settings, not here. |

The first page opens with **Welcome. A few words before we open the book.** Then the existing what-beat. A tap anywhere on the page body (not Skip) turns the page. Last-page tap finishes first-run (`first-run-done-button`). Advance keys stay `first-run-next-button` / `first-run-done-button`. Layout is SafeArea’d above the system home/back bar. No Transform.

---

## Tap path — once on a fresh install (DoD)

Uninstall the app or clear app storage so SharedPreferences is empty.

1. Launch. After splash: greeting + **What Butler does**. **Skip** is in the app bar (48px, first tap completes first-run).
2. Tap the page → **What it doesn’t do**. Tap → privacy. Tap again to finish first-run.
3. One-time **Safety disclaimer** → **I understand** (if not already acknowledged). Skip cannot skip this beat.
4. Home. Empty house: **Name this home**. Kill and reopen: onboarding does **not** return.

**Skip** on the first page also completes first-run; disclaimer still shows if needed. Returning users with the flag set go straight to Home (or disclaimer).
