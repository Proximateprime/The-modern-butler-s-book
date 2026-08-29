# MODULE 4.1 — EVIDENCE DATA MODEL

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-18  
**Authority:** Architecture Specification  
**Depends On:**  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 3.8 — Uncertainty Management & Adaptive Intelligence  
- Module 4.0 — Repair Session Data Model

---

## Purpose

This document defines the **Evidence Data Model**. Evidence is the foundational input to the entire diagnostic system.

The Butler never asks the user to diagnose. The user only provides observations. These observations are recorded as structured Evidence. All reasoning, hypothesis generation, and recommendations are derived from Evidence.

This model is critical because it enforces the principle of **Observation Before Conclusion**.

---

## Core Concepts

### Evidence
A structured record of something the user observed, measured, confirmed, or experienced during the diagnostic process.

Evidence can come from:
- User answers to questions
- User-provided descriptions (text or voice)
- Photos or videos
- Measurements (voltage, temperature, etc.)
- Results of basic condition checks
- System-detected information (when available)

### Evidence Provenance & Trust
Every Evidence record must carry information about its source and reliability (see Module 3.11).

### Evidence Lifecycle
Evidence is collected during a Repair Session and remains linked to that session. It can also be referenced by Household Memory for long-term use.

---

## Data Model

### Evidence

| Field                    | Type      | Description                                              | Required |
|--------------------------|-----------|----------------------------------------------------------|----------|
| id                       | UUID      | Unique identifier                                        | Yes      |
| session_id               | UUID      | Reference to the Repair Session                          | Yes      |
| appliance_id             | UUID      | Reference to the appliance                               | Yes      |
| evidence_type            | String    | Type of evidence (see Evidence Types below)              | Yes      |
| content                  | JSONB     | Structured content of the evidence                       | Yes      |
| raw_input                | Text      | Original user input (if applicable)                      | No       |
| source_trust_level       | Decimal   | Trust score of the source (0–1)                          | Yes      |
| source_metadata          | JSONB     | Additional trust/provenance information                  | Yes      |
| collected_at             | Timestamp | When the evidence was recorded                           | Yes      |
| collected_in_state       | String    | Which state in the state machine it was collected in     | Yes      |
| linked_knowledge_nodes   | UUID[]    | References to related Knowledge Graph nodes (optional)   | No       |

### Evidence Types

The following evidence types are supported:

| Evidence Type              | Description                                      | Example Content |
|----------------------------|--------------------------------------------------|-----------------|
| `text_observation`         | Free-text description from user                  | "Water is pooling at the bottom after the cycle" |
| `structured_answer`        | Answer to a multiple-choice or boolean question  | `{ "answer": "No", "question_id": "..." }` |
| `photo`                    | Image evidence                                   | `{ "url": "...", "description": "Lint filter" }` |
| `video`                    | Video evidence                                   | `{ "url": "...", "duration_seconds": 12 }` |
| `measurement`              | User-reported or system measurement              | `{ "type": "voltage", "value": 120, "unit": "V" }` |
| `basic_condition_check`    | Result of a basic operating condition check      | `{ "check": "door_closed", "result": true }` |
| `maintenance_record`       | Record of recent maintenance performed           | `{ "action": "cleaned_lint_trap", "date": "..." }` |
| `previous_repair`          | Reference to a past repair in Household Memory   | `{ "session_id": "..." }` |

---

## Relationships

- One **Evidence** record belongs to one **RepairSession**.
- One **Evidence** record belongs to one **Appliance**.
- Evidence can be linked to one or more nodes in the **Knowledge Graph**.
- Evidence can be referenced by **Household Memory** for long-term use.

---

## Trust and Weighting

Evidence carries trust metadata (as defined in Module 3.11). The Reasoning Engine must use this metadata when:

- Updating confidence scores
- Ranking hypotheses
- Deciding which evidence takes precedence during contradictions

Higher-trust evidence should have greater influence on conclusions.

---

## Version History

**Version 1.0** — 2026-07-18  
Initial locked specification for the Evidence Data Model.

---

## Implementation Notes

This model should be implemented early because Evidence is the primary input to the Reasoning Engine. All future reasoning logic depends on well-structured, trustworthy Evidence records.

The model must support extensibility for new evidence types as the system evolves.

---

*This document is binding. All evidence collection and processing must follow the structure and trust requirements defined herein.*