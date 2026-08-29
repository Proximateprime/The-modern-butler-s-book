# MVP audit + polish (Phase 1+2 as shipped)

Audit date **2026-08-22**. App **0.1.0+1**. Scope: make the **current** app trustworthy, calm, and finished for external testers. No Phase 3, no CV/AR, no ranking rewrite, no runtime web research, no Store billing.

Read from code, not from plans. Companion docs: [`PHASE2_EXIT_CHECKLIST.md`](PHASE2_EXIT_CHECKLIST.md), [`../MVP_DEFINITION.md`](../MVP_DEFINITION.md), [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md).

**Verdict:** the loop is sound. One **safety-adjacent trust bug** (P0 below), plus dead AR code compiled in, ungated debug chrome, and a late pro warning. Everything else is polish.

---

## P0 — fixed before cosmetics

**Pro-only paths sold a DIY price.** On `thermal-fuse-open`, `heating-element-failed`, and `door-switch-failure`, the session showed **Parts & cost** with `DIY ~ $10–25` and an **I'll repair** button, let the user gather tools, and only at the guidance phase said *A full fix likely needs a pro*. `partsEstimatesForSelectedPath` never consulted `closePathDiyCannotComplete` (`lib/helpers/parts_cost.dart:121`), and the pro-scope card only mounted in `ClosePathPhase.guidance` (`lib/ui/session_screen.dart:3587`).

That is false DIY hope on the exact paths where the app must be most honest. Fixed in B1/B2 below.

---

## A1. Navigation & surface inventory

38 files in `lib/ui/`; 16 are routes. **Keep** unless noted.

| Surface | File | Decision | Reason |
|---|---|---|---|
| Splash | `splash_screen.dart` | Keep | ~900ms brand, skipped in tests |
| First run (3 slides) | `first_run_screen.dart` | Keep | Honest limits before Home |
| Safety disclaimer | `safety_disclaimer_screen.dart` | Keep | Gate + read-only re-read |
| Home / House Book | `home_screen.dart` | Keep | Appliances, maintenance, history, export |
| Appliance detail | `appliance_detail_screen.dart` | Keep | History, pattern hint, start/continue |
| Add / edit appliance | `add_appliance_screen.dart` | Keep | Model/serial identity |
| Session | `session_screen.dart` | Keep | The product |
| Record outcome | `session_outcome_screen.dart` | Keep | Fixed memory |
| Completion | `session_completion_screen.dart` | Keep | Wrap-up + reminder |
| Technician handoff | `pro_handoff_screen.dart` | Keep | Already an **outcome** screen, not a repair step |
| Tools inventory | `tools_inventory_screen.dart` | Keep | Readiness source of truth |
| Profiles sheet | `profiles_picker.dart` | Keep | Homes + people |
| Guides / install / About | `package_manager_screen.dart`, `package_install_screen.dart`, `about_screen.dart` | Keep | Versions, local install |
| Settings | `settings_screen.dart` | Keep, **gate Demo + Pro** | See A2.5 |
| **Visual guide** | `visual_guide_screen.dart` | **Delete** | AR parked; unreachable (`locationVisualAidsEnabled` false) |
| **Dryer inspect diagram** | `dryer_inspect_diagram.dart` | **Delete** | Unreferenced widget, self-labelled parked |

Duplicate navigation (Tools and Profiles from both the home AppBar and Settings; Load sample home from both Home and Settings): **Keep**. Two doors to one room is normal here — Settings is the discoverable path, the AppBar is the fast one. No duplicate *destination screens*.

---

## A2. Useless UI hit list

| # | Item | Decision | Evidence / action |
|---|---|---|---|
| 1 | Camera on a step with no inspect purpose | **Already safe** | Inspect mounts with `offerLiveCamera: false` (`session_screen.dart:2383,3541`), so the flashlight never appears. Evidence photo **Gallery / Camera** stays — it attaches an optional local photo, is labelled *Optional photo of what you see. It stays on this device.*, and does not rank. |
| 2 | Show me where / visual guide / pins / diagrams | **Delete** | Push gated by `locationVisualAidsEnabled` (false). Screen, widget, and the two unbundled SVGs removed. |
| 3 | Browse failure modes rabbit hole | **Keep (already advanced)** | Collapsed `ExpansionTile`, subtitle *Optional — a recommendation is already shown above*, hidden on safety stop and terminal. No change needed. |
| 4 | Live quotes / tax / payment / checkout | **None exist** | Only *Estimates only. Not a quote.* and *Estimates only — no payment.* **But** the DIY estimate itself was misleading on pro-only paths — see P0. |
| 5 | Household Pro debug visible in release | **Gate** | No `kDebugMode` anywhere in the repo. Switch labelled `Household Pro (debug)` shipped to testers. Now debug-only. |
| 6 | Empty panels that look broken | **Keep** | Evidence / failure modes / working notes are collapsed tiles with one calm line each; they do not read as broken. |
| 7 | Redundant Exit + Back + End Session | **Keep** | Distinct: **Exit** leaves (progress saved), **Back** steps one phase, **End Session** records an outcome. Labels already differ. |
| 8 | `Step N of N` on escalation handoff | **Already correct** | Progress only renders inside `_SafeGuidanceCard`; the pro warning and pro-recommended cards replace it. |
| 9 | AR / YOLO / CoreML in UI strings | **None** | Only code comments in `location_visual_aids.dart`. |

Also removed: **Multimeter** and **Voltage tester** from the addable tools catalog. No supported dryer/washer/DW/fridge path requires either, both are flagged `isLiveElectricalTool`, and offering them implies live-electrical work is in scope.

**Demo section kept, not hidden.** Load sample home, Reset sample data, Include sample open session, Simulate offline, and Simulate camera & microphone denied are all *required by* [`REGRESSION_PHASE1.md`](REGRESSION_PHASE1.md) and [`REGRESSION_PHASE2.md`](REGRESSION_PHASE2.md). Hiding them would break the tester scripts. They now carry a one-line explainer that they are demo content, not household data.

---

## A3. Flow audit (trust)

### Early capability warning

| | |
|---|---|
| Required | Warn **before** a long DIY chain when the leader is pro-only |
| Was | `_ProScopeWarningCard` mounted only at `ClosePathPhase.guidance`, i.e. after conclusion → decision → **parts (with a DIY price)** → tools → inspect |
| Now | A pro-scope notice also mounts on the **conclusion** card, before the user picks **I'll repair** or gathers anything; the parts card drops the DIY estimate and the **I'll repair** CTA on those paths |

### Pro handoff

Already an outcome, not a fake repair step. `safeCheckGuidanceSteps` strips terminal "call a pro" copy from numbered guidance, so those lines never get an **I did this**. `formatProHandoffSummary` emits *Why we're stopping* → *What to tell a technician* → *What we noticed* → *Leader hypothesis* → *What was already tried* → *Safety notes*. `proHandoffWhy` / `proHandoffTellTechnician` are mode-specific for the four dryer escalations and have honest defaults. **Keep as built.**

Gap closed: the interview "paused" line said *Questions are paused* without saying why. Now names the reason.

### Fixed outcome

Root cause / prevention are confirmable chips on **Fixed** only; **Root cause not sure** stores nothing invented; history writes on close, never mid-session. Safety hard-stop cannot reach **Fixed** (`_allowFixed` requires `allowResolved`; `_endSession` on a stop closes as `calledProfessional`). **Correct as built.**

### Tools readiness

Reads household `ownedToolIds` live (P2-12). Required-but-missing shows **Not in your tools** and does not unlock invasive steps. **Correct as built.**

---

## A4. Copy audit

| Problem | String | Action |
|---|---|---|
| Cryptic | `Questions are paused — finish this step, then End Session.` | Say why: we already have a most-likely cause |
| Apologetic / unclear | `Using general dryer guide — model-specific notes limited` | Plainer: what it means for the user |
| Jargon | `thermal cutoff`, `continuity`, `windings`, `capacitor` | Only appear in **prohibitions** ("do not test live windings") and pro-facing handoff text, where the precise word is the point. Household-facing interview uses plain words. **No change.** |
| Over-confident | — | Leader copy is `Most likely` / `More of your answers match this…`; no "definitely". **No change.** |
| Shame / panic | — | Safety stop is `Stop — Call a professional` plus a reason. Firm, not panicky. **No change.** |

Tone target unchanged: calm technician, observation first, engineering wording kept in stored history and the technician handoff.

---

## A5. Knowledge audit (dryer, washer, dishwasher, fridge)

No new modes authored. Findings:

| Family | Finding | Action |
|---|---|---|
| Dryer no-heat | Easy checks (lint → hood → hose) already precede panel work on the 12 gated modes. Discriminators present. | None |
| Dryer `thermal-fuse-open`, `heating-element-failed`, `door-switch-failure` | Terminal is a handoff, but **parts showed a DIY price first** | **P0 fix** (B1) |
| Dryer | `worn-drum-rollers` / `idler-pulley-wear` say "typically a technician job" but are not `isProHandoffGuidanceStep`, so they keep **I did this** | Left as-is: those paths *are* DIY-completable for a confident user; the copy is a caution, not a stop |
| Dryer | No beginner meter steps anywhere; `forbidden_guidance` strips multimeter / ohm / continuity | None |
| Washer | Won't-spin (`unbalanced-washer-load`) has **no** inspect chain | Correct — the app never promises one. Steps are honest ("Do not open a sealed transmission or test live electrical parts"). None |
| Washer | Drain-filter polarity: **Matches / OK** = clear = `No` | Verified correct in `washer-core` 0.2.3. None |
| Dishwasher | Won't-start has only the door-latch mode, no observational no-power path | Honest gap; documented in KNOWN_ISSUES. Not authored this pass |
| Fridge | Three `stop` SafeChecks (`fridge-no-sealed-system`, `fridge-no-live-electrical`, `fridge-no-compressor-live`); close paths never add or recover refrigerant | Verified. None |

**No package version bumps** — no knowledge content changed. Only presentation of parts/cost and warning timing.

---

## A6. Dead code / dead assets

| Item | Decision |
|---|---|
| `lib/ui/visual_guide_screen.dart` | **Delete** (unreachable; AR parked) |
| `lib/ui/dryer_inspect_diagram.dart` | **Delete** (no importer) |
| `assets/inspect/dryer-front.svg`, `dryer-rear.svg` | **Delete** (not in `pubspec.yaml`, rejected by `inspectHasCuratedImage`) |
| `lib/helpers/visual_guide.dart` | **Keep** — still live logic (`visualGuideForSafeStep`, forbidden-content checks) |
| `lib/services/appliance_service.dart` | **Delete** — dead Supabase CRUD stub that **no longer compiles** against the current `Appliance` model (11 analyzer errors). Only survived because nothing imports it |
| Rest of Supabase cluster: `services/knowledge_graph_service.dart`, `seed/knowledge_graph_seeder.dart`, `seed/kg_mvp_seed_data.dart`, `models/knowledge_graph.dart`, `examples/kg_query_examples.dart` | **Keep, isolated** — not reachable from `main.dart`; `Supabase.initialize` is never called. These still compile. Dropping them (and the `supabase_flutter` dependency) is a build-size decision, not a UX polish one |
| `lib/demo/session_happy_path.dart` | **Keep** — used by `test/session_coordinator_test.dart` |
| `knowledge_factory/data/*.json` | **Keep** — authoring source, asserted by tests |
| Sample data leaking into a real household | **No leak** — sample only enters a household literally named `Sample home`, and only on explicit user action |

---

## What was removed vs fixed

**Removed**

- `lib/ui/visual_guide_screen.dart`, `lib/ui/dryer_inspect_diagram.dart`, `test/visual_guide_test.dart`
- `assets/inspect/dryer-front.svg`, `assets/inspect/dryer-rear.svg`
- The **Show me where** button and its dead branch in `session_screen.dart`
- The curated-image branch in `inspect_step_card.dart` (never satisfiable while AR is parked)
- **Multimeter** and **Voltage tester** from the addable tools catalog
- `HouseholdEntitlementUrgency` dead constant list (folded into the test that used it)

**Fixed**

- Parts & cost hides the DIY estimate and the **I'll repair** CTA on `closePathDiyCannotComplete` paths; shows a pro-only line instead
- Pro-scope notice now also appears on the **conclusion** card, before decision / parts / tools
- **Household Pro (debug)** is compiled out of release builds (`kDebugMode`)
- Demo section labelled as demo content
- Paused-questions and general-guide copy say what they mean

**Left alone on purpose:** ranking, close-path knowledge content, pro handoff structure, browse-failure-modes tile, evidence photo capture, Demo tester controls.

---

## Test suite: was red, now green

The suite was **not** green before this pass — 9 widget tests failed, and none of them were caused by the polish work. All were test-harness fragility, verified by reverting individual edits:

| Test | Cause | Fix |
|---|---|---|
| `maintenance_list_test`: home shows next upcoming reminders | Ran at the default 800×600 surface; the reminder tile sat at y=675 | `prepareTallSurface` |
| `settings_test`, `demo_mode_test` (2) | `scrollSettingsUntil` only scrolled **down**, so a row above the current offset was unreachable and the drag detached the scrollable | Helper rewinds to the top first |
| `session_timeline_test` (2), `session_back_navigation_test` | Tapped `answer-choice-weak` directly, but `exterior-airflow` renders as an inspect card | Use the existing `tapInspectOrAnswerChoice` helper |
| `opportunistic_maintenance_test` (2) | Same, for `heavily-clogged` | Helper now maps clogged/blocked to **Doesn't match / Not OK** |
| `ui_vertical_slice_test` | Hard-coded `recent-outcome-session-3`; id numbering shifted when household members started consuming ids (P2-10) | Read the real session id from the repository |

**699 tests pass** (`flutter test`). New coverage in `test/audit_polish_test.dart`.

---

## Phase C — verification

Automated, on this commit:

| Check | Result |
|---|---|
| `flutter analyze` on `lib/` | Clean (0 errors, 0 warnings) |
| `flutter test` | **699 passed** |
| `flutter build apk --release` | Built `build/app/outputs/flutter-apk/app-release.apk`, 99.2 MB (104,043,521 bytes), **2026-08-22 20:47** |

Manual steps for a phone pass — [`REGRESSION_PHASE2.md`](REGRESSION_PHASE2.md) §L covers 1 and 3:

1. **Dryer no-heat, pro-terminal.** Sample dryer → **No heat** → heat cycle **Yes**, drum **Turns normally**, no warmth, airflow **Matches / OK**. Expect *A full fix likely needs a pro* on **Most likely**; **Parts & cost** with `Pro ~` only; no camera chrome on any inspect step; handoff listing *Why we're stopping* and *What to tell a technician*.
2. **Tools round-trip.** Tools → add **Screwdriver** → kill the app → reopen → start a repair whose checklist needs it → **In your tools**. Remove it → **Not in your tools**. Meters are not in the add list.
3. **Fixed path.** A DIY-completable close → **Confirmed** → **Fixed** → tap **Root cause not sure** → save. History row appears with no invented root cause.
4. **Washer drain.** **Won't drain** → door then filter look before opening the trap; **Matches / OK** on the filter means *clear*.
5. **Fridge sealed stop.** Add Fridge → **Not cooling** → confirm no step ever offers refrigerant, sealed-system, or compressor work; hazard **Yes** hard-stops without **Fixed**.
6. **Browse failure modes.** Collapsed by default, subtitle marks it optional, hidden after a safety stop — a beginner is not trapped in it.

---

## Constraints held

Ranking core untouched. `arParked` stays `true` and `locationVisualAidsEnabled` stays `false` — the dead UI behind them is now gone rather than dormant. No Phase 3 surface added. No runtime web research and no LLM in the diagnostic path. No Store billing. No gas, sealed-system, refrigerant, or beginner live-electrical guidance. App version stays **0.1.0+1** — no user-facing feature was added, so the version line in Settings and the docs stays valid.

## Known issues left (honest)

- Dishwasher **Won't start** still has only the door-latch path; no observational no-power look.
- Washer **won't spin** stays interview-only (no inspect chain). Correct, but thin.
- Sample home still has no dishwasher or fridge, so §C and the fridge paths need a manually added appliance.
- P2-07 (dryer no-heat knowledge quality pass) remains **SKIPPED**.
- The unused Supabase knowledge-graph cluster still compiles into the tree and keeps `supabase_flutter` in `pubspec.yaml`. Not reachable at runtime; removing it is a build-size decision.
- `worn-drum-rollers` and `idler-pulley-wear` say "typically a technician job" but remain DIY-completable, so they keep **I did this**. Intentional, but the wording is softer than the hard pro-only paths.
