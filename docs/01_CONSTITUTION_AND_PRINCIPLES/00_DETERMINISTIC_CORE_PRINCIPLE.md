# DETERMINISTIC CORE PRINCIPLE

**Status:** Locked Engineering Principle  
**Version:** 1.0  
**Date:** 2026-07-21  
**Authority:** Foundational  

---

## Principle

All diagnostic reasoning, confidence updates, safety decisions, question selection, and investigation flow shall be **deterministic** and fully testable without requiring an LLM.

Language models may improve communication, explanation, and user interaction, but they shall never be the sole source of diagnostic logic or safety-critical decisions.

---

## What This Means in Practice

- Given the same DecisionContext, Evidence set, and Knowledge Package, the system must always produce the same next EvidenceRequest, confidence change, safety decision, and stop/continue decision.
- Unit tests and regression tests must be able to run completely offline with zero model calls.
- The LLM is allowed only after the deterministic core has already decided *what* should happen. Its job is limited to natural language phrasing and explanation.

---

## Why This Principle Exists

Safety-critical and trust-critical behavior cannot depend on non-deterministic model outputs.  
This principle protects the product from silent regression, untestable logic, and unpredictable safety failures.

---

## Version History

**Version 1.0** — 2026-07-21  
Elevated from QA recommendation to locked engineering principle.

---

*This principle is binding for all future implementation.*
