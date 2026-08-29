# Phase 2 exit checklist

Candidate **2026-08-22**. App **0.1.0+1**. APK: [`BUILD_NOTES_PHASE2.md`](BUILD_NOTES_PHASE2.md). Testers: [`TESTER_BRIEF_PHASE2.md`](TESTER_BRIEF_PHASE2.md). Plan: [`PHASE2_PLAN.md`](PHASE2_PLAN.md).

| Mark | Meaning |
|---|---|
| **DONE** | Shipped in this candidate with tests or a manual script. |
| **PARTIAL** | Shipped with an honest gap (stub, docs-only, or DoD not fully met). |
| **SKIPPED** | Not in this candidate. |

**Overall: PARTIAL.** Core retention tickets landed. P2-07 (dryer no-heat quality pass) was not done. Sample home still has no dishwasher/fridge. Store billing is a debug toggle. Home rename/delete is not built. No Phase 3.

Frozen product definition: [`docs/MVP_DEFINITION.md`](../MVP_DEFINITION.md).

---

## Tickets

| ID | Work | Status | Notes |
|---|---|---|---|
| P2-01 | Phase 2 plan | **DONE** | [`PHASE2_PLAN.md`](PHASE2_PLAN.md) |
| P2-02 | Root cause / prevention on **Fixed** | **PARTIAL** | Chips + history `Prevent:` / `Also:` on Fixed. Professional / not-fixed / stopped still skip memory chips (handoff exists). [`REPAIR_HISTORY.md`](REPAIR_HISTORY.md) |
| P2-03 | Why ask this? | **DONE** | Interview + inspect. Authored splits, no LLM. [`REGRESSION_PHASE2.md`](REGRESSION_PHASE2.md) §H |
| P2-04 | Confidence display | **DONE** | Standing phrases, no `%`. Hidden on early questions |
| P2-05 | Package release checklist | **DONE** | Authoring gate. Does not auto-publish |
| P2-06 | Regression scenarios as data | **DONE** | [`scenarios/README.md`](scenarios/README.md) |
| P2-07 | Dryer no-heat knowledge quality pass | **SKIPPED** | Not implemented this cycle |
| P2-08 | Knowledge Factory prototype | **PARTIAL** | Authoring-only under `knowledge_factory/prototype/`. Not in the app runtime |
| P2-09 | Washer / DW second pass | **DONE** | `washer-core` / `dishwasher-core` **0.2.3**. Won’t-spin inspect and DW no-power look still out |
| P2-10 | Light household members | **DONE** | People in a home; homes still isolate. No rename/delete/roles |
| P2-11 | Pattern hints | **DONE** | N=2, vent / drain-filter / coils. Sample home must not hint. [`REGRESSION_PHASE2.md`](REGRESSION_PHASE2.md) §K |
| P2-12 | Repair readiness vs inventory | **DONE** | **In your tools** / **Not in your tools**. [`REGRESSION_PHASE2.md`](REGRESSION_PHASE2.md) §J |
| P2-13 | Fridge observational | **DONE** | `fridge-core` **1.0.1** PRIMARY. Manual [`FRIDGE_PATHS.md`](FRIDGE_PATHS.md). Not in sample home |
| P2-14 | Value gate placeholder | **PARTIAL** | Debug **Household Pro**. No Store IAP. Safety never paywalled. [`MONETIZATION_HOOK.md`](MONETIZATION_HOOK.md) |
| P2-15 | Phase 2 candidate build | **DONE** | This checklist + APK + Phase 2 regression/brief/build notes |

---

## Frozen / out of Phase 2 (must stay NO)

| Item | Status |
|---|---|
| Ranking algorithm rewrite / LLM diagnosis | **NO** |
| Live AR / AI-generated part images / CV | **NO** (`locationVisualAidsEnabled` false) |
| Public knowledge platform / domain OS / 10k factory | **NO** |
| Runtime web research | **NO** |
| Beginner gas / sealed-system / live-electrical how-to | **NO** |
| Live quotes / checkout / subscriptions | **NO** |
| Cloud sync of household data | **NO** |

---

## Exit bar for testers

Phone or emulator: [`REGRESSION_PHASE1.md`](REGRESSION_PHASE1.md) then [`REGRESSION_PHASE2.md`](REGRESSION_PHASE2.md). File crashes and safety leaks; do not file [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md).
