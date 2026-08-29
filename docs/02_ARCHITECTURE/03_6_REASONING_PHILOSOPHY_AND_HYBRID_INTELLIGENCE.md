# MODULE 3.6 — REASONING PHILOSOPHY & HYBRID INTELLIGENCE

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-18  
**Authority:** Architecture Specification  
**Depends On:**  
- Safety Invariants  
- Non-Negotiables  
- App Promise  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 02 — Knowledge Graph Structure  
- Module 03 — Knowledge Graph Seeding (MVP Phase 1)  
- Critical Design Decisions Addendum (2026-07-17)

---

## Purpose

This document defines how the Butler reasons. It establishes the core philosophy and architecture of the reasoning system.

The Modern Butler’s Book is a **hybrid reasoning system**. It is not a database lookup tool. It is not a generic large language model chatbot. It is not a pure rule engine. It combines structured knowledge, engineering principles, session evidence, and household history to produce reliable, explainable, and safe diagnostic reasoning.

This specification is binding on the Reasoning Engine, Knowledge Graph, Evidence Engine, Household Memory Engine, Learning Engine, and all future components that participate in diagnostic decision-making.

---

## Core Principles

The reasoning architecture is governed by the following principles:

- **Engineering First** — Reasoning begins with fundamental engineering principles (airflow, heat transfer, fluid dynamics, electrical behavior, mechanical motion, control systems) before relying on memorized repair cases.
- **Hybrid Intelligence** — The Butler draws simultaneously from multiple sources of knowledge rather than depending on any single source.
- **Evidence Before Assumption** — Conclusions must be grounded in structured evidence from the current session.
- **Root Cause Before Completion** — Every repair session must attempt to identify why a failure occurred, not merely what failed.
- **Progressive Knowledge** — Knowledge improves over time through versioned updates, but engineering truth is never automatically overwritten by learning.
- **Explainability Before Fluency** — The system must be able to explain its reasoning at every significant decision point.
- **Adaptive Reasoning** — The system prepares likely next steps while the user is still processing the current step.
- **Long-Term Household Improvement** — Reasoning improves across the lifetime of a household through verified outcomes while maintaining strict privacy boundaries.

---

## Hybrid Intelligence

The Butler reasons by combining multiple information sources at once. These sources include:

- Engineering principles and physical laws
- The Knowledge Graph (structured relationships between categories, subsystems, components, symptoms, and failure modes)
- Evidence collected during the current session
- Household Memory (prior repairs, root causes, and maintenance history)
- Appliance specifications and known characteristics
- Verified community knowledge (anonymized and quality-gated)
- Safe engineering heuristics
- Manufacturer documentation (when available and reviewed)

The database and Knowledge Graph assist reasoning. They accelerate and ground it. They do not replace it or define its limits.

---

## Database Philosophy

The Knowledge Graph is intentionally incomplete. It will never contain every appliance model, every possible failure mode, or every symptom. The Butler must remain capable of useful reasoning even when a specific appliance, component, or failure pattern is absent from the graph.

The Knowledge Graph provides high-value structured relationships that improve speed and accuracy. It does not act as a hard boundary on what the Butler can diagnose or explain.

When the Knowledge Graph lacks direct coverage, the system falls back to engineering principles, session evidence, and household history.

---

## Engineering First

The Butler prioritizes reasoning from engineering fundamentals over pattern matching against previous repair cases.

Core domains of engineering understanding include:

- Airflow and ventilation
- Heat transfer and thermodynamics
- Water flow, pressure, and drainage
- Electrical circuits, motors, sensors, and control systems
- Mechanical motion, belts, bearings, and seals
- Safety interlocks and protective devices

The system uses these principles to evaluate hypotheses and generate explanations even when specific failure patterns are not present in the Knowledge Graph.

---

## Progressive Knowledge

Knowledge in the system grows over time through multiple channels:

- Versioned updates to the Knowledge Graph
- Household Memory of verified repairs and maintenance
- Quality-gated additions from verified community outcomes
- Reviewed manufacturer documentation and expert contributions

Learning improves the system’s performance but never replaces engineering truth. All updates to core knowledge must be versioned and reversible.

---

## Household Memory in Reasoning

Household Memory provides critical context for reasoning. Previous repairs are not treated as isolated events. When relevant, the system uses prior root cause information to adjust question ordering and hypothesis ranking.

Example:  
If Household Memory shows that a dryer previously overheated due to lint blockage and restricted airflow, the Butler may prioritize questions about vent cleaning and airflow in a new “not heating” investigation rather than immediately assuming a failed heating element.

Household Memory improves probability assessment without replacing current evidence.

---

## Root Cause Intelligence

The Butler does not consider a repair complete when a failed component is identified. Every session must attempt to determine why the failure occurred.

Root cause analysis distinguishes between:

- **Immediate Cause** — The component or condition that directly stopped working
- **Root Cause** — The underlying reason the immediate cause occurred
- **Contributing Factors** — Conditions that increased the likelihood of failure
- **Preventive Actions** — Steps that can reduce recurrence

Protective devices (such as thermal fuses or pressure switches) are treated as symptoms of underlying problems, not as root causes.

---

## Predictive Maintenance

Over time, patterns in Household Memory enable the Butler to identify recurring issues before failure occurs. Examples include repeated lint buildup, dirty condenser coils, clogged filters, or washer imbalance.

When patterns are detected, the system may proactively recommend maintenance actions as part of prevention recommendations or during relevant diagnostic sessions.

Predictive suggestions are always presented as recommendations rather than requirements and are grounded in the household’s own history.

---

## Adaptive Reasoning

The reasoning system is designed for responsive interaction. While the user is reading or responding to one question, the system prepares likely follow-up branches.

This includes:

- Speculative pre-computation of high-probability next questions based on current evidence and hypotheses
- Caching of likely Knowledge Graph traversals
- Branch prediction for common evidence paths
- Maintenance of multiple active hypothesis threads until sufficient evidence resolves them

The goal is to minimize perceived latency and create a smooth, natural diagnostic experience while remaining fully grounded in evidence and the state machine defined in Module 3.5.

---

## Explainability

At every significant decision point, the Butler must be able to explain:

- Why a particular question was selected
- Why confidence in a hypothesis increased or decreased
- Why a potential failure mode was ruled out or deprioritized
- Why a specific repair or maintenance action was recommended
- Why investigation continued or concluded

Explanations must be available to the user and must reference the evidence, Knowledge Graph relationships, and (when relevant) household history that informed the decision.

---

## Future Compatibility

The reasoning architecture must remain compatible with multiple operational environments and future developments, including:

- Fully offline operation
- Hybrid local + cloud reasoning
- Multiple AI model providers
- Custom or future reasoning engines
- Symbolic reasoning components
- Local on-device models

The core principles of hybrid intelligence, engineering-first reasoning, and evidence-based conclusions must remain stable regardless of the underlying implementation technology.

---

## Responsibilities

**Reasoning Engine**  
Primary owner of hypothesis generation, confidence scoring, and interpretation of evidence against the Knowledge Graph and household history. Coordinates with other engines but does not own truth.

**Knowledge Graph**  
Provides structured relationships that ground and accelerate reasoning. Remains intentionally incomplete.

**Evidence Engine**  
Supplies structured observations from the current session as the primary input to reasoning.

**Household Memory Engine**  
Supplies historical context (prior root causes and maintenance) that informs probability and question selection without replacing current evidence.

**Learning Engine**  
Proposes improvements to the Knowledge Graph and predictive patterns based solely on verified outcomes.

**Root Cause & Prevention Engine**  
Responsible for root cause analysis and generation of prevention recommendations within the diagnostic workflow.

---

## Failure Recovery

When the Knowledge Graph lacks coverage for a specific appliance or failure, the system must:

- Fall back to engineering principles and session evidence
- Clearly communicate the limits of its knowledge when appropriate
- Continue guiding the user safely rather than refusing to assist

The system must never claim certainty it does not have and must remain functional even with partial or missing graph data.

---

## Version History

**Version 1.0** — 2026-07-18  
Initial locked specification establishing the hybrid reasoning philosophy, database philosophy, engineering-first approach, and adaptive reasoning requirements.

---

## Implementation Notes

This document defines the philosophy and constraints that must guide all implementation of the Reasoning Engine and related components. Future development of the reasoning system, question selection logic, hypothesis ranking, and integration with the state machine defined in Module 3.5 must remain consistent with the principles and requirements stated here.

This document forms part of the permanent Product Bible. Any proposed changes to reasoning behavior must be evaluated against this specification.

---

*This document is binding. All reasoning-related implementation must conform to the hybrid intelligence model, engineering-first priority, and architectural constraints defined herein.*