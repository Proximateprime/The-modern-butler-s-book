# MODULE 3.10 — CONFIDENCE & EXPLAINABILITY POLICY

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-18  
**Authority:** Architecture Specification  
**Depends On:**  
- Safety Invariants  
- Non-Negotiables  
- App Promise  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 3.6 — Reasoning Philosophy & Hybrid Intelligence  
- Module 3.8 — Uncertainty Management & Adaptive Intelligence

---

## Purpose

This document defines how the Butler communicates confidence and maintains explainability throughout the diagnostic process. It establishes requirements for how uncertainty is represented to the user and how the system can account for its reasoning at any point.

Clear communication of confidence and strong explainability are essential for building user trust and preventing over-reliance on the system.

This specification is binding on the Reasoning Engine, Conversation Engine, and any component that presents conclusions or recommendations to the user.

---

## Confidence Communication

The Butler must never present conclusions as absolute facts. All significant outputs must include an appropriate expression of confidence.

### Required Confidence Expressions

The system should express confidence in clear, user-friendly ways, such as:

- **Most likely:** Drain obstruction (82%)
- **Other strong possibilities:**
  - Drain pump failure (12%)
  - Float switch issue (6%)

Confidence levels should generally follow these interpretive bands:

- **Below 40%**: "Several possibilities remain likely."
- **40–60%**: "These are the most common causes based on current evidence."
- **60–75%**: "This appears to be the leading cause."
- **75–90%**: "The evidence strongly suggests..."
- **Above 90%**: "The evidence is highly consistent with..."

The Butler should **never** use language that implies absolute certainty (e.g., "This is definitely the problem" or "I'm certain").

### Confidence Traceability

Every meaningful change in confidence must be traceable to specific evidence. When asked, the system must be able to explain:

- Which pieces of evidence increased confidence in the current leading hypothesis
- Which pieces of evidence decreased confidence or supported alternative hypotheses
- Why certain hypotheses were ruled out

---

## Explainability Requirements

The Butler must support multiple levels of explainability:

### 1. Real-time Explainability
At any point during a session, the user should be able to ask “Why are you asking this?” or “Why do you think that?” and receive a clear answer.

### 2. Session History Explainability
The user must be able to request a summary of how the investigation reached its current state. This should include:

- Key observations recorded
- Important questions asked and the reasoning behind them
- How evidence affected hypothesis rankings
- How contradictions were resolved
- Why the investigation is continuing or concluding

### 3. Outcome Explainability
After a session, the user should be able to understand:

- Why a particular root cause was identified
- Why specific prevention recommendations were made
- What evidence supported the final conclusions

---

## Confidence and Decision Making

Confidence levels must influence system behavior in the following ways:

- **Low confidence (< 50%)**: The system should be cautious with guidance and may recommend additional verification or professional assistance.
- **Medium confidence (50–75%)**: The system may offer guidance but should clearly communicate remaining uncertainty.
- **High confidence (> 75%)**: The system may provide stronger recommendations while still maintaining transparency about evidence strength.

Confidence alone should never override safety constraints defined by the Risk & Safety Engine.

---

## Version History

**Version 1.0** — 2026-07-18  
Initial locked specification defining requirements for confidence communication and explainability.

---

## Implementation Notes

All user-facing outputs from the Reasoning Engine and Conversation Engine must include appropriate confidence indicators and support the explainability requirements defined in this document.

This document forms part of the permanent Product Bible.

---

*This document is binding. All handling and communication of confidence and reasoning explanations must conform to the requirements defined herein.*