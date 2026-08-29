# Offline smoke (installed packages)

Installed appliance guides run **on this device**. Airplane mode must not crash or blank the repair. There is **no cloud LLM** in the live repair path. Installing a bundled guide does **not** need the internet.

Read from code on **2026-08-22**. Tests: `test/offline_packages_test.dart`, `test/degraded_mode_ux_test.dart`, `test/knowledge_package_manager_test.dart`. Copy: **Offline — guides on this device still work**.

Phone: `flutter run` (or the release APK). Chrome: use **Simulate offline** (no OS airplane).

---

## What still works offline

Questionnaire chips, inspect LOOK FOR, tools checklist, Safe Guidance, Record outcome, House Book, tools inventory, maintenance Done, local backup/restore, **Install from this device**.

Home shows **Offline** in the app bar and the degraded banner. A repair shows the same banner (`session-offline-banner`) **above** the questions — not instead of them.

---

## What is not a network feature

| Control | Offline behavior |
|---|---|
| **Install from this device** | Local bundled copy. Helper: *Installing uses the copy stored on this device. It does not need the internet.* |
| **Check for updates** | Snackbar: *You’re offline. Guides already on this device still work.* (stub — no cloud catalog) |
| Cloud diagnosis / LLM | None. Ranking is the on-device package. |

Share/export uses the OS share sheet; if the sheet cannot run, text may copy locally. That is not a Butler cloud upload.

---

## A. Phone — airplane mode (DoD)

1. Wi‑Fi on. **Load sample home**. Open **Laundry Room Dryer** → **Start repair**. Confirm **What's going on?** and chips (e.g. **No heat**).
2. Without leaving the app, turn on **Airplane mode** (OS). Bring the app to the foreground if Android paused it.
3. Home (Exit if needed): app bar **Offline**, banner **Offline — guides on this device still work**. Dismiss **OK** if you want; the repair still works.
4. **Continue repair** or **Start repair** again. Questions and (after I'll repair) **Safe Guidance** still appear. Not a blank white screen. No stack trace.
5. Settings → **Guides** → **Check for updates**: offline snackbar. If a family is missing, **Install from this device** still completes.

Pass: chips + guidance for the installed family; calm Offline copy; no crash.

Turn airplane mode off when done.

---

## B. Chrome / emulator without airplane — Simulate offline

1. Settings → **Demo** → **Simulate offline** on.
2. Same as A from the Home banner and a dryer session.

Turn the switch off to restore the online chrome (guides were never removed).
