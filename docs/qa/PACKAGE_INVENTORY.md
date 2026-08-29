# Knowledge package inventory

Read-only audit of bundled appliance guides as loaded by `KnowledgePackageRepository` on 2026-08-19. Dryer ranking is unchanged.

Release (human sign-off; validator does not publish): [`docs/knowledge/PACKAGE_RELEASE_CHECKLIST.md`](../knowledge/PACKAGE_RELEASE_CHECKLIST.md). Family folders: [`dryer`](../knowledge/dryer/README.md), [`washer`](../knowledge/washer/README.md), [`dishwasher`](../knowledge/dishwasher/README.md).

**Completeness**

| Mark | Meaning |
|---|---|
| **COMPLETE** | Family package with a full authored mode set, first-line questions, close-path guidance on every mode, and safety gates. |
| **PRIMARY** | Primary real-world symptom paths meet the dryer quality bar (easy checks first, ranked modes, I did this / I couldn’t, safety stops, prevention, path-only cost rows, typical-location diagrams). Not a 40-mode family guide. |
| **PARTIAL** | Thin MVP: small symptom/mode set, beginner-safe close paths only, not a full family guide. |
| **MISSING** | No seeded package for that category. |

None of the four categories is **MISSING**.

**How to see versions in the app:** Settings → About (**App 0.1.1+2**) and Settings → Package manager (`dryer-core 1.4.2`, `washer-core 0.2.3`, `fridge-core 1.0.1`, `dishwasher-core 0.2.3`). Click path: [`VERSIONS.md`](VERSIONS.md).

**How counts were taken**

| Column | Source |
|---|---|
| Version | `KnowledgePackage.version` from `KnowledgePackageRepository().loadById` |
| Symptoms | `KnowledgePackage.symptoms` |
| Failure modes | `KnowledgePackage.failureModes` |
| Easy-check gate | Dryer: `dryerEasyAirflowBeforePartsModeIds` (same 12 ids as `dryerEasyAirflowInspectModeIds`). Washer: `washerEasyCheckTemplateIds` + `washerEasyChecksBeforeRepairModeIds`. Dishwasher: `dishwasherEasyCheckTemplateIds` + `dishwasherEasyChecksBeforeRepairModeIds`. Fridge: `fridgeEasyCheckTemplateIds` + `fridgeEasyChecksBeforeRepairModeIds`. |
| Inspect coverage | `package.inspectSteps` length and ids. Modes counted when `inspectStepsForClosePath` (package list, `appliesTo` family) is non-empty. |
| Guidance steps | Sum of `FailureModeClosePath.safeGuidanceSteps` over every mode in the package (per-mode, not unique strings). Every mode has a close path (`missing = 0`). |
| Safety stops | Package `SafeCheck` rows with `safetyLevel: stop`, plus a `hazard-observation` template if present, plus failure-mode ids that `evaluateSafetyStop` hard-stops by Primary alone. |

Dryer also ships three dedicated easy-airflow interview templates (`lint-filter-condition`, `exterior-airflow`, `vent-hose-condition`). Those are included in the 28 unique first-line ids (52 authored rows on Batch 01+02).

---

## Summary

| Appliance | Package | Version | Status | Symptoms | Failure modes | Easy-check gate | Inspect coverage | Guidance steps | Safety stops |
|---|---|---|---|---:|---:|---|---|---:|---|
| Dryer | `dryer-core` | 1.4.2 | **COMPLETE** | 8 | 41 | 3 airflow templates; gated on **13 / 41** modes. Also 28 unique first-line questions (52 authored rows). | **3** steps (lint filter → hood → hose) on **13 / 41** modes | built-in + imported | 1 hazard prompt + professional-only fuse/element/door/motor ids; 0 `stop` SafeChecks (7 observational checks, `low`/`caution`) |
| Washer | `washer-core` | 0.2.3 | **PRIMARY** | 6 | 9 | 10 easy templates; gated on **9 / 9** modes | **8** steps (door, coin trap, standpipe, hose run, taps, screens, tap drip, power/lock) on **8 / 9** modes (spin is interview-only) | 41 | 4 SafeChecks (3 `stop` + 1 beginner unplug) + 1 hazard prompt |
| Dishwasher | `dishwasher-core` | 0.2.3 | **PRIMARY** | 7 | 6 | 6 easy templates; gated on **6 / 6** modes | **6** steps (tub filter → door → high-loop/hose/knockout → supply/air-gap → spray arms → door-seal leak) on **6 / 6** modes | 28 | 4 SafeChecks (3 `stop` + 1 beginner unplug) + 1 hazard prompt |
| Fridge | `fridge-core` | 1.0.1 | **PRIMARY** | 8 | 9 | 9 easy templates; gated on **9 / 9** modes | **4** steps (temps → gasket → vents → coils) on **4 / 9** modes | 42 | 4 SafeChecks (3 `stop` + 1 beginner unplug) + 1 hazard prompt |

Shared (not a package): `lib/helpers/safety_stop.dart` — evidence substring rules for gas, live electrical language, and fire/smoke. Catalog: `lib/helpers/knowledge_package_catalog.dart`. Close-path lookup: `lib/helpers/dryer_close_path.dart` (`closePathForFailureMode`). Seed: `lib/services/knowledge_package_repository.dart`.

---

## Dryer

**COMPLETE** — production `dryer-core` **1.4.2**. Core seed plus Knowledge Factory Batch 01 (20 modes) and Batch 02 (20 modes), plus **accessible-thermal-reset** (user-reachable cutoff vs panel fuse). Merge yields **41** unique failure modes. Easy-airflow inspect overlays (lint filter → outside hood → visible hose) sit on the 13 heat / long-dry / overheat / resettable-cutoff modes. Brand overlays add access notes and commonality only; they do not add modes.

This package is the **quality-bar reference**: easy non-invasive checks before teardown, ranked failure modes with plain-language symptoms, guidance compatible with **I did this** / **I couldn’t**, explicit safety stops (no live electrical for beginners, no gas DIY, no sealed-system / refrigerant), common misdiagnoses on authored records, prevention lines, cost rows only for parts the close path replaces, and Show me where as a typical-location diagram (yours may vary).

| Field | Count | Notes |
|---|---:|---|
| Symptoms | 8 | `no-heat`, `long-dry-time`, `clothes-hot-but-damp`, `weak-exterior-airflow`, `will-not-start`, `motor-runs-drum-still`, `squealing-or-thumping`, `dryer-very-hot` |
| Failure modes | 41 | Electric-dryer family. Includes `accessible-thermal-reset` (DIY cooldown/reset + vent) and `gas-dryer-no-ignition-professional-only` (escalate; not a gas DIY guide). |
| Evidence templates | 38 | Includes 3 easy-airflow templates and `hazard-observation`. |
| Easy-check coverage | 3 templates / 13 modes | Interview + inspect before panel/parts on the 13 heat / long-dry / overheat / resettable-cutoff mode ids (same set as `dryerEasyAirflowInspectModeIds`). |
| Inspect coverage | 3 steps / 13 modes | `inspect-lint-filter` → `inspect-vent-hood` → `inspect-vent-hose`. Same 13 modes. Other modes have no inspect chain. |
| Easy-check questions | 28 unique / 52 rows | First-line questions on Batch 01+02 records. |
| Close paths | 41 / 41 | Imported from authoring + built-in map (resettable ids prefer built-in DIY). |
| Guidance steps | (see close-path map) | Sum of beginner `safeGuidanceSteps`. Resettable cutoff adds cooldown / visible-reset / vent steps. |
| SafeChecks | 7 | Observational (`low` / `caution`); none tagged `stop`. |
| Safety stops | 1 + 3 | `hazard-observation`; Primary hard-stops: `motor-failure`, `electric-supply-connection-fault`, `electrical-burning-smell-hazard`. |

**File paths**

- `lib/services/knowledge_package_repository.dart` — core symptoms, templates, SafeChecks, base modes
- `lib/knowledge_factory/dryer_batch_01.dart`
- `lib/knowledge_factory/dryer_batch_02.dart`
- `lib/knowledge_factory/data/dryer_batch_01.v1.json`
- `lib/knowledge_factory/data/dryer_batch_02.v1.json`
- `lib/knowledge_factory/golden_examples.dart`
- `lib/knowledge_factory/data/dryer_thermal_fuse_restricted_vent.v1.json`
- `lib/helpers/dryer_close_path.dart` — built-in dryer close paths
- `lib/knowledge_factory/dryer_inspect_steps.dart` — lint / hood / hose inspect overlays
- `lib/helpers/easy_airflow_checks.dart` — lint / vent / hose gate (presentation)
- `lib/knowledge/dryer_brand_overlays.dart` — 5 overlays (Whirlpool/Maytag/Kenmore, GE/Hotpoint, Samsung, LG, Electrolux/Frigidaire)
- `lib/helpers/safety_stop.dart` — shared hard-stop checklist
- [`docs/knowledge/dryer/`](../knowledge/dryer/README.md) — claimed paths + release pointer

---

## Washer

**PRIMARY** — production `washer-core` **0.2.3**. Drain / fill / spin / leak / won’t-start / door-won’t-close. No sealed tub, live electrical, or gas guidance. Manual trust-bar paths: [`WASHER_PATHS.md`](WASHER_PATHS.md). Won’t-drain inspect: door latch then packed-vs-clear coin-trap look. Fill: taps then hose-end screens (screens skipped while a tap is closed). Leak: tap coupling and/or standpipe/hose run. Won’t-start: door and/or power-lock look (no meter). Changelog: [`docs/knowledge/washer/CHANGELOG.md`](../knowledge/washer/CHANGELOG.md).

### Primary paths (DoD)

| Starter chip | Ranked modes (plain-language) |
|---|---|
| Won't drain | Clogged drain filter or pump trap; kinked or clogged drain hose |
| Won't fill | Closed taps or kinked inlet hose; packed inlet-hose screens |
| Won't spin | Unbalanced load (water still in the drum can raise the drain-filter path via a follow-up look) |
| Leaks | Loose inlet hose at the tap; drain hose not seated in the standpipe |
| Won't start | Door not fully latched; no power, breaker off, or control lock |
| Door won't close | Door not fully latched |

| Field | Count | Notes |
|---|---:|---|
| Symptoms | 6 | `wont-drain`, `wont-fill`, `wont-spin`, `leaks`, `wont-start`, `door-wont-close` |
| Failure modes | 9 | Filter, drain hose, taps/kink, inlet screens, unbalanced load, loose inlet, standpipe seating, door latch, power/lock |
| Evidence templates | 12 | 1 complaint + 10 observations + `hazard-observation` |
| Easy-check coverage | 10 templates / 9 modes | Drain: door click → filter look → hose look. Fill: taps then hose-end screens. Spin: load (then water in drum). Leak: tap coupling then standpipe. Start: door then power/lock. Gate: `washerEasyChecksBeforeRepairModeIds`. |
| Inspect coverage | 8 steps / 8 modes | Package order: door click → coin-trap → standpipe → hose run → taps/inlet → screens → tap drip → power/lock. On drain (door + filter; hose leader adds hose run), standpipe leak, door latch, fill taps/screens, loose inlet, no-power. **Won't spin / unbalanced load:** interview only. |
| Guidance steps | 41 | Close path on every mode (9 / 9). Door-latch path does not walk the drain filter. |
| SafeChecks | 4 | `washer-unplug-first` (`beginner`); 3 `stop`: `washer-no-sealed-system`, `washer-no-live-electrical`, `washer-no-gas` |
| Safety stops | 3 + 1 | Those 3 `stop` rows plus `hazard-observation`. No Primary-id hard-stops. |

Show me where uses washer front/rear diagrams with **typical location — yours may vary.** No dryer lint-filter pins.

**File paths**

- `lib/knowledge_factory/washer_mvp_v01.dart`
- `lib/knowledge_factory/washer_inspect_steps.dart` — door, coin-trap, standpipe, hose run, taps, screens, tap drip, power/lock
- `lib/helpers/dryer_close_path.dart` — `_washerClosePaths`
- `lib/helpers/washer_easy_checks.dart` — path-specific easy-first gate (presentation)
- `lib/knowledge_factory/failure_mode_authoring_registry.dart` — prevention, misdiagnoses, tools, path-only parts
- `lib/helpers/knowledge_package_catalog.dart`
- [`docs/knowledge/washer/`](../knowledge/washer/README.md) — claimed paths + release pointer

---

## Dishwasher

**PRIMARY** — production `dishwasher-core` **0.2.3**. Standing water / drain / fill / poor clean / leak / start / door. No sealed pump, live electrical, gas, or refrigerant guidance. Drain inspect and easy checks: tub filter/sump first, then door latch, then hose / high-loop / air-gap / leftover disposal knockout (look only). Fill, poor clean, and leak also have text inspect. Manual: [`DW_PATHS.md`](DW_PATHS.md). Changelog: [`docs/knowledge/dishwasher/CHANGELOG.md`](../knowledge/dishwasher/CHANGELOG.md).

### Primary paths (DoD)

| Starter chip | Ranked modes (plain-language) |
|---|---|
| Standing water | Clogged tub filter |
| Won't drain | Kinked drain hose or blocked drain path; clogged tub filter |
| Won't fill | Closed supply or air-gap blockage |
| Poor clean | Clogged spray arms or dirty filter; clogged tub filter |
| Leaks | Door seal drip or loose visible connection |
| Won't start / Door won't close | Door not fully latched |

| Field | Count | Notes |
|---|---:|---|
| Symptoms | 7 | `standing-water`, `wont-drain`, `wont-fill`, `poor-clean`, `leaks`, `wont-start`, `door-wont-close` |
| Failure modes | 6 | Tub filter, drain path, closed supply/air gap, spray arms, door-seal leak, door latch |
| Evidence templates | 8 | 1 complaint + 6 easy-checks + `hazard-observation` |
| Easy-check coverage | 6 templates / 6 modes | Look at door, filter, hose, supply, spray, or seal before rinse / pull-out / disconnect. Gate: `dishwasherEasyChecksBeforeRepairModeIds`. |
| Inspect coverage | 6 steps / 6 modes | Package order: `inspect-dishwasher-filter` → `inspect-dishwasher-door-click` → `inspect-dishwasher-drain-hose` (high-loop / air-gap / leftover disposal knockout, look only) → supply/air-gap → spray-arm holes → door-seal/sink hose. Drain modes: first three. Door-not-latched: door only. Fill: supply. Poor clean: filter then spray. Leak: gasket/hose look. |
| Guidance steps | 28 | Close path on every mode (6 / 6) |
| SafeChecks | 4 | `dishwasher-unplug-first` (`beginner`); 3 `stop`: `dishwasher-no-sealed-pump`, `dishwasher-no-live-electrical`, `dishwasher-no-gas-or-sealed` |
| Safety stops | 3 + 1 | Those 3 `stop` rows plus `hazard-observation`. No Primary-id hard-stops. |

Show me where uses tub/sink diagrams with **typical location — yours may vary.**

**File paths**

- `lib/knowledge_factory/dishwasher_mvp_v01.dart`
- `lib/knowledge_factory/dishwasher_inspect_steps.dart` — filter / door / hose / supply / spray / leak inspect
- `lib/helpers/dryer_close_path.dart` — `_dishwasherClosePaths`
- `lib/helpers/dishwasher_easy_checks.dart` — easy-first invasive gate (presentation)
- `lib/knowledge_factory/failure_mode_authoring_registry.dart`
- `lib/helpers/knowledge_package_catalog.dart`
- [`docs/knowledge/dishwasher/`](../knowledge/dishwasher/README.md) — claimed paths + release pointer

---

## Fridge

**PRIMARY** — production `fridge-core` **1.0.1**. Observational cooling / door / leak / ice / noise / power paths plus inspect on cooling / door / setpoint (not on leak, ice, noise, or won’t-run). Never refrigerant, sealed-system, compressor live diagnostics, or piercing lines. Manual: [`FRIDGE_PATHS.md`](FRIDGE_PATHS.md).

### Primary paths (DoD)

| Starter chip | Ranked modes (plain-language) |
|---|---|
| Not cooling | Dirty coils or blocked cabinet airflow; door gasket/ajar; temperature controls |
| Fridge warm, freezer cold | Blocked internal vents; door gasket |
| Too cold | Temperature controls set too warm or too cold |
| Water leak | Clogged defrost drain or drip pan |
| Ice maker | Ice maker off or supply closed; ice bin or dispenser jam |
| Noisy | Not level or items rattling |
| Door won't close | Door gasket or ajar |
| Won't run | No power or display off |

| Field | Count | Notes |
|---|---:|---|
| Symptoms | 8 | `not-cooling`, `fridge-warm-freezer-cold`, `too-cold`, `water-leak`, `ice-maker`, `noisy`, `door-wont-close`, `wont-run` |
| Failure modes | 9 | Coils/airflow, internal vents, door gasket, temp controls, defrost drain/pan, ice supply, ice bin jam, unlevel, no power |
| Evidence templates | 11 | 1 complaint + 9 observations + `hazard-observation` |
| Easy-check coverage | 9 templates / 9 modes | Temps, door seal, and internal vents before coil pull-out. Coils only after unplug, accessible grille/coils only. Gate: `fridgeEasyChecksBeforeRepairModeIds`. |
| Inspect coverage | 4 steps / 4 modes | Package order: `inspect-fridge-temps` → `inspect-fridge-door-seal` → `inspect-fridge-vents` → `inspect-fridge-coils`. On `blocked-fridge-coils-or-airflow` (all four), `blocked-fridge-internal-vents` (gasket + vents), `fridge-door-gasket-or-ajar` (gasket), `fridge-temp-controls-set-wrong` (temps + gasket). `fridge-no-power-or-control` and the leak / ice / noise modes: no inspect chain. |
| Guidance steps | 42 | Close path on every mode (9 / 9) |
| SafeChecks | 4 | `fridge-unplug-first` (`beginner`); 3 `stop`: `fridge-no-sealed-system`, `fridge-no-live-electrical`, `fridge-no-compressor-live` |
| Safety stops | 3 + 1 | Those 3 `stop` rows plus `hazard-observation`. No Primary-id hard-stops. |

Show me where uses fridge front/rear diagrams with **typical location — yours may vary.**

**File paths**

- `lib/knowledge_factory/fridge_mvp_v01.dart`
- `lib/knowledge_factory/fridge_inspect_steps.dart` — temps, gasket, vents, coils
- `lib/helpers/dryer_close_path.dart` — `_fridgeClosePaths`
- `lib/helpers/fridge_easy_checks.dart` — observational easy-first gate (presentation)
- `lib/knowledge_factory/failure_mode_authoring_registry.dart`
- `lib/helpers/knowledge_package_catalog.dart`
- [`FRIDGE_PATHS.md`](FRIDGE_PATHS.md) — observational trust bar
