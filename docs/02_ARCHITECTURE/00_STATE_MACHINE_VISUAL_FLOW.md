# STATE MACHINE VISUAL FLOW

**Status:** Implementation Aid  
**Version:** 1.0  
**Date:** 2026-07-20  

**Depends On:**  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 0.5 — Butler Reasoning Cycle

---

## Purpose

A simple visual reference for Cursor and developers.
This does not replace Module 3.5. It makes the main path easy to see.

---

## Primary Happy Path

```
Start / Idle
    ↓
Select Appliance
    ↓
Basic Condition Verification
    ↓
Collect Initial Observations
    ↓
Convert to Structured Evidence
    ↓
Generate Candidate Failure Modes
    ↓
Update Confidence
    ↓
Risk & Safety Check
    ↓
Need more evidence?
   / \
 Yes   No
  ↓     ↓
Ask next   Generate Safe Guidance
best question      ↓
  ↓         User Action
Collect evidence      ↓
  ↓         Verification
Back to confidence    ↓
                 Resolved?
                  / \
               No    Yes
                ↓     ↓
           Investigate  Root Cause
           more         ↓
                    Prevention
                        ↓
                 Update Household Memory
                        ↓
                   Session Closed
```

---

## Always-On Interrupts

At many points, these may divert the flow:

- Safety hard stop → professional recommendation
- User pauses / leaves → resumable session
- Technical failure → preserve evidence, safe message
- Insufficient knowledge → limited local guidance or escalate

---

## Implementation Note

For the 2-week MVP, not every branch needs rich behavior.
The spine of the flow must work.
Safety stops must work.
Save/resume basics must work.

---

*Use this as a map, not as permission to expand scope.*