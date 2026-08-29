# MODULE 4.0 — REPAIR SESSION DATA MODEL

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-18  
**Authority:** Architecture Specification  
**Depends On:**  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 3.9 — Repair Philosophy

---

## Purpose

This document defines the core data model for a **Repair Session**. The Repair Session is the central entity around which all diagnostic activity, evidence, reasoning, and outcomes revolve.

Every observation, question, hypothesis, state transition, verification, root cause, and prevention recommendation must be recorded within the context of a Repair Session.

This model is foundational. All other data models (Evidence, Household Memory, etc.) connect to or reference the Repair Session.

---

## Core Concepts

### Repair Session
A Repair Session represents a single troubleshooting and repair interaction between the user and the Butler for one appliance.

**Key Characteristics:**
- One Repair Session is tied to exactly one Appliance.
- A session follows the state machine defined in Module 3.5.
- A session records all evidence, hypotheses, actions, and outcomes.
- A session ends only when it reaches the `Session Closed` state.

### Session State History
The system must maintain a chronological record of state transitions during the session. This enables explainability and allows the session to be resumed or audited.

### Evidence Collection
All evidence gathered during the session (observations, answers, photos, measurements) must be linked to the Repair Session.

### Hypothesis Tracking
Active and historical hypotheses, along with their confidence scores over time, must be recorded within the session.

---

## Data Model

### RepairSession

| Field                    | Type          | Description                                      | Required |
|--------------------------|---------------|--------------------------------------------------|----------|
| id                       | UUID          | Unique identifier                                | Yes      |
| appliance_id             | UUID          | Reference to the appliance being diagnosed       | Yes      |
| household_id             | UUID          | Reference to the household                       | Yes      |
| current_state            | String        | Current state from the diagnostic state machine  | Yes      |
| started_at               | Timestamp     | When the session began                           | Yes      |
| last_activity_at         | Timestamp     | Last time the session was active                 | Yes      |
| ended_at                 | Timestamp     | When the session was closed                      | No       |
| resolution_status        | String        | Resolved / Partially Resolved / Unresolved       | No       |
| user_goal                | String        | User's stated goal (if provided)                 | No       |
| created_by_user_id       | UUID          | User who started the session                     | Yes      |

### SessionStateHistory

| Field               | Type      | Description                              |
|---------------------|-----------|------------------------------------------|
| id                  | UUID      | Unique identifier                        |
| session_id          | UUID      | Reference to RepairSession               |
| state               | String    | State name from the state machine        |
| entered_at          | Timestamp | When the state was entered               |
| exited_at           | Timestamp | When the state was exited                |
| reason_for_transition | String  | Why the transition occurred              |
| triggered_by        | String    | User / System / Safety Engine            |

### SessionHypothesis

| Field                  | Type      | Description                                      |
|------------------------|-----------|--------------------------------------------------|
| id                     | UUID      | Unique identifier                                |
| session_id             | UUID      | Reference to RepairSession                       |
| failure_mode_id        | UUID      | Reference to Knowledge Graph failure mode        |
| confidence             | Decimal   | Current confidence score (0–1)                   |
| rank                   | Integer   | Current ranking among hypotheses                 |
| first_considered_at    | Timestamp | When this hypothesis first appeared              |
| last_updated_at        | Timestamp | Last time confidence or rank changed             |
| status                 | String    | Active / Ruled Out / Leading / Resolved          |

### SessionEvidenceLink

| Field             | Type    | Description                                      |
|-------------------|---------|--------------------------------------------------|
| id                | UUID    | Unique identifier                                |
| session_id        | UUID    | Reference to RepairSession                       |
| evidence_id       | UUID    | Reference to Evidence record                     |
| added_at          | Timestamp | When this evidence was linked to the session   |
| source_state      | String  | Which state the evidence was collected in        |

### SessionOutcome

| Field                        | Type      | Description                                      |
|------------------------------|-----------|--------------------------------------------------|
| id                           | UUID      | Unique identifier                                |
| session_id                   | UUID      | Reference to RepairSession                       |
| immediate_cause              | Text      | What directly failed                             |
| root_cause                   | Text      | Why the failure occurred                         |
| contributing_factors         | JSONB     | Additional factors that contributed              |
| resolution_status            | String    | Resolved / Partially Resolved / Unresolved       |
| root_cause_confidence        | Decimal   | Confidence in root cause determination           |
| determined_at                | Timestamp | When root cause was recorded                     |

### SessionPreventionRecommendation

| Field                  | Type      | Description                                      |
|------------------------|-----------|--------------------------------------------------|
| id                     | UUID      | Unique identifier                                |
| session_id             | UUID      | Reference to RepairSession                       |
| recommendation_text    | Text      | Specific prevention advice                       |
| category               | String    | Maintenance / Behavior Change / Inspection       |
| priority               | String    | High / Medium / Low                              |
| based_on_root_cause    | Boolean   | Whether this is directly tied to root cause      |
| created_at             | Timestamp | When the recommendation was generated            |

---

## Relationships

- One **RepairSession** belongs to one **Appliance**.
- One **RepairSession** has many **SessionStateHistory** records.
- One **RepairSession** has many **SessionHypothesis** records.
- One **RepairSession** has many **SessionEvidenceLink** records.
- One **RepairSession** has zero or one **SessionOutcome**.
- One **RepairSession** has many **SessionPreventionRecommendation** records.

---

## Lifecycle

A Repair Session moves through the states defined in Module 3.5. The data model must support:

- Starting a new session
- Recording state transitions
- Accumulating evidence and hypotheses over time
- Recording final outcome and prevention recommendations
- Allowing session resumption after interruption
- Maintaining full auditability for explainability

---

## Version History

**Version 1.0** — 2026-07-18  
Initial locked specification for the Repair Session data model.

---

## Implementation Notes

This model should be implemented early as it serves as the backbone for the diagnostic system. All evidence, reasoning, and outcomes must be associated with a Repair Session.

Future modules (especially Evidence Model and Household Memory) will reference this model.

---

*This document is binding. The Repair Session data model must support all states, evidence collection, hypothesis tracking, root cause analysis, and prevention requirements defined in Modules 3.5 and 3.9.*