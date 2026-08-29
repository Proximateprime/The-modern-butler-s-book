# MODULE 5.1 — RISK & SAFETY ENGINE

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-19  
**Authority:** Architecture Specification  

**Depends On:**  
- Safety Invariants  
- Non-Negotiables  
- Design Principles  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 3.9 — Repair Philosophy  
- Module 4.3 — Evidence Acquisition & Translation Engine

---

## Purpose

The Risk & Safety Engine is the final authority on safety within The Modern Butler’s Book.

Its purpose is to protect the user, the household, and the integrity of the system by evaluating risk at every relevant decision point and enforcing hard safety boundaries.

This engine has the authority to:

- Interrupt any diagnostic path
- Block specific guidance
- Force escalation to a professional
- Prevent the system from issuing unsafe recommendations
- Override lower-priority goals when safety is at risk

No other engine may bypass or weaken the decisions of the Risk & Safety Engine.

---

## Core Responsibilities

1. **Risk Evaluation**  
   Continuously assess the risk level of the current diagnostic path, proposed guidance, and user actions.

2. **Safety Gate Enforcement**  
   Enforce the permanent Safety Invariants. Certain categories of work (live electrical internals, gas systems, sealed refrigerant systems, etc.) are never allowed regardless of user skill or confidence.

3. **Escalation Decisions**  
   Determine when the system must stop guiding and recommend professional service.

4. **Intervention Authority**  
   Ability to pause, redirect, or terminate a session when risk becomes unacceptable.

5. **Context-Aware Safety**  
   Adjust safety strictness based on the current situation, available evidence, user skill signals, and environmental factors — without ever removing hard safety gates.

---

## When the Engine Must Act

The Risk & Safety Engine must evaluate risk at least at these points:

- Before issuing any physical guidance or repair step
- When a new high-risk hypothesis becomes leading
- When the user is about to perform an action that involves electricity, gas, moving parts, or height
- When confidence is high but the recommended action is inherently dangerous
- When contradictory evidence increases uncertainty in a safety-critical area
- When the user demonstrates low skill or high uncertainty in a risky situation

---

## Risk Classification

The engine should classify situations into clear risk levels (example categories):

- **Low Risk** — Safe observational checks, external visual inspections, simple maintenance
- **Moderate Risk** — Actions that require basic tools or limited physical access but stay within safe boundaries
- **High Risk** — Actions that approach safety boundaries or involve significant uncertainty
- **Prohibited** — Actions that violate Safety Invariants (these must never be recommended)

Only Low and carefully controlled Moderate risk actions may proceed with guidance. High Risk and Prohibited actions must trigger escalation or refusal.

---

## Escalation Rules

The engine should force professional recommendation when:

- The required action violates a Safety Invariant
- Confidence is insufficient and the remaining possibilities are safety-critical
- The user cannot safely perform necessary observations
- Multiple high-risk failure modes remain plausible
- The system detects conditions that require specialized tools, certification, or training

Escalation messages must be clear, calm, and non-judgmental. They should explain *why* professional help is recommended without making the user feel incapable.

---

## Interaction with Other Engines

- **Reasoning Engine**: Provides current hypotheses and confidence. The Risk Engine can reject or deprioritize unsafe hypotheses.
- **Conversation Engine / Evidence Acquisition Engine**: Can force rephrasing or block questions that would lead the user toward unsafe actions.
- **State Machine Controller**: Can force a transition to a safe terminal state (e.g., “Recommend Professional”).
- **Household Memory**: May use past safety-related outcomes to adjust sensitivity.

---

## Explainability Requirement

Whenever the Risk & Safety Engine intervenes, it must be able to explain:

- Why the current path is considered unsafe
- Which Safety Invariant or risk factor triggered the decision
- What safer alternatives (if any) remain available

---

## Version History

**Version 1.0** — 2026-07-19  
Initial locked specification establishing the Risk & Safety Engine as the final safety authority.

---

## Implementation Notes

This engine must be treated as a hard constraint layer. Implementation should make it difficult or impossible for other parts of the system to bypass its decisions.

This document forms part of the permanent Product Bible.

---

*This document is binding. No guidance or diagnostic path may proceed if it violates the decisions of the Risk & Safety Engine.*