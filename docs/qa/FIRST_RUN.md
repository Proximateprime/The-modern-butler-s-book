# First-run onboarding

Three short screens. **Skip** or **Get started** both finish it for good. Legal **Safety disclaimer** is a separate screen after this.

Read from code on **2026-08-22**. Tests: `test/first_run_empty_states_test.dart`. Flag: `modern_butler_first_run_complete_v1`.

---

## Screens

| # | Title | Point |
|---|---|---|
| 1 of 3 | **What Butler does** | Observe → guide safe checks → remember House Book |
| 2 of 3 | **What it doesn’t do** | No gas / live electrical / sealed cooling DIY. **The camera never diagnoses.** |
| 3 of 3 | **Your household stays here** | Names, appliances, photos, tools, repair notes on this device. Not uploaded. |

---

## Tap path — once on a fresh install (DoD)

Uninstall the app or clear app storage so SharedPreferences is empty.

1. Launch. After splash: **What Butler does** (**1 of 3**). **Skip** is in the app bar. The first tap on Skip completes first-run.
2. **Next** → **What it doesn’t do**. **Next** → privacy. **Get started**.
3. One-time **Safety disclaimer** → **I understand** (if not already acknowledged).
4. Home. Kill and reopen: onboarding does **not** return.

**Skip** on screen 1 also completes first-run; disclaimer still shows if needed. Returning users with the flag set go straight to Home (or disclaimer).
