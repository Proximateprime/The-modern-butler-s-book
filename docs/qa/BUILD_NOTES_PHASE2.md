# Phase 2 candidate APK

Built **2026-08-25 10:23** (local). Device-test fix pack on the frozen ranking core (app **0.1.1+2**, dryer-core **1.4.2**). **No Phase 3** (no public knowledge platform, no live AR/CV, no domain OS, no Store IAP).

What changed in this APK: [`TEST_FEEDBACK_AUG25.md`](TEST_FEEDBACK_AUG25.md). Phase 1 notes: [`BUILD_NOTES.md`](BUILD_NOTES.md). Prior Phase 2 household-retention candidate was **2026-08-22** (0.1.0+1, 99.2 MB).

## Artifact

| | |
|---|---|
| Path | `build/app/outputs/flutter-apk/app-release.apk` |
| Size | 99.6 MB (104,481,211 bytes) |
| Version | **0.1.1+2** |
| Command | `flutter build apk --release` |

ProGuard still has ML Kit optional-language `-dontwarn` rules in `android/app/proguard-rules.pro`. Assemble completed without new missing-class rules.

`flutter test`: 708 passed. `flutter analyze lib test`: no errors on this pack’s files; remaining infos/warnings are pre-existing (const, deprecations, unused test stubs).

## What testers should retest

Walk [`REGRESSION_PHASE2.md`](REGRESSION_PHASE2.md) after [`REGRESSION_PHASE1.md`](REGRESSION_PHASE1.md), plus [`TESTER_BRIEF_PHASE2.md`](TESTER_BRIEF_PHASE2.md):

- First **What's going on?** is **multi-select**; two chips both appear in the starting-from line
- After Most likely, **Review what you checked** does **not** undo diagnosis
- Resettable thermal cutoff vs thermal **fuse** (fuse stays pro-only on Parts)
- Dual remaining causes: simpler path first
- Belt / bearings brick-risk warning still lets you continue
- Maintenance due ping or home banner; no empty manufacturer cards
- **Why ask this?** on dryer no-heat lint look
- **Fixed** outcome chips (root cause / prevention) → history `Prevent:`
- Washer pan **Not in your tools** ↔ **In your tools** vs household **Tools**
- Sample home has **no** `From your household history` card
- Safety stops and emergency copy still appear with **Household Pro (debug)** off

## Not in this APK

Live quotes, checkout, subscriptions, generated inspect pictures, runtime web research / live LLM diagnosis, Knowledge Factory prototype UI (`knowledge_factory/prototype/` is authoring-only on disk), calendar OAuth, iOS.
