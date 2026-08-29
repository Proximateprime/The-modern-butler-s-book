# MASTER ARCHITECTURE INDEX
## The Modern Butler’s Book — Product Bible (Architecture Layer)

**Status:** Living Index  
**Last Updated:** 2026-07-19  
**Purpose:** Single entry point for all locked architecture documents.

This index organizes the architecture into clear layers so both humans and AI coding tools can quickly find the correct governing document.

---

## Layer 0 — Foundational Principles

These documents sit above everything else. All other modules must remain consistent with them.

| Document | File | Status |
|----------|------|--------|
| Design Principles | `00_DESIGN_PRINCIPLES.md` | Locked |
| Safety Invariants | (Earlier document) | Locked |
| Non-Negotiables | (Earlier document) | Locked |
| App Promise | (Earlier document) | Locked |
| Critical Design Decisions | (Earlier document) | Locked |

---

## Layer 1 — Reasoning & Communication Philosophy (3.x)

These documents define **how the Butler thinks and how it communicates**.

| Module | Title | File | Status |
|--------|-------|------|--------|
| 3.5 | Diagnostic Workflow & State Machine | `03_5_DIAGNOSTIC_WORKFLOW_AND_STATE_MACHINE.md` | Locked |
| 3.6 | Reasoning Philosophy & Hybrid Intelligence | `03_6_REASONING_PHILOSOPHY_AND_HYBRID_INTELLIGENCE.md` | Locked |
| 3.7 | Predictive Conversation Engine | `03_7_PREDICTIVE_CONVERSATION_ENGINE.md` | Locked |
| 3.8 | Uncertainty Management & Adaptive Intelligence | `03_8_UNCERTAINTY_MANAGEMENT_AND_ADAPTIVE_INTELLIGENCE.md` | Locked |
| 3.9 | Repair Philosophy | `03_9_REPAIR_PHILOSOPHY.md` | Locked |
| 3.10 | Confidence & Explainability Policy | `03_10_CONFIDENCE_AND_EXPLAINABILITY_POLICY.md` | Locked |
| 3.11 | Knowledge Trust & Evidence Ranking Specification | `03_11_KNOWLEDGE_TRUST_AND_EVIDENCE_RANKING_SPECIFICATION.md` | Locked |
| 3.12 | Human-Centered Reasoning & Adaptive Communication | `03_12_HUMAN_CENTERED_REASONING_AND_ADAPTIVE_COMMUNICATION.md` | Locked |

---

## Layer 2 — Data Models & Evidence Acquisition (4.x)

These documents define **what the system stores and how it obtains evidence from humans**.

| Module | Title | File | Status |
|--------|-------|------|--------|
| 4.0 | Repair Session Data Model | `04_0_REPAIR_SESSION_DATA_MODEL.md` | Locked |
| 4.1 | Evidence Data Model | `04_1_EVIDENCE_DATA_MODEL.md` | Locked |
| 4.2 | Household Memory Data Model | `04_2_HOUSEHOLD_MEMORY_DATA_MODEL.md` | Locked |
| 4.3 | Evidence Acquisition & Translation Engine | `04_3_EVIDENCE_ACQUISITION_AND_TRANSLATION_ENGINE.md` | Locked |

---

## Layer 3 — Core Engines & Platform Services (5.x)

These documents define the major engines and platform capabilities.

| Module | Title | File | Status |
|--------|-------|------|--------|
| 5.1 | Risk & Safety Engine | `05_1_RISK_AND_SAFETY_ENGINE.md` | Locked |
| 5.2 | Engine Orchestration Layer | `05_2_ENGINE_ORCHESTRATION_LAYER.md` | Locked |
| 5.3 | Learning Engine | `05_3_LEARNING_ENGINE.md` | Locked |
| 5.4 | Knowledge Graph Query Engine | `05_4_KNOWLEDGE_GRAPH_QUERY_ENGINE.md` | Locked |
| 5.5 | Confidence & Decision Engine | `05_5_CONFIDENCE_AND_DECISION_ENGINE.md` | Locked |
| 5.6 | Knowledge Graph Versioning | `05_6_KNOWLEDGE_GRAPH_VERSIONING.md` | Locked |
| 5.7 | Engineering Knowledge Authoring System | `05_7_ENGINEERING_KNOWLEDGE_AUTHORING_SYSTEM.md` | Locked |
| 5.8 | Validation & Simulation Framework | `05_8_VALIDATION_AND_SIMULATION_FRAMEWORK.md` | Locked |
| 5.9 | Telemetry & Improvement Analytics | `05_9_TELEMETRY_AND_IMPROVEMENT_ANALYTICS.md` | Locked |
| 5.10 | Domain Plugin Architecture | `05_10_DOMAIN_PLUGIN_ARCHITECTURE.md` | **Future** |

---

## Recommended Reading Order for New Contributors / Cursor

1. Design Principles  
2. Safety Invariants + Non-Negotiables + App Promise  
3. Module 3.5 (State Machine)  
4. Module 3.9 (Repair Philosophy)  
5. Module 4.0 + 4.1 + 4.2 (Core Data Models)  
6. Module 4.3 (Evidence Acquisition)  
7. Module 5.1 (Risk & Safety)  
8. Module 5.2 (Orchestration)  
9. Remaining engines as needed

---

## Notes

- This index is a **cut-down but still substantial** version of the full Product Bible.  
- The full Product Bible also contains earlier volumes on vision, market, business model, UX details, and long-term company strategy.  
- Architecture documents in this index are intended to be **implementation-constraining**. Cursor and future developers should treat Locked documents as authoritative.

---

*This Master Index should be updated whenever a new architecture module is added or the status of an existing module changes.*