# TEST CORPUS SPECIFICATION

**Status:** Implementation Specification  
**Version:** 1.0  
**Date:** 2026-07-20  
**Authority:** Engineering Specification  

**Depends On:**  
- Module 5.8 — Validation & Simulation Framework  
- Module 0.5 — Butler Reasoning Cycle  
- Diagnostic Trace Format

---

## Purpose

This document requires a canonical suite of reference diagnostic scenarios that can be used to test the reasoning system.

These scenarios act as the equivalent of unit/regression tests for diagnostic behavior.

---

## What a Test Scenario Should Include

- Appliance context
- Sequence of user observations / evidence
- Expected major questions or question categories
- Expected leading hypotheses at key stages
- Expected safety behavior
- Expected final outcome category (guidance, escalation, root cause direction)
- Notes on acceptable variation

---

## Design Intent

A shared test corpus makes it possible to detect regressions when:

- Knowledge is updated
- Ranking logic changes
- Confidence thresholds change
- Question selection logic is modified

---

## Version History

**Version 1.0** — 2026-07-20  
Initial specification for a canonical diagnostic test corpus.

---

*This document requires the creation and maintenance of reference diagnostic scenarios for validation.*