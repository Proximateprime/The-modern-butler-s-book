# ERROR TAXONOMY

**Status:** Implementation Specification  
**Version:** 1.0  
**Date:** 2026-07-20  
**Authority:** Engineering Specification  

**Depends On:**  
- Module 5.12 — Failure Recovery  
- Module 5.2 — Engine Orchestration Layer

---

## Purpose

This document requires a shared classification of errors so that logging, recovery, analytics, and support remain consistent.

---

## Example Error Categories

- Knowledge errors (missing or conflicting graph data)
- Reasoning errors
- Evidence conflicts / contradictory observations
- Communication / LLM failures
- Missing required evidence
- User cancellation / abandonment
- Safety interventions
- Infrastructure / network failures
- Storage / sync failures
- Authorization / quota / abuse limits

---

## Design Intent

A shared taxonomy prevents every engine from inventing its own error language and makes operational behavior more coherent.

---

## Version History

**Version 1.0** — 2026-07-20  
Initial requirement for a shared error taxonomy.

---

*This document establishes the need for standardized error classification across the system.*