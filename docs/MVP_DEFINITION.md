# MVP definition (freeze)

**Status:** Frozen as of **2026-08-22** after Phase 1 and Phase 2 candidate builds.  
**App:** **0.1.1+2** (`lib/app_info.dart`). Device-test pack: [`qa/TEST_FEEDBACK_AUG25.md`](qa/TEST_FEEDBACK_AUG25.md). Artifact: [`qa/BUILD_NOTES_PHASE2.md`](qa/BUILD_NOTES_PHASE2.md).  
**This file describes what the code does**, not Version 1 architecture wish lists. Older locks that disagree with this page are historical: [`07_POLICIES/00_MVP_SCOPE_LOCK.md`](07_POLICIES/00_MVP_SCOPE_LOCK.md) (2026-07-19) still lists iOS + Supabase household backend; the shipping book does not.

**MVP = Phase 1 + Phase 2 as implemented**, with the gaps marked **PARTIAL** / **SKIPPED** on [`qa/PHASE2_EXIT_CHECKLIST.md`](qa/PHASE2_EXIT_CHECKLIST.md). Overall Phase 2 exit is **PARTIAL**. That is the product bar until an explicit un-freeze.

Promise in code: observe, don’t guess; safety over completing a repair; privacy on this device; explain important asks. Ranking and diagnosis stay **deterministic** on-device. An LLM does not decide what is wrong.

---

## What MVP is

A **local-first Flutter household repair book** on Android (`flutter build apk --release` / `flutter run`). Chrome can walk chips, sample reset, export, tools, resume, and simulate-offline. There is **no iOS project** in this repo.

### Repair loop (Phase 1, still required)

A household can add an appliance, start a session, answer observation chips, pass safety / easy-check / tool gates, follow beginner-safe guidance, verify, record an outcome, and see that close on **Repair history**. **Continue repair** resumes the first incomplete guidance step. Guides work offline (compiled-in packages). Camera and microphone never diagnose.

Inventories: [`qa/PHASE1_INVENTORY.md`](qa/PHASE1_INVENTORY.md), [`qa/PACKAGE_INVENTORY.md`](qa/PACKAGE_INVENTORY.md).

### Phase 2 that actually shipped

| Capability | Reality |
|---|---|
| Why ask this? | Expand on the current interview / inspect. Authored split sentences + package maps. No ranking dump. |
| Fixed memory | On **Fixed**, confirmable root-cause / contributing / prevention chips. History shows `Prevent:` / `Also:`. **Root cause not sure** stores no invented cause. Pro / not-fixed / stopped skip those chips (handoff still exists). |
| Confidence | Standing phrases on recommendation / summary only. **No `%`**. Hidden on early questions. |
| Washer / DW | `washer-core` / `dishwasher-core` **0.2.3** PRIMARY trust bars. Drain-filter inspect polarity fixed. Not 40-mode encyclopedias. |
| Members | People in a home share that home’s House Book. Homes isolate appliances. No rename, delete, or roles. |
| Pattern hints | Dismissible `From your household history` at N=2 for vent / drain-filter / coils. Sample home must not hint. Not ranking. |
| Readiness | **In your tools** / **Not in your tools** follow household **Tools**, not a copy at session start. |
| Fridge | `fridge-core` **1.0.1** observational PRIMARY. Hard stop: no refrigerant / sealed system / compressor live DIY. Not in sample home. |
| Household Pro | Settings **debug** toggle. Extra export formatting only. Store billing **not wired**. Safety never paywalled. |
| Package discipline | Human release checklist + scenario JSON. Validator does not publish. |
| Knowledge Factory | Folder on disk, not in the app (see below). |

**Not in MVP even though tickets existed:** P2-07 dryer no-heat knowledge quality pass (**SKIPPED**). Dishwasher / fridge in sample home. Home rename/delete. Store IAP. Won’t-spin washer inspect. Dishwasher observational no-power path.

### Knowledge packages (bundled seeds)

| Package | Version | Completeness |
|---|---|---|
| `dryer-core` | 1.4.2 | COMPLETE (8 symptoms, 41 modes). Easy-airflow inspect on **13 / 41**. Resettable cutoff is DIY; thermal fuse swap stays pro-only. |
| `washer-core` | 0.2.3 | PRIMARY (6 symptoms, 9 modes). Spin is interview-only. |
| `dishwasher-core` | 0.2.3 | PRIMARY (7 symptoms, 6 modes). |
| `fridge-core` | 1.0.1 | PRIMARY observational (8 symptoms, 9 modes). Inspect on **4 / 9**. |

No runtime download. Install from this device uses the copy already in the binary.

### Deterministic Core (do not reopen for MVP)

Diagnosis, safety stops, and ranking come from structured knowledge + evidence. LLM = communication/translation only if used at all; it is **not** the ranker. No runtime web research. No runtime invention of procedures.

### Platforms and data

Household data lives in `LocalDomainStore` (on-device). JSON backup/restore is local. Leftover `SupabaseClient` helpers under `lib/services/` are **not** the House Book path (`local_domain_store.dart`: no cloud, sync, or Supabase for that store).

---

## Explicit non-goals (Phase 3 — do not start)

These are **out of MVP**. Architecture essays may describe them; the app must not grow them until validation (below) and an explicit un-freeze.

- Public knowledge / discovery platform, marketplace, or community ranking from outcomes
- Domain OS, plugins for HVAC / automotive / new families
- “10k factory” scale authoring or auto-merge of research into production packages
- Live AR tracking, YOLO/CoreML, object detection, AI-generated part images
- Camera-as-diagnosis (rating-plate OCR / barcode is identity only; inspect camera is flashlight + LOOK FOR text)
- Thermal cameras / external sensors / smart-appliance deep integrations
- Ranking algorithm rewrite or LLM-as-authority diagnosis
- Runtime web research or live package fetch
- Cloud account, cloud sync of household data, push notifications
- Live quotes, checkout, subscriptions, real Store IAP
- Beginner gas DIY, sealed-system / refrigerant DIY, live-electrical how-to
- Multi-language localization as a product track
- iOS ship from this repo (no Xcode project here)

Phase 3 docs such as [`02_ARCHITECTURE/07_0_PUBLIC_KNOWLEDGE_AND_DISCOVERY_PLATFORM.md`](02_ARCHITECTURE/07_0_PUBLIC_KNOWLEDGE_AND_DISCOVERY_PLATFORM.md) stay **architecture**, not MVP scope.

---

## AR parked policy

**Parked.** `arParked = true` and `locationVisualAidsEnabled = false` in `lib/helpers/location_visual_aids.dart`.

| Allowed now | Forbidden until a real curated raster exists |
|---|---|
| Text LOOK FOR + OK / Not OK + chips | Pins, boxes, or overlays on junk / generated images |
| Optional **Use camera while I look** (flashlight + same text) | Live AR tracking, “found it” CV |
| Typical-location **copy** | Show me where / generated dryer schematics in the user path |
| Manual chips as the only diagnostic confirm | Camera deciding a failure mode |

Do not flip the flag for CustomPaint schematics, unbundled SVGs, or “wait for a better vision model.” Details: [`qa/INSPECT_AR_STATUS.md`](qa/INSPECT_AR_STATUS.md), [`qa/PHASE1_INVENTORY.md`](qa/PHASE1_INVENTORY.md) (dormant entry points).

---

## Knowledge Factory authoring-only policy

`knowledge_factory/prototype/` is **not part of the Flutter app**. Do not import it from `lib/`. Do not add it to `pubspec.yaml` assets. Do not fetch URLs from session, interview, inspect, or package-install code.

Production truth is compiled-in: `lib/knowledge_factory/` + `KnowledgePackageRepository`. Candidates in the prototype stay `draft` / `needs_review` until a human signs [`knowledge/PACKAGE_RELEASE_CHECKLIST.md`](knowledge/PACKAGE_RELEASE_CHECKLIST.md). **Do not auto-merge** prototype files into dryer/washer/DW/fridge batches.

Authoring-time research (Cursor / notes) is allowed **outside** the household runtime. Runtime web research is not. README: [`../knowledge_factory/prototype/README.md`](../knowledge_factory/prototype/README.md).

---

## Exit criteria for external validation (before Phase 3)

Phase 3 work (platform, CV, factory scale, Store) waits until **external** testers — not the authoring agents — can sign the bar below on the Phase 2 APK (or a later bugfix build of the same MVP).

Walk [`qa/TESTER_BRIEF_PHASE2.md`](qa/TESTER_BRIEF_PHASE2.md): [`qa/REGRESSION_PHASE1.md`](qa/REGRESSION_PHASE1.md) then [`qa/REGRESSION_PHASE2.md`](qa/REGRESSION_PHASE2.md). Do not treat [`qa/KNOWN_ISSUES.md`](qa/KNOWN_ISSUES.md) as failures.

**Pass (all required):**

1. **Safety:** No beginner live-electrical, gas, or refrigerant/sealed-system how-to. Hazard **Yes** hard-stops without **Fixed**. Fridge path never teaches recharge.
2. **Observe, don’t guess:** Chips and inspect LOOK FOR drive ranking. Camera is optional. `Why ask this?` names a split, not a percent.
3. **Easy checks first:** Dryer lint → hood → hose before panel on no-heat; washer door → filter look before opening the trap; required missing tool stays **Not in your tools** until **Tools** lists it.
4. **Memory:** A DIY **Fixed** writes one history row with prevention when chips were left on. **Continue repair** does not re-ask the starter. Sample reset does not crash. Sample home does not invent a pattern hint.
5. **Local:** Airplane / simulate-offline still shows guides. Export inventory lists model/serial without a login. **Household Pro (debug)** off does not hide stops.
6. **Automation:** `flutter test test/regression_binder_v1_test.dart` and `flutter test` green on the same commit as the APK.

**Does not block validation (known MVP limits):** no dishwasher/fridge in sample home; no iOS; Chrome share sheet vs file; parts copy says estimates only; no push; P2-07 not done; debug entitlement is not a store.

**Fail (blocks Phase 3):** crash on reset; ranking rewrite or LLM diagnosis in the session path; AR/CV enabled without a curated raster; runtime web research; paywalled safety copy; auto-merge of Knowledge Factory candidates into packages.

Until this bar is signed, keep ranking frozen, AR parked, Factory authoring-only, and Phase 3 unbuilt.
