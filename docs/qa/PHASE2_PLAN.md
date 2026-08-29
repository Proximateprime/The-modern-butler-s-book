# Phase 2 plan (P2-01)

**Candidate exit (P2-15):** [`PHASE2_EXIT_CHECKLIST.md`](PHASE2_EXIT_CHECKLIST.md) — overall **PARTIAL**. Testers: [`TESTER_BRIEF_PHASE2.md`](TESTER_BRIEF_PHASE2.md). APK: [`BUILD_NOTES_PHASE2.md`](BUILD_NOTES_PHASE2.md). Frozen definition: [`../MVP_DEFINITION.md`](../MVP_DEFINITION.md).

Planning inventory only — **no implementation in this pass.** Dated **2026-08-22**.

**Sources:** there is no `PHASE1_EXIT_CHECKLIST.md` file. This list is read from the Phase 1 exit surfaces plus code: [`PHASE1_INVENTORY.md`](PHASE1_INVENTORY.md), [`REGRESSION_PHASE1.md`](REGRESSION_PHASE1.md), [`PACKAGE_INVENTORY.md`](PACKAGE_INVENTORY.md), [`WASHER_PATHS.md`](WASHER_PATHS.md), [`DW_PATHS.md`](DW_PATHS.md), [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md), Version 1 in-scope leftovers in [`docs/07_POLICIES/00_MVP_SCOPE_LOCK.md`](../07_POLICIES/00_MVP_SCOPE_LOCK.md), confidence policy in [`docs/02_ARCHITECTURE/03_10_CONFIDENCE_AND_EXPLAINABILITY_POLICY.md`](../02_ARCHITECTURE/03_10_CONFIDENCE_AND_EXPLAINABILITY_POLICY.md). Standing product lock: MVP Phase 1+2 household repair; Phase 3 (public platform, domain OS, CV) stays out.

**Still frozen from Phase 1:** ranking algorithm, AR / AI images, live quotes, beginner gas / sealed-system / live-electrical how-to, runtime web research.

Priorities below are **user retention** (come back, finish a session, trust the book) — not encyclopedia size.

---

## Order of work

| Rank | Work | Retention why | Phase 2 posture |
|---|---|---|---|
| **1** | Explainability — “why this question” | Stops drop-off when the interview feels random | **Do next** |
| **2** | Root cause / prevention on verified outcomes | House Book becomes the reason to return | **Do next** |
| **3** | Deeper washer / dishwasher from **real gaps** | Most households hit these more often than fridge DIY | **Do next** |
| **4** | Confidence display (only when meaningful) | Fake certainty or “Possible” on everything trains people to ignore the book | **Do with 1** (same session chrome) |
| **5** | Package verification discipline | Protects 1–3; bad packages destroy trust faster than missing modes | **Do as a gate**, not a feature |
| **6** | Household multi-profile polish | Needed for two homes / roommates; core add/switch already ships | **If in scope after 1–5** |
| **7** | Fridge observational-only depth | Less frequent DIY; package already PRIMARY | **Schedule** unless 1–5 finish early |

---

## 1. Explainability (“why this question”)

**Version 1 asked for** real-time “Why are you asking this?” ([MVP scope lock](../07_POLICIES/00_MVP_SCOPE_LOCK.md); architecture [3.10](../02_ARCHITECTURE/03_10_CONFIDENCE_AND_EXPLAINABILITY_POLICY.md)).

**Code today**

- After a most-likely cause: expandable **How we got here** (`lib/ui/how_we_got_here_tile.dart`) lists observations plus a generic leader sentence (`leaderWhyFromStandings` in `lib/helpers/session_timeline.dart`).
- **Why ask this?** on the current interview and inspect (`lib/ui/why_ask_this_tile.dart`, `lib/helpers/why_ask_this.dart`): authored split sentences plus remaining-mode names from package `supportByAnswer` / `excludeByAnswer`. No LLM, no ranking dump. Tests: `test/why_ask_this_test.dart`.

**Phase 2 DoD**

- On the current observation (and inspect LOOK FOR), a short, authored or package-derived reason: what this answer *splits*, not a lecture.
- Same voice as the book: observe, don’t guess. Never invent a reason at runtime (no LLM as authority).
- Optional: “Why this most-likely?” stays the existing tile, tightened so it names *which answers* moved the leader — still display-only, no ranking change.

**Out of scope:** full trace dump, percentages, “why the algorithm.”

---

## 2. Root cause / prevention on verified outcomes

**Version 1 asked for** basic root-cause capture, prevention, and household memory.

**Code today**

- `SessionOutcome` already has `rootCause`, `contributingFactors`, `preventiveActions` (`lib/models/session_outcome.dart`).
- **Record outcome** seeds those fields from authoring **only when the user picks Fixed**, as confirmable chips plus optional extra lines (`lib/ui/session_outcome_screen.dart`). **Root cause not sure** stores no root cause (no LLM guess). History shows `Prevent:` / `Also:` (`repairHistoryExtraLines`). Optional **Update maintenance schedule** writes a local reminder.
- Professional / not-fixed / stopped closes skip the memory fields even when verification ran.

**Phase 2 DoD**

- After a **verified** close (Confirmed on a DIY-completable path, or an honest pro handoff after safe checks): show **why it failed** and **what stops a repeat**, seeded from the package, editable, written to House Book.
- History / wrap-up must surface prevention without opening Settings.
- Do not pretend a pro-required path (thermal fuse, heater circuit) was a completed DIY fix.

**Out of scope:** community learning from outcomes, ranking updates from memory. A separate **display-only** pattern hint (P2-11) may appear on the appliance page from repeated verified Fixed / maintenance records; it does not change ranking.

---

## 3. Deeper washer / dishwasher (from real gaps)

Washer and DW are **PRIMARY**, not dryer-COMPLETE ([`PACKAGE_INVENTORY.md`](PACKAGE_INVENTORY.md): washer-core **0.2.3**, 9 modes; dishwasher-core **0.2.3**, 6 modes). Phase 1 trust bars are done ([`WASHER_PATHS.md`](WASHER_PATHS.md), [`DW_PATHS.md`](DW_PATHS.md)). Phase 2 is **not** “add 40 modes.”

**Real gaps (code / known issues)**

| Gap | Where | Why it hurts retention |
|---|---|---|
| Drain-filter inspect polarity | Fixed in `washer-core` **0.2.3** (OK = clear / `No`; not-OK = packed / `Yes`) | Was a retention bug: both chips stored `Yes` |
| Won’t-spin has no inspect chain | Inventory: **8 / 9** washer modes; unbalanced load is interview-only | Easy to skip into “motor” anxiety; standing water already redirects to drain |
| Dishwasher won’t-start has no observational no-power path | DW_PATHS: latch only by design | Fine for Phase 1; Phase 2 may add **plug / breaker / lock look** (no meter) if testers bounce |
| Sample home has no dishwasher | [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md), [`DEMO_RESET.md`](DEMO_RESET.md) | Testers and households never try DW |
| Thin competing-mode sets | 9 washer / 6 DW modes vs dryer 40 | Only deepen where a discriminator is missing (e.g. fill vs screens already exist — do not clone dryer encyclopedia) |

**Phase 2 DoD (washer then DW)**

1. Fix washer drain-filter inspect **answer maps** so OK vs not-OK actually discriminate.
2. Add inspect or LOOK FOR only where a competing mode is currently unsplit (spin/water already in interview — verify that path on a phone before adding chrome).
3. Optional: canned **Add Dishwasher** in sample home (same reset rules as dryer/washer).
4. Keep gates: unplug before open-filter; no sealed tub/pump; no live electrical.

**Out of scope:** inverter / hall-sensor / wash-motor / heater / control-board encyclopedias (explicitly parked in WASHER_PATHS / DW_PATHS).

---

## 4. Confidence display (only when meaningful)

**Architecture 3.10** wanted bands and even percents (“Drain obstruction (82%)”).

**Code today**

- Standing is **integer support/exclude counts**, not probabilities (`FailureModeStanding` in `lib/helpers/failure_mode_standing.dart`).
- Early interview **Browse failure modes** shows no Stronger match / Possible / Less likely chrome (`showStandingChrome: false`).
- Recommendation and diagnosis summary use humble phrases (`lib/helpers/confidence_display.dart`). Never percents. Tests: `test/confidence_display_test.dart`.

**Phase 2 policy (do not add percents)**

- Show a rank label **only** when it changes a decision: e.g. **Stronger match** when net ≥ 2, **Less likely** when weakened, hide or demote blanket **Possible** on every row.
- Never show “82%” or “highly consistent” from counts of 1.
- Tie copy to explainability (item 1): “more of your answers match this” beats a badge.

**Out of scope:** new scoring engine, LLM confidence, architecture percent bands.

---

## 5. Package verification discipline

Authoring-time only. Candidates are not production until a human signs ([standing knowledge rule](../../.cursor/rules/butler-mvp-standing.mdc)). Operational checklist + CI-less validator: [`docs/knowledge/PACKAGE_RELEASE_CHECKLIST.md`](../knowledge/PACKAGE_RELEASE_CHECKLIST.md) (`dart run tool/validate_knowledge_packages.dart`). Print sign-off form: [`docs/05_VERIFICATION_AND_QA/00_KNOWLEDGE_PACKAGE_RELEASE_CHECKLIST (1).md`](../05_VERIFICATION_AND_QA/00_KNOWLEDGE_PACKAGE_RELEASE_CHECKLIST%20(1).md). Neither publishes a package.

**Phase 2 DoD**

- Before bumping washer / DW / fridge package versions: discriminators, easy-check gate, inspect polarity, safety stops, prevention lines, path-only cost rows, golden/path docs, `flutter test` with **zero** runtime LLM, and `dart run tool/validate_knowledge_packages.dart` (mechanical gates only).
- One-page per bump in `docs/qa/` (extend WASHER_PATHS / DW_PATHS / a fridge path note) — same bar as dryer trust, not 40-mode count.
- Factory import must not silently overwrite close-path **handoff vs DIY** language (Phase 1 lesson: `safeGuidanceBoundary` vs built-in steps).

**Out of scope:** runtime package fetch, cloud approval UI, auto-merge from [`knowledge_factory/prototype/`](../../knowledge_factory/prototype/README.md) (authoring templates only; no app web research).

---

## 6. Household multi-profile (if in scope)

**Version 1** listed household memory; local **homes** already ship, plus light **people** in the active home (P2-10).

**Code today:** add + switch homes (`lib/ui/profiles_picker.dart`, `AppDependencies.createHousehold` / `switchHousehold`). Tools, appliances, sessions are per **home**. People (`HouseholdMember`) share that home’s appliances, tools, and House Book; switch identity with `switchMember` / **Add person**. Sessions store `createdByUserId` as the current person. Sample reset leaves other homes alone ([`DEMO_RESET.md`](DEMO_RESET.md)). **No rename, no delete, no roles.**

**Phase 2 remaining:** rename/delete a home with a clear “this household’s repairs are removed from this device”; keep no cloud account.

**Out of scope:** accounts, sync, sharing a profile off-device (backup already exists).

---

## 7. Fridge observational-only

**fridge-core 1.0.1** is **PRIMARY** (P2-13): 8 symptoms, 9 modes, observational cooling / door / leak / ice / noise / power. Inspect on **4 / 9** modes (temps → gasket → vents → coils). Leak, ice, noise, won’t-run stay interview-only. Sealed-system / refrigerant / compressor live work are forbidden (`fridge-no-sealed-system`, `fridge-no-live-electrical`, `fridge-no-compressor-live`). Manual: [`FRIDGE_PATHS.md`](FRIDGE_PATHS.md). Tests: `test/fridge_mvp_test.dart`.

**Not in** the Phase 1 appliance table or sample home. Not a stub and not PARTIAL — no new sealed-system modes.

**Out of scope:** sealed-system repair, piercing lines, live compressor diagnostics, CV on frost patterns.

---

## 8. Value gate (honest placeholder)

P2-14: [`MONETIZATION_HOOK.md`](MONETIZATION_HOOK.md). Debug **Household Pro** toggle. Store billing is not wired. Never lock safety stops or core repair.

---

## Explicitly not Phase 2

- Phase 3 platform / domain OS / 10k factory / live AR tracking
- Re-enable AR or AI images (`locationVisualAidsEnabled` stays false)
- Ranking net formula / LLM diagnosis
- Live quotes, checkout, subscriptions
- New appliance families (HVAC, oven, etc.)
- Cloud sync of household data

---

## Suggested first three coding tickets (when un-frozen)

1. **P2-02** — “Why this question” on the active observation / inspect card (authored copy; tests on dryer no-heat + washer drain).
2. **P2-03** — Verified-outcome root cause + prevention always written and shown in history/wrap-up (Fixed and honest pro close).
3. **P2-04** — Washer drain-filter inspect polarity + any follow-on washer/DW gap that fails a phone walk of [`WASHER_PATHS.md`](WASHER_PATHS.md) / [`DW_PATHS.md`](DW_PATHS.md).

Package bumps for P2-04 go through item 5. Fridge stays scheduled until those three land.
