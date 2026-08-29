# MODULE 6.0 — KNOWLEDGE GRAPH SCHEMA

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-19  
**Authority:** Architecture Specification  

**Depends On:**  
- Module 02 — Knowledge Graph Structure  
- Module 5.6 — Knowledge Graph Versioning  
- Module 5.4 — Knowledge Graph Query Engine

---

## Purpose

This document defines the high-level schema and core entity types of the Knowledge Graph.

It provides the structural foundation that the Query Engine, Reasoning Engine, and Authoring System all depend on.

---

## Core Node Types

- **ApplianceCategory**
- **Subsystem**
- **Component**
- **Symptom**
- **FailureMode**
- **ObservationMethod** (optional, for acquisition strategies)
- **SafeCheck**
- **PreventionAction**

---

## Core Relationship Types

- `contains` (Category → Subsystem → Component)
- `produces` (FailureMode → Symptom)
- `suggests` (Symptom → FailureMode)
- `affects` (FailureMode → Component)
- `applies_to` (FailureMode → ApplianceCategory)
- `can_be_observed_by` (Symptom / FailureMode → ObservationMethod)
- `prevented_by` (FailureMode → PreventionAction)

---

## Required Metadata on Nodes & Edges

- Unique stable identifier / slug
- Human-readable name
- Description
- Graph version
- Source / provenance
- Trust / verification status
- Active / deprecated flag
- Timestamps (created, updated)

---

## Design Principles

- The graph is intentionally incomplete.
- Prefer explicit relationships over implicit ones.
- Support versioning at the graph and individual statement level.
- Allow future extension without breaking existing queries.

---

## Version History

**Version 1.0** — 2026-07-19  
Initial locked high-level schema for the Knowledge Graph.

---

*This document is binding. All Knowledge Graph implementations must support these core entity and relationship types.*