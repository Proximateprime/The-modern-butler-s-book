# TEST SCENARIO SPECIFICATION

**Status:** Locked Implementation Specification  
**Version:** 1.0  
**Date:** 2026-07-21  
**Authority:** QA / Reliability  

**Depends On:**  
- Deterministic Core Principle  
- Engineering Simplifications (DecisionContext, EvidenceRequest, should_continue_investigation)  
- Module 8.0 — Local-First Knowledge Package Architecture  

---

## Purpose

This document defines the official language for writing diagnostic test scenarios for The Modern Butler’s Book.

Every regression test, golden path, failure case, and Knowledge Package validation shall use this format.

The goal is that any engineer (or Cursor) can write, run, and understand a test without ambiguity.

---

## Scenario Format

```yaml
Scenario ID: DRYER-001
Title: No heat with spinning drum – basic path
Package: Dryer Electric Universal v2.0
Initial State:
  Appliance: Electric Dryer
  Session: New

User Reports:
  - Drum spins
  - No heat

Evidence Sequence:
  - type: structured_answer
    question: "Does the dryer start when you press the button?"
    answer: "Yes"
  - type: structured_answer
    question: "Does the drum turn?"
    answer: "Yes"
  - type: structured_answer
    question: "Is there any heat at all after a few minutes?"
    answer: "No"
  - type: structured_answer
    question: "Is the lint filter clean?"
    answer: "Yes"
  - type: structured_answer
    question: "At the outside vent, is the airflow strong while running?"
    answer: "Weak"

Expected Next Action:
  type: EvidenceRequest
  needed: "Check for restricted vent / further airflow confirmation or thermal protection history"
  # or
  type: Guidance
  content: "Clean the exterior vent and lint pathway..."
  # or
  type: Stop
  reason: "Sufficient confidence for safe guidance"

Expected Safety Decision: Continue (Low/Moderate risk)

Expected Confidence Band: Medium → High (after airflow evidence)

Notes:
  - Must not recommend live electrical testing
  - Must treat thermal fuse as possible secondary symptom
```

---

## Required Fields

- Scenario ID (unique, stable)
- Title
- Package (exact version)
- User Reports (initial symptoms)
- Evidence Sequence (ordered)
- Expected Next Action (EvidenceRequest / Guidance / Stop / Escalate)
- Expected Safety Decision
- Notes (any special constraints)

Optional but recommended:
- Expected Confidence Band after each major step
- Expected Root Cause if the scenario reaches completion
- Tags (e.g. safety-critical, resume, contradiction)

---

## Rules for Writing Scenarios

1. Scenarios must be fully deterministic. No “the LLM might say…”.
2. Every Expected Next Action must be something the deterministic core can produce.
3. Safety-critical paths must have explicit Expected Safety Decision.
4. Prefer short, focused scenarios over giant end-to-end stories.
5. Use real-world language in User Reports and answers.

---

## How Scenarios Are Used

- Unit / integration tests of Reasoning, Confidence, Question Selection, and Safety
- Regression suite when a Knowledge Package is updated
- Validation that a new package does not break existing behavior
- Golden path verification before release

---

## Version History

**Version 1.0** — 2026-07-21  
Initial locked Test Scenario Specification.

---

*All future diagnostic tests must follow this format.*
