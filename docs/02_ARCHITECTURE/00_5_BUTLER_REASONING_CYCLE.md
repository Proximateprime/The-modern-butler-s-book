# MODULE 0.5 — THE BUTLER REASONING CYCLE
## System Execution Flow

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-19  
**Authority:** Architecture Specification  

**Depends On:**  
- Design Principles  
- Module 3.5 — Diagnostic Workflow & State Machine  
- All major engines (Reasoning, Evidence, Conversation, Risk, Confidence, etc.)

---

## Purpose

This document provides the single high-level view of how The Modern Butler’s Book works from end to end.

It answers the question:

> “How does the whole system actually run?”

Detailed behavior of individual engines is defined in their own modules.  
This document shows **when** those engines are used and **how** they fit together in a normal diagnostic session.

---

## The Butler Reasoning Cycle

```
1. User starts a session and selects an appliance
          ↓
2. Basic Condition Verification
          ↓
3. Collect Initial Observations
          ↓
4. Structure observations into Evidence
          ↓
5. Query Knowledge Graph for candidate Failure Modes
          ↓
6. Rank hypotheses + calculate initial confidence
          ↓
7. Risk & Safety evaluation
          ↓
8. Decide: enough confidence to guide, or need more evidence?
          ↓
     ┌────┴────┐
     │         │
   Need more   Enough
   evidence    confidence
     │         │
     ▼         ▼
9a. Select next     10. Generate Safe Guidance
    highest-value         ↓
    observation      11. User performs action
    request               ↓
     │               12. Verification
     ▼                    ↓
9b. Present request  13. Resolved?
    to user               │
     │               ┌────┴────┐
     ▼               No       Yes
9c. Collect new           │        │
    Evidence              │        ▼
     │                    │   14. Root Cause Analysis
     └──────► back to 6   │        ↓
                          │   15. Prevention Recommendations
                          │        ↓
                          │   16. Update Household Memory
                          │        ↓
                          │   17. (Optional) Learning Candidate
                          │        ↓
                          └─► 18. Session Closed / Archived
```

---

## Key Control Points

### When Confidence Is Evaluated
- After every new piece of Evidence is accepted
- Before deciding whether to ask another question or issue guidance
- Before finalizing Root Cause

### When Risk & Safety Is Evaluated
- Before any guidance is shown to the user
- When a new high-risk hypothesis becomes leading
- Whenever the user is about to perform a physical action

### When Household Memory Is Queried
- Early in the session (to surface relevant history)
- During hypothesis ranking
- When generating Prevention Recommendations

### When Explainability Is Available
- At any time the user asks “Why?”
- Automatically when the system makes a significant decision (optional)

---

## Relationship to the State Machine

This Reasoning Cycle operates inside the states defined in Module 3.5 (Diagnostic Workflow & State Machine).  

The State Machine controls *which phase* the session is in.  
This document describes the *logical flow of reasoning and evidence* that happens across those phases.

---

## Design Intent

This cycle exists so that:

- A new developer can understand the overall system quickly
- Cursor has a clear top-level reference instead of inventing flow
- Individual engines know when they are expected to run
- The separation between “what evidence is needed” and “how to ask for it” remains clear

---

## Version History

**Version 1.0** — 2026-07-19  
Initial locked System Execution Flow / Butler Reasoning Cycle.

---

*This document is the recommended high-level entry point for understanding how the entire diagnostic system operates.*