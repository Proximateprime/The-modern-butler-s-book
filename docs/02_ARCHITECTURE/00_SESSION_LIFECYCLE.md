# SESSION LIFECYCLE

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-21  
**Authority:** Implementation Reference  

This document defines the legal life of a Repair Session from creation to terminal state.  
All engines and UI flows must respect these states and transitions.

---

## Primary Happy Path

```
New Session
    ↓
Appliance Selected
    ↓
Knowledge Package Loaded
    ↓
Diagnosis Active
    ↓
Guidance / Repair Direction
    ↓
Verification
    ↓
Outcome Recorded
    ↓
Household Memory Updated
    ↓
Closed
```

---

## Core States

| State | Meaning |
|-------|---------|
| `New` | Session created, appliance not yet confirmed |
| `ApplianceSelected` | Appliance chosen, package not yet loaded |
| `KnowledgeLoading` | Package download / open in progress |
| `KnowledgeReady` | Package loaded and validated |
| `DiagnosisActive` | Asking questions / collecting evidence |
| `GuidanceIssued` | Safe guidance or repair direction has been given |
| `Verification` | Checking whether the guidance worked |
| `OutcomePending` | Terminal result being written |
| `Closed` | Terminal state reached and memory updated |
| `Escalated` | Hard stop or professional escalation |
| `Unexpected` | Unexpected Outcome path entered |
| `Abandoned` | User left without reaching a terminal engineering outcome |
| `Error` | Unrecoverable session error |

---

## Legal Transitions (Simplified)

- `New` → `ApplianceSelected`
- `ApplianceSelected` → `KnowledgeLoading` → `KnowledgeReady` or `Error`
- `KnowledgeReady` → `DiagnosisActive`
- `DiagnosisActive` → `DiagnosisActive` (more evidence)
- `DiagnosisActive` → `GuidanceIssued`
- `DiagnosisActive` → `Escalated`
- `GuidanceIssued` → `Verification` or `DiagnosisActive` (if guidance was only a check)
- `Verification` → `OutcomePending` or `DiagnosisActive` or `Unexpected`
- `OutcomePending` → `Closed`
- Any active state → `Abandoned` (user quits)
- Any active state → `Error` (unrecoverable)
- `DiagnosisActive` / `GuidanceIssued` / `Verification` → `Unexpected` when criteria met

---

## Special Paths

### Resume
A session in `DiagnosisActive`, `GuidanceIssued`, or equivalent non-terminal state may be resumed.  
On resume the system must:
- Reload the correct package version used by the session
- Re-validate critical evidence for staleness where required
- Restore DecisionContext (or rebuild it deterministically from stored evidence)

### Crash / Kill Recovery
If the app is killed:
- On next launch the session may return to the last safely persisted state
- No safety-critical decision may be assumed complete unless it was persisted

### Unexpected Outcome
When entered:
- Session moves toward an Unexpected Outcome record
- Engineering incident workflow may be triggered
- User communication follows the Unexpected Outcome / Incident policies

### User Quits
- Session becomes `Abandoned` or is moved to a soft-abandoned state
- Partial evidence may still be retained according to privacy and learning rules
- Household Memory is not updated with a success claim

### Professional Escalation
- Session may terminate as `Escalated`
- Clear reason codes must be stored
- User is left with clear next steps

### Partial Success
- Allowed as a form of Outcome (or a sub-status of Success)
- Must be recorded honestly (what improved vs what remains)

### Failure / Unresolved
- Terminal state when the system cannot reach a verified success and is not treating it as Unexpected Outcome
- Must still produce a clean SessionOutcome

---

## Terminal States (Exactly One)

Every session must eventually reach exactly one terminal engineering state:

- `Success` (including partial success variants if modeled)
- `Unresolved`
- `Unexpected Outcome`
- `Escalated` (may be modeled as a form of Unresolved or separate)
- `Abandoned` (may be excluded from engineering learning)

Rules:
- Exactly one terminal outcome record per finished session
- Household Memory updates occur only from appropriate terminal states
- Learning systems only consume verified or explicitly qualified outcomes

---

## Invariants

1. A session is always bound to one primary appliance.
2. A session records the exact Knowledge Package version used.
3. Safety stops can move a session to Escalated from most active states.
4. No terminal success may be recorded without passing through the defined outcome path.
5. Resume must never invent evidence that was not previously recorded.
6. Crash recovery must prefer safety and honesty over continuity.

---

## Version History

**Version 1.0** — 2026-07-21  
Initial locked Session Lifecycle for implementation.