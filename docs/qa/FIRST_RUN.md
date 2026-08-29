# First-run greeting

Three short pages. **Skip** or **Get started** both finish it for good. Legal **Safety disclaimer** is a separate screen after this. There is no “1 of 3” page-counter chrome.

Read from code on **2026-08-29**. Tests: `test/first_run_empty_states_test.dart`, `test/natural_ui_v1_test.dart`, `test/session_scroll_skip_test.dart`. Flag: `modern_butler_first_run_complete_v1`.

---

## Pages

| Page | Title | Point |
|---|---|---|
| 1 | Greeting + **What Butler does** | Observe → guide safe checks → remember House Book |
| 2 | **What it doesn’t do** | No gas / live electrical / sealed cooling DIY. **The camera never diagnoses.** |
| 3 | **Your household stays here** | Names, appliances, photos, tools, repair notes on this device. Not uploaded. |

The first page opens with **Welcome. A few words before we open the book.** Then the existing what-beat. **Continue** turns the page. Last page: **Get started**.

---

## Tap path — once on a fresh install (DoD)

Uninstall the app or clear app storage so SharedPreferences is empty.

1. Launch. After splash: greeting + **What Butler does**. **Skip** is in the app bar (48px, first tap completes first-run).
2. **Continue** → **What it doesn’t do**. **Continue** → privacy. **Get started**.
3. One-time **Safety disclaimer** → **I understand** (if not already acknowledged).
4. Home. Empty house: **Name this home**. Kill and reopen: onboarding does **not** return.

**Skip** on the first page also completes first-run; disclaimer still shows if needed. Returning users with the flag set go straight to Home (or disclaimer).
