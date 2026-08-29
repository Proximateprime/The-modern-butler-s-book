# MODULE 6.1 — EVIDENCE PROVENANCE

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-19  
**Authority:** Architecture Specification  

**Depends On:**  
- Module 4.1 — Evidence Data Model  
- Module 3.11 — Knowledge Trust & Evidence Ranking Specification

---

## Purpose

Every piece of Evidence must carry a clear and permanent record of its origin.

This document defines the provenance requirements that make explainability, trust weighting, and auditing possible.

---

## Required Provenance Information

Every Evidence record must be able to answer:

- **Who or what produced this evidence?** (User, Camera, Sensor, Manual, Community, System inference, etc.)
- **When was it collected?**
- **In which diagnostic state was it collected?**
- **What was the original form of the input?** (text, photo, selection, measurement, etc.)
- **What is the assessed trust level of this source?**
- **Has this evidence been verified or contradicted later in the session?**

---

## Provenance Categories (Examples)

- Direct user observation
- User-submitted photo / video
- Structured answer to a system question
- Basic condition check result
- Household Memory reference
- Manufacturer documentation
- Verified community report
- System-derived / inferred (must be clearly marked as such)

---

## Rules

- Provenance must be immutable once the evidence is accepted.
- Inferred evidence must never be presented as direct observation.
- Provenance must be available for explainability (“Why do you believe this?”).

---

## Version History

**Version 1.0** — 2026-07-19  
Initial locked specification for Evidence Provenance.

---

*This document is binding. All Evidence must carry permanent provenance information as defined herein.*