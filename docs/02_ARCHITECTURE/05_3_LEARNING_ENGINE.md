# MODULE 5.3 — LEARNING ENGINE

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-19  
**Authority:** Architecture Specification  

**Depends On:**  
- Design Principles  
- Module 3.6 — Reasoning Philosophy  
- Module 3.9 — Repair Philosophy  
- Module 4.0 — Repair Session Data Model  
- Module 4.1 — Evidence Data Model  
- Module 4.2 — Household Memory Data Model

---

## Purpose

The Learning Engine is responsible for improving the system over time based on verified real-world outcomes.

Its purpose is to allow The Modern Butler’s Book to become more accurate, more efficient, and more helpful as more successful repairs are completed — while strictly protecting engineering truth and user privacy.

Learning is deliberately constrained. The system must never learn from assumptions, unverified outcomes, or low-quality data.

---

## Core Principles

1. **Learn Only From Verified Outcomes**  
   Only sessions that have explicit verification of the final result may contribute to learning.

2. **Engineering Truth is Protected**  
   Core Knowledge Graph relationships and engineering principles cannot be automatically overwritten by learning. Proposed changes must be versioned and reviewable.

3. **Privacy First**  
   Personal household data never enters Community Intelligence. Only anonymized, aggregated patterns may be proposed.

4. **Reversibility**  
   All learning updates must be versioned and reversible.

5. **Separation of Concerns**  
   Learning improves ranking, question effectiveness, and prevention recommendations. It does not redefine fundamental engineering knowledge without human oversight.

---

## What the Learning Engine May Improve

- Relative ranking of failure modes for specific symptom combinations
- Effectiveness of different observation / question phrasings
- Prevention recommendation relevance
- Time and difficulty estimates
- Recognition of recurring patterns within a household (via Household Memory)
- Anonymized community patterns (after sufficient volume and quality gates)

---

## What the Learning Engine Must Never Do

- Automatically rewrite core engineering relationships in the Knowledge Graph
- Learn from sessions that lack verification
- Incorporate personal identifying information into shared models
- Reduce safety constraints based on observed user behavior
- Create new failure modes without review

---

## Learning Triggers

Learning proposals may only be generated after:

- A Repair Session has reached a verified outcome
- Root Cause Analysis has been attempted
- The user (or system) has confirmed the final result

---

## Learning Outputs

The Learning Engine produces **proposals**, not direct changes. These proposals may include:

- Suggested adjustments to failure mode ranking weights
- Suggested improvements to communication strategies
- New candidate prevention patterns
- Anonymized community statistics

All proposals are subject to quality gates and versioning before they can affect live behavior.

---

## Version History

**Version 1.0** — 2026-07-19  
Initial locked specification for the Learning Engine.

---

## Implementation Notes

The Learning Engine should be designed as a proposal-generating system rather than an automatic updater of core knowledge. This preserves long-term integrity of the engineering foundation.

This document forms part of the permanent Product Bible.

---

*This document is binding. All learning and improvement processes must respect the constraints and principles defined herein.*