# DETERMINISM POLICY

**Status:** Locked Engineering Decision  
**Version:** 1.0  
**Date:** 2026-07-20  
**Authority:** Engineering Specification  

**Depends On:**  
- Module 3.6 — Reasoning Philosophy  
- Module 5.5 / 5.5B / 5.5C — Confidence & Question Selection  
- Engineering Principles — AI Cost & Local-First

---

## Purpose

This document defines which parts of the Butler’s behavior must be deterministic and which parts may legitimately vary.

This is essential for testing, debugging, user trust, and cost control.

---

## Deterministic (Must Not Vary Across Identical Runs)

The following must produce the same results given the same inputs:

- Candidate failure mode retrieval from the Knowledge Graph
- Confidence score calculations
- Question selection ranking (utility scores)
- Safety gate decisions
- Core diagnostic state transitions
- Structured evidence interpretation results

These systems form the diagnostic backbone and must be stable and testable.

---

## Non-Deterministic (May Vary)

The following may legitimately vary:

- Natural language phrasing of questions and explanations
- Tone and wording of educational content
- Minor variations in how the same idea is expressed

The meaning and diagnostic intent must remain consistent even if the exact wording changes.

---

## Design Intent

- Diagnostic reasoning stays predictable and testable
- Communication can remain natural and human
- Regression testing of core logic remains possible
- Users are not surprised by changing diagnostic conclusions for the same evidence

---

## Version History

**Version 1.0** — 2026-07-20  
Initial locked Determinism Policy.

---

*This document is binding. Core diagnostic behavior must remain deterministic.*