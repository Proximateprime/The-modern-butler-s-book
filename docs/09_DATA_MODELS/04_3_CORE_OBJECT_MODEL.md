# MODULE 4.3 — CORE OBJECT MODEL

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-18  
**Authority:** Architecture Specification  
**Depends On:**  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 4.0 — Repair Session Data Model  
- Module 4.1 — Evidence Data Model

---

## Purpose

This document defines the **Core Object Model** for The Modern Butler’s Book. It establishes a shared conceptual vocabulary of the main objects in the system and their relationships.

This model is not a database schema. It is a high-level object-oriented view that all future documents and implementation should reference to ensure consistency.

---

## Core Objects

### Appliance
Represents a physical appliance in the household.

**Key Attributes:**
- Identity (nickname, category, manufacturer, model, serial)
- Location label
- Status
- Approximate age

**Relationships:**
- Belongs to a Household
- Has many Repair Sessions
- Has many Maintenance Records
- Has many Root Cause History entries

### Repair Session
See Module 4.0 for detailed model.

**Key Relationships:**
- Belongs to one Appliance
- Contains many Evidence records
- Contains many Hypotheses
- Has one Outcome (when completed)
- Has many Prevention Recommendations

### Evidence
See Module 4.1 for detailed model.

**Key Relationships:**
- Belongs to one Repair Session
- Can be linked to Knowledge Graph nodes
- Can reference Household Memory records

### Hypothesis
A potential explanation for the observed symptoms during a session.

**Key Attributes:**
- Linked Failure Mode (from Knowledge Graph)
- Current confidence score
- Status (Active, Ruled Out, Leading, Resolved)
- History of confidence changes

**Relationships:**
- Belongs to one Repair Session
- References one Failure Mode in the Knowledge Graph

### Evidence
(Already defined in Module 4.1)

### Failure Mode
A known way an appliance or component can fail (from the Knowledge Graph).

**Relationships:**
- Can produce Symptoms
- Can be suggested by Symptoms
- Can affect Components

### Symptom
An observable effect of a failure (from the Knowledge Graph).

### Root Cause
The underlying reason a failure occurred (recorded in Session Outcome).

**Key Attributes:**
- Immediate Cause
- Root Cause description
- Contributing Factors
- Confidence in root cause determination

### Prevention Recommendation
Actionable advice to reduce the chance of recurrence.

**Key Attributes:**
- Recommendation text
- Category
- Priority
- Whether it is based on identified root cause

### Maintenance Record
A record of maintenance performed on an appliance.

**Key Attributes:**
- Maintenance type
- Date performed
- Notes

### Question
A structured question presented to the user during a diagnostic session.

**Key Attributes:**
- Question text
- Possible answers
- Information gain score (at time of selection)
- Reason for selection

### Conversation State
The current position in the diagnostic conversation (closely tied to the state machine in Module 3.5).

---

## Object Relationships Summary

- **Household** → has many **Appliances**
- **Appliance** → has many **Repair Sessions**
- **Repair Session** → has many **Evidence** records
- **Repair Session** → has many **Hypotheses**
- **Repair Session** → has one **Outcome**
- **Repair Session** → has many **Prevention Recommendations**
- **Evidence** → can link to **Knowledge Graph** nodes
- **Hypothesis** → references **Failure Mode**
- **Appliance** → has many **Maintenance Records**
- **Appliance** → has many **Root Cause History** entries

---

## Version History

**Version 1.0** — 2026-07-18  
Initial locked specification of the Core Object Model.

---

## Implementation Notes

This conceptual model should be used as the common language across all future architecture documents and implementation work. Every new module should reference these core objects where relevant.

---

*This document is binding. All future data models and system design must be consistent with this core object model.*