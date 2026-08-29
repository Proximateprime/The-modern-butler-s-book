# Tester brief — Phase 2 candidate

**App 0.1.1+2** · Device-test fix pack **2026-08-25**. Ranking still frozen. AR / AI images still off. Camera never diagnoses. **No Phase 3** (no public platform, no live CV, no domain OS).

Guides: **dryer-core 1.4.2**, **washer-core 0.2.3**, **fridge-core 1.0.1**, **dishwasher-core 0.2.3**.

Install: [`BUILD_NOTES_PHASE2.md`](BUILD_NOTES_PHASE2.md) (`build/app/outputs/flutter-apk/app-release.apk`). What changed in this APK: [`TEST_FEEDBACK_AUG25.md`](TEST_FEEDBACK_AUG25.md). Exit marks: [`PHASE2_EXIT_CHECKLIST.md`](PHASE2_EXIT_CHECKLIST.md). What MVP is: [`../MVP_DEFINITION.md`](../MVP_DEFINITION.md).

Phase 1 one-pager (still valid): [`TESTER_BRIEF.md`](TESTER_BRIEF.md).

## Start

1. Install the Phase 2 APK (or `flutter run` on a phone).
2. First launch: **Skip** or **Get started** → **I understand**. [`FIRST_RUN.md`](FIRST_RUN.md).
3. **Load sample home**. **Include sample open session** **off**, then **Reset sample data**. [`DEMO_RESET.md`](DEMO_RESET.md).
4. Walk [`REGRESSION_PHASE1.md`](REGRESSION_PHASE1.md), then [`REGRESSION_PHASE2.md`](REGRESSION_PHASE2.md) (§H Why ask this, §I Fixed memory, §J readiness, §K pattern hint if you can run two Fixes). Phone: [`REGRESSION_PHONE.md`](REGRESSION_PHONE.md).
5. Optional: fridge [`FRIDGE_PATHS.md`](FRIDGE_PATHS.md); backup [`BACKUP_SMOKE.md`](BACKUP_SMOKE.md); denied camera [`PERMISSIONS_DENIED.md`](PERMISSIONS_DENIED.md).

## Changed in the 2026-08-25 device-test pass

- First **What's going on?** chips are **multi-select**. Pick every observation that fits; Other can combine with chips.
- After Most likely, **Review what you checked** lists inspect looks. It does **not** start the interview over.
- A dryer with a **reset button / cooldown cutoff** is not the same as a **thermal fuse** swap. Fuse stays pro-only (no DIY price / I'll repair on Parts). Reset + vent/lint can complete at home.
- If two causes still fit, the app pursues the **simpler** one first and keeps the other listed.
- High-stakes DIY (belt / bearings / rollers) shows a hard warning; you still choose whether to continue.
- Maintenance reminders can ping locally when due, or show a home banner if notifications are off. Empty manufacturer / community cards are hidden.
- Typed Other text is stored even when the guide has no exact match.

Prior polish (2026-08-22) still applies: [`AUDIT_POLISH_MVP.md`](AUDIT_POLISH_MVP.md) (pro-only Parts card, no Show me where, no meters, Household Pro debug-only, plain interview pause copy).

## Pass if

- Phase 1 kit still passes (easy checks first, chip-only repair, **Continue repair**, **Fixed** history).
- `Why ask this?` on the current no-heat look names a split, not a `%`.
- **Fixed** can save guide **Prevention** onto the history row (`Prevent:`).
- Washer pan **Not in your tools** until it is on **Tools**, then **In your tools**.
- Sample home does **not** invent `From your household history`.
- A pro-only path never shows a **DIY ~** price or **I'll repair** on **Parts & cost**.
- **Review what you checked** after a conclusion leaves the same most-likely cause in place.
- Two starter chips both show in the session’s starting-from line / evidence.

## File as bugs

Crashes, lost household data, live-electrical / gas / sealed-system how-to for beginners, **Continue repair** that re-asks the starter, required tool marked owned when **Tools** does not list it, `%` on confidence copy, pattern hint on sample dryer, a **DIY ~** price on a path that later says you need a technician, **Review what you checked** wiping answers.

Do **not** file [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md). Do **not** file “no Store purchase,” “no dishwasher in sample home,” or “Knowledge Factory folder is not in the app.”
