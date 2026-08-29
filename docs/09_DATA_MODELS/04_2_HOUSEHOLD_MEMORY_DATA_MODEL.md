# MODULE 4.2 — HOUSEHOLD MEMORY DATA MODEL

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-18  
**Authority:** Architecture Specification  
**Depends On:**  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 3.9 — Repair Philosophy  
- Module 4.0 — Repair Session Data Model

---

## Purpose

This document defines the **Household Memory Data Model**. Household Memory is what transforms the Butler from a generic diagnostic tool into a personalized, long-term household assistant.

It stores historical information about appliances, past repairs, root causes, and maintenance actions so the system can provide better context, improved prevention recommendations, and more intelligent question ordering over time.

---

## Core Concepts

### Household Memory
A collection of historical records associated with a household and its appliances. It includes:

- Past repair sessions and their outcomes
- Root causes identified in previous repairs
- Maintenance actions performed
- Recurring patterns and issues

### Root Cause History
Past root causes should be queryable so the system can recognize similar situations and adjust reasoning accordingly.

### Maintenance History
Records of routine maintenance (vent cleaning, filter changes, descaling, etc.) that can inform both diagnostics and predictive maintenance.

---

## Data Model

### MaintenanceRecord

| Field                  | Type      | Description                                      | Required |
|------------------------|-----------|--------------------------------------------------|----------|
| id                     | UUID      | Unique identifier                                | Yes      |
| appliance_id           | UUID      | Reference to the appliance                       | Yes      |
| household_id           | UUID      | Reference to the household                       | Yes      |
| maintenance_type       | String    | Type of maintenance performed                    | Yes      |
| performed_at           | Timestamp | When the maintenance was done                    | Yes      |
| notes                  | Text      | Additional details                               | No       |
| performed_by           | String    | User or professional                             | No       |
| source                 | String    | How this record was created (user / system)      | Yes      |

### RootCauseHistory

| Field                     | Type      | Description                                      |
|---------------------------|-----------|--------------------------------------------------|
| id                        | UUID      | Unique identifier                                |
| appliance_id              | UUID      | Reference to the appliance                       |
| household_id              | UUID      | Reference to the household                       |
| original_session_id       | UUID      | Reference to the Repair Session where it was identified |
| immediate_cause           | Text      | What directly failed                             |
| root_cause                | Text      | Why it failed                                    |
| contributing_factors      | JSONB     | Additional contributing factors                  |
| occurred_at               | Timestamp | When the failure occurred                        |
| recorded_at               | Timestamp | When this record was created                     |

### RecurringIssuePattern (Derived / Computed)

This can be a materialized view or computed on demand. It tracks patterns such as:

- Repeated lint buildup on a specific dryer
- Repeated dirty condenser coils on a refrigerator
- Repeated filter clogs on a dishwasher

These patterns support predictive maintenance features.

---

## Relationships

- **MaintenanceRecord** belongs to one **Appliance** and one **Household**.
- **RootCauseHistory** belongs to one **Appliance** and one **Household**.
- Both can be referenced by future **RepairSession** records for context.

---

## Usage in Reasoning

Household Memory should be consulted during:

- **Appliance Selection** and early investigation (to surface relevant history)
- **Generate Candidate Failure Modes** (to adjust probabilities based on past root causes)
- **Generate Prevention Recommendations** (to personalize advice)
- **Question Generation** (to ask more relevant follow-up questions)

---

## Privacy Considerations

Household Memory contains personal repair and maintenance history. It must remain private to the household and must never be included in Community Intelligence without explicit anonymization and user consent.

---

## Version History

**Version 1.0** — 2026-07-18  
Initial locked specification for the Household Memory Data Model.

---

## Implementation Notes

This model should be designed with query performance in mind, as historical context will be frequently accessed during diagnostic sessions. Consider indexing on `appliance_id` and common maintenance types.

---

*This document is binding. Household Memory must support root cause history, maintenance tracking, and contextual reasoning as defined in Modules 3.5, 3.9, and 4.0.*