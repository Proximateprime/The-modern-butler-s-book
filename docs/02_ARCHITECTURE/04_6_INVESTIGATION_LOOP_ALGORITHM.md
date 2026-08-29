# MODULE 4.6 — INVESTIGATION LOOP ALGORITHM

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-18  
**Authority:** Architecture Specification  
**Depends On:**  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 3.6 — Reasoning Philosophy & Hybrid Intelligence  
- Module 4.4 — Reasoning Data Flow  
- Module 4.5 — Question Generation Model

---

## Purpose

This document defines the **Investigation Loop Algorithm** — the core iterative process the Butler uses to gather evidence and refine hypotheses until it can safely provide guidance or reach a conclusion.

This is one of the central algorithms of the diagnostic system.

---

## Investigation Loop

The core loop operates as follows:

```
while (confidence is insufficient AND stopping criteria not met) {

    1. Select highest-value safe question
       (using Question Generation Model)

    2. Present question to user
       (via Conversation Engine)

    3. Collect new Evidence
       (update Evidence records)

    4. Update active Hypotheses and Confidence scores
       (Reasoning Engine)

    5. Perform Risk Evaluation
       (Risk & Safety Engine)

    6. Check Stopping Criteria
       - Sufficient confidence reached?
       - Safety constraint triggered?
       - Diminishing returns?
       - User requests to stop?

    7. If stopping criteria met → exit loop
       Else → repeat from step 1
}
```

---

## Stopping Criteria

The loop should terminate when one or more of the following are true:

- A hypothesis reaches high confidence and passes risk evaluation
- Multiple hypotheses remain with similar probability and further questions have low information gain
- Safety constraints prevent further investigation
- User explicitly wants to stop or seek professional help
- Available evidence has been exhausted

When the loop exits, the system moves to Root Cause Analysis or Safe Guidance (as defined in Module 3.5).

---

## Integration with State Machine

This algorithm primarily operates inside the **Adaptive Question Selection & Evidence Collection** state but can influence transitions to other states (Risk Evaluation, Generate Safe Guidance, etc.).

---

## Version History

**Version 1.0** — 2026-07-18  
Initial locked specification for the Investigation Loop Algorithm.

---

## Implementation Notes

This algorithm should be implemented as the central control flow for the diagnostic reasoning process. It must respect all constraints from the State Machine (Module 3.5) and Question Generation Model (Module 4.5).

---

*This document is binding. The core diagnostic investigation process must follow this loop structure and stopping criteria.*