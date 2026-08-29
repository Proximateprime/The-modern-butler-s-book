# MODULE 4.4 — REASONING DATA FLOW

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-18  
**Authority:** Architecture Specification  
**Depends On:**  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 3.6 — Reasoning Philosophy & Hybrid Intelligence  
- Module 4.0 — Repair Session Data Model  
- Module 4.1 — Evidence Data Model

---

## Purpose

This document defines the **Reasoning Data Flow** — the sequence in which data moves between components during diagnostic reasoning.

It specifies the inputs and outputs of each major step so that implementation (especially by Cursor) has clear contracts between components.

---

## Primary Reasoning Data Flow

The core diagnostic reasoning loop follows this general flow:

```
User Observation
       ↓
Evidence (structured + trust metadata)
       ↓
Knowledge Graph Query (symptoms → failure modes)
       ↓
Candidate Failure Modes + Initial Scores
       ↓
Confidence Update (incorporating Household Memory)
       ↓
Risk Evaluation
       ↓
Next Best Question Selection (Information Gain)
       ↓
New Evidence
       ↓
(Loop until stopping criteria met)
       ↓
Root Cause Analysis
       ↓
Prevention Recommendations
       ↓
Session Outcome Recording
```

---

## Detailed Step Descriptions

### 1. User Observation → Evidence
- Raw user input (text, selection, photo, etc.) is converted into structured **Evidence**.
- Evidence includes trust metadata.
- Evidence is linked to the current Repair Session and state.

### 2. Evidence → Knowledge Graph Query
- The Reasoning Engine queries the Knowledge Graph using current Evidence (especially symptoms).
- Returns relevant **Failure Modes** and relationships.

### 3. Candidate Failure Modes
- A list of possible failure modes is generated with initial association scores.
- Household Memory may adjust initial scores based on past root causes.

### 4. Confidence Update
- Confidence scores for each hypothesis are calculated/updated.
- Source trust levels and evidence strength are taken into account.
- History of confidence changes is recorded.

### 5. Risk Evaluation
- The Risk & Safety Engine evaluates current hypotheses and evidence.
- May block guidance or recommend professional service.

### 6. Question Selection
- The Conversation Engine (with input from Reasoning Engine) selects the next question with highest information gain.
- Predicted follow-up branches may be pre-computed (see Module 3.7).

### 7. New Evidence Collection
- User provides new information → new Evidence is created.
- Loop returns to step 2.

### 8. Root Cause & Prevention
- Once sufficient confidence or stopping criteria are met, root cause analysis is performed.
- Prevention recommendations are generated.

### 9. Outcome Recording
- Final outcome, root cause, and prevention recommendations are saved to the Repair Session.

---

## Key Data Objects in the Flow

- **Evidence**
- **Hypothesis** (with confidence)
- **Failure Mode** (from Knowledge Graph)
- **Risk Assessment**
- **Question**
- **Session State**
- **Root Cause Record**
- **Prevention Recommendation**

---

## Version History

**Version 1.0** — 2026-07-18  
Initial locked specification of the Reasoning Data Flow.

---

## Implementation Notes

This data flow should be used as the foundation when implementing the interaction between the Reasoning Engine, Evidence Engine, Conversation Engine, and State Machine Controller.

Clear interfaces should be defined between each step to avoid tight coupling.

---

*This document is binding. All reasoning-related data movement must follow the flow and object contracts defined herein.*