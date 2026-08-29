# MODULE 8.0 — LOCAL-FIRST KNOWLEDGE PACKAGE ARCHITECTURE

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-20  
**Authority:** Architecture Specification  

**Depends On:**  
- Design Principles  
- Engineering Principles — AI Cost & Local-First  
- Module 5.4 — Knowledge Graph Query Engine  
- Module 5.6 — Knowledge Graph Versioning  
- Module 5.7 — Engineering Knowledge Authoring System  
- Module 6.0 — Knowledge Graph Schema  
- MVP Scope Lock

---

## Purpose

This document locks the Local-First Knowledge Package Architecture.

AI should be the **translator**, not the **encyclopedia**.

Deterministic reasoning, confidence logic, safety rules, and structured knowledge should perform as much diagnostic work as possible on-device. The LLM is primarily responsible for communication, explanation, and adaptive wording.

---

## Core Decision

Instead of relying on cloud AI for appliance knowledge during every repair:

- Each appliance family is represented by a versioned **Knowledge Package**
- Packages are downloaded to the device and stored locally
- Packages update through small version patches
- The Knowledge Graph operates primarily against local data

---

## What a Knowledge Package Contains

A package may include:

- Failure modes
- Evidence relationships / evidence graph
- Diagnostic transitions
- Confidence tuning values
- Safety rules
- Repair procedures
- Preventive maintenance
- Required tools
- Parts metadata
- Engineering references
- Diagrams / exploded views
- 3D models
- AR anchor metadata
- Version history

Not every package needs every asset on day one. Minimum useful coverage comes first; depth grows over time.

---

## Knowledge Package Manager

The app includes a subsystem responsible for:

- Detecting appliance model numbers (OCR / barcode / QR / manual entry)
- Mapping models to appliance families
- Downloading required packages
- Applying delta updates
- Verifying package integrity
- Managing local storage

### Example

```
Whirlpool WED5000DW2
        ↓
Knowledge Package: Whirlpool Dryer Family
        ↓
Downloaded once
        ↓
Available offline
```

Model-specific differences should be handled as lightweight patches whenever practical.

---

## Local-First Reasoning Pipeline

Most diagnostic work should occur without cloud AI:

```
Knowledge Package
      ↓
Evidence Engine
      ↓
Reasoning Engine
      ↓
Confidence Engine
      ↓
Safety Engine
      ↓
LLM only when needed
      ↓
Natural language output
```

When the LLM is used, it should receive structured state such as:

- Current hypotheses
- Confidence values
- Current evidence
- User communication preferences
- Relevant session context

It should not receive entire manuals or the full knowledge graph by default.

---

## Knowledge Seeding Philosophy

We are not manually writing one giant static database.

Instead:

1. AI may assist in drafting structured knowledge from legitimate engineering sources
2. Human review validates correctness
3. Packages become version-controlled engineering assets
4. Verified repair outcomes refine future versions

---

## Coverage Strategy: Breadth + Progressive Depth

Every supported category launches with a **Minimum Useful Knowledge Package**, including at least:

- Overview
- Safety
- Maintenance
- Major components
- Common failure modes
- Diagnostic flow
- Safe checks
- Common repairs
- Prevention
- Tool requirements

Depth increases over time while broad category coverage remains available.

---

## Internal Metric: Knowledge Coverage Score

An internal engineering metric used only for planning:

- Identify weak packages
- Prioritize authoring effort
- Track improvement over time

This is not a user-facing score.

---

## Guiding Principle

> Every expensive AI call should teach the Butler how to require fewer expensive AI calls in the future.

As deterministic engineering knowledge improves:

- API cost per repair should fall
- Offline capability should rise
- Privacy should improve
- Speed should improve
- Repair quality should improve

---

## Relationship to MVP

For the 2-week push:

- Full package manager sophistication is not required on day one
- A local seed package for Dryer is enough to prove the loop
- The architecture must remain compatible with on-demand family packages and delta updates

Do not expand MVP scope to build the entire package ecosystem before the diagnostic loop works.

---

## Version History

**Version 1.0** — 2026-07-20  
Initial locked specification for Local-First Knowledge Package Architecture.

---

*This document is binding. Knowledge distribution and diagnostic runtime design must remain local-first and package-oriented as defined herein.*