# ENGINEERING SIMPLIFICATIONS — LOCKED

**Status:** Locked Engineering Decision  
**Version:** 1.0  
**Date:** 2026-07-21  
**Authority:** Architecture → Implementation Bridge  

**Depends On:**  
- Design Principles  
- Module 0.5 — Butler Reasoning Cycle  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 3.6 — Reasoning Philosophy  
- Module 5.1 — Risk & Safety Engine  
- Module 5.2 — Engine Orchestration Layer  
- Module 5.5 — Confidence & Decision Engine  
- Module 5.5C — Question Selection Algorithm  
- Module 8.0 — Local-First Knowledge Package Architecture  

---

## Purpose

These simplifications reduce complexity, eliminate duplicated state, and tighten contracts between engines **without changing any user-facing behavior**.

They are permanent implementation rules. Cursor and all future developers must follow them.

---

## Locked Rules

### 1. DecisionContext (Shared State)

All engines that need current diagnostic state must read from a single shared `DecisionContext` object.

No engine may maintain its own private copy of:
- Active hypotheses and confidence scores
- Current safety level
- Investigation status
- Expected information gain
- User skill / tool context

**Engineering Rule:**  
Any runtime state required by more than one engine must live in `DecisionContext` rather than being duplicated across engines.

`DecisionContext` should be organized (not a flat God Object). Recommended top-level groups:
- Evidence
- Hypotheses
- Safety
- User
- Session
- Tools

### 2. SessionOutcome Projection

Root Cause, Contributing Factors, and Prevention Recommendations are fields (or derived views) of a single `SessionOutcome` record.

There is no separate Root Cause Engine or Prevention Engine at runtime.  
Prevention is simply a projection of the Outcome + relevant Household Memory.

### 3. EvidenceRequest Contract

The Reasoning layer only emits a strict `EvidenceRequest`.

The Conversation / Evidence Acquisition layer only consumes that request and produces the human interaction.

There is no negotiation or duplicated responsibility between the two layers.

### 4. Single Stopping Function

There is one authoritative function:

```text
should_continue_investigation(DecisionContext) → boolean
```

All paths that need to decide whether to ask another question or issue guidance must call this function.  
Stopping logic is not allowed to be re-implemented in multiple places.

### 5. Runtime Knowledge Surface

At diagnosis time the system only ever sees:
- The currently loaded Knowledge Package(s)
- Household Memory

The full Knowledge Graph exists only for authoring and packaging.  
Runtime never queries a global Knowledge Graph.

### 6. Safety Validator (Final Gate)

**No user-visible guidance, regardless of how it was generated, may bypass the deterministic Safety Validator.**

This rule applies whether the guidance was produced by:
- An LLM
- A local model
- A template
- A rule-based generator
- Any future source

The Safety Validator has the final word on every message that reaches the user.

### 7. Confidence Display (MVP)

During questioning → no confidence is shown to the user.

At diagnosis / recommendation points → only three bands are shown:
- Low
- Medium
- High

Exact numeric confidence remains internal until real calibration data exists.  
Never display false precision (e.g. “74%”, “81%”).

---

## Implementation Notes for Cursor

1. Create a shared `DecisionContext` type early. All engines that need state must accept it as input rather than reconstructing it.
2. Make `SessionOutcome` the single source of truth for root cause + prevention data.
3. Define a clear `EvidenceRequest` interface. Reasoning produces it; Conversation consumes it.
4. Implement `should_continue_investigation()` as a pure function of `DecisionContext`.
5. Ensure the Safety Validator runs after any content generation and before the user sees the message.
6. Keep confidence bands simple for the first version.

---

## Why These Rules Exist

These changes remove duplicated decision logic, tighten engine contracts, make testing easier, and reduce the chance of divergent behavior between engines.

They do not add features. They make the existing system cleaner and harder to break.

---

## Version History

**Version 1.0** — 2026-07-21  
Initial locked set of engineering simplifications after the pre-Cursor refinement pass.

---

*These rules are binding for all implementation work.*
