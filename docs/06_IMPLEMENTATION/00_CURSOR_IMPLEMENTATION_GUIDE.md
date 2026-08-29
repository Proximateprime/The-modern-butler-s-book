# CURSOR IMPLEMENTATION GUIDE
## The Modern Butler’s Book

**Status:** Implementation Guidance  
**Version:** 1.0  
**Date:** 2026-07-19  
**Authority:** Architecture → Implementation Bridge  

This document tells Cursor (or any developer/AI) **what to read first** and **what to build in what order**.  
It exists to prevent the system from inventing architecture.

**Feature freeze:** [`docs/FEATURE_FREEZE.md`](../FEATURE_FREEZE.md) (2026-08-17). After freeze, **bugfixes only**.

---

## Critical Rules for Cursor

1. Treat all documents marked **Locked** as authoritative.
2. Do not invent new engines, states, or data models that contradict existing modules.
3. Prefer the simplest implementation that fully respects the architecture.
4. When in doubt, follow Design Principles and Safety Invariants first.
5. Never bypass the Risk & Safety Engine.

---

## Recommended Reading Order (Do This First)

Read these documents in order before writing significant code:

### Foundation (Must Read)
1. `00_DESIGN_PRINCIPLES.md`
2. Safety Invariants
3. Non-Negotiables
4. App Promise
5. `00_MASTER_ARCHITECTURE_INDEX.md`

### Core Workflow & Philosophy
6. `03_5_DIAGNOSTIC_WORKFLOW_AND_STATE_MACHINE.md`
7. `03_9_REPAIR_PHILOSOPHY.md`
8. `03_12_HUMAN_CENTERED_REASONING_AND_ADAPTIVE_COMMUNICATION.md`
9. `04_3_EVIDENCE_ACQUISITION_AND_TRANSLATION_ENGINE.md`

### Data Foundations
10. `04_0_REPAIR_SESSION_DATA_MODEL.md`
11. `04_1_EVIDENCE_DATA_MODEL.md`
12. `04_2_HOUSEHOLD_MEMORY_DATA_MODEL.md`

### Safety & Control
13. `05_1_RISK_AND_SAFETY_ENGINE.md`
14. `05_0_RISK_AND_SAFETY_DECISION_TABLES.md`
15. `05_2_ENGINE_ORCHESTRATION_LAYER.md`

### Supporting Engines (Read as Needed)
- Confidence & Decision Engine
- Learning Engine
- Knowledge Graph related modules
- Explainability Engine
- Session Resume & Failure Recovery

---

## Recommended Build Sequence

Build in this order. Do not skip ahead to advanced features.

### Phase 1 — Foundation
1. Project setup (Flutter + Supabase)
2. Authentication & basic Household structure
3. Appliance model and basic CRUD
4. Repair Session model (create, save, resume)
5. Basic state machine skeleton (even if many states are stubs)

### Phase 2 — Evidence & Conversation Core
6. Evidence model + provenance
7. Simple question presentation (one question at a time)
8. Evidence Acquisition & Translation (start simple)
9. Basic session flow through a few states

### Phase 3 — Reasoning Skeleton
10. Knowledge Graph basic structure + seed data
11. Simple hypothesis ranking
12. Confidence updates (even if initially rule-based)
13. Risk & Safety checks at key points

### Phase 4 — Completing the Loop
14. Root Cause capture
15. Prevention recommendations
16. Session summary & Household Memory updates
17. Basic explainability (“Why are you asking this?”)

### Phase 5 — Hardening
18. Session Resume & Continuity
19. Failure Recovery
20. Offline support (basic)
21. Improved confidence and stopping rules

---

## What Cursor Should Not Do Yet

- Full predictive conversation with heavy pre-computation
- Advanced learning from community data
- Complex multi-session reasoning
- AR / advanced computer vision
- Domain plugins beyond appliances
- Monetization systems

---

## Success Criteria for Early Versions

A successful early implementation can:

- Start a Repair Session on an appliance
- Ask observation-based questions
- Collect Evidence
- Maintain session state
- Respect basic safety gates
- Reach a simple conclusion or professional recommendation
- Save the session to Household Memory

---

*This guide is the recommended bridge between the Product Bible and actual code. Follow it unless there is a strong, documented reason not to.*