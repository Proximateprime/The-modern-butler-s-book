# MODULE 3.8 — UNCERTAINTY MANAGEMENT & ADAPTIVE INTELLIGENCE

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-18  
**Authority:** Architecture Specification  
**Depends On:**  
- Safety Invariants  
- Non-Negotiables  
- App Promise  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 3.6 — Reasoning Philosophy & Hybrid Intelligence  
- Module 3.7 — Predictive Conversation Engine  
- Critical Design Decisions Addendum (2026-07-17)

---

## Purpose

This document defines how the Butler manages uncertainty, trust, contradictions, and adaptation throughout the diagnostic process. It establishes the architectural requirements for confidence scoring, source reliability, contradiction resolution, and graceful behavior under imperfect conditions.

These capabilities are essential for creating a trustworthy system that can operate reliably in real-world conditions where information is incomplete, contradictory, or varies in quality.

This specification is binding on the Reasoning Engine, Evidence Engine, Conversation Engine, Household Memory Engine, and Learning Engine.

---

## Core Principles

The uncertainty management architecture operates under the following principles:

- **Evidence Before Assumption** — No conclusion may be treated as certain without supporting evidence.
- **Transparency of Uncertainty** — The system must communicate its level of confidence and the reasons behind it.
- **Trust Differentiation** — Different sources of information carry different levels of reliability.
- **Contradiction Resilience** — The system must handle conflicting information without breaking or losing prior evidence.
- **Goal Awareness** — Reasoning and recommendations should consider the user’s objectives when relevant.
- **Graceful Degradation** — The Butler must continue functioning usefully even when data or services are limited.
- **Explainable History** — The user must be able to understand how the investigation reached its current state.

---

## Confidence & Uncertainty

The Butler must never present conclusions as absolute facts. Instead, it must communicate confidence levels transparently.

Confidence should be expressed in ways such as:

- Most likely: Drain obstruction (82%)
- Other possibilities:
  - Drain pump failure (14%)
  - Control board issue (4%)

Every significant change in confidence must be traceable to specific evidence. The system should be able to explain:

- Which pieces of evidence increased confidence in a hypothesis
- Which pieces of evidence decreased confidence
- Why certain hypotheses were ruled out or deprioritized

Confidence scores are dynamic and must be updated continuously as new evidence is collected.

---

## Trust Management

Not all information carries equal weight. The system must differentiate between sources based on their reliability.

Examples of trust levels include:

- Direct sensor data or measured values → Very High
- Clear photo evidence → High
- User statement about a recent action → Medium to Low
- User memory of events from years ago → Low
- Manufacturer service manual → Authoritative (when applicable)
- Community reports (unverified) → Medium until verified
- Random internet sources → Low

The Reasoning Engine and Evidence Engine must account for source trust when updating hypotheses and confidence scores. Higher-trust evidence should carry greater influence on conclusions.

---

## Contradiction Handling

The system must be able to detect and respond to contradictory information without losing prior evidence or becoming unstable.

When new evidence conflicts with previous information (for example, a user stating the drum spins, followed by a video showing it does not), the Butler must:

- Acknowledge the contradiction explicitly
- Identify which evidence is more recent or higher trust
- Update the active hypothesis set accordingly
- Explain the change in reasoning to the user
- Preserve the full history of conflicting evidence

Contradictions should trigger re-evaluation rather than causing the system to discard earlier data.

---

## Goal-Based Reasoning

Users have different objectives when troubleshooting. The system should adapt its recommendations and questioning style based on the user’s goals when they are known or can be inferred.

Common user goals include:

- Cheapest possible repair
- Fastest resolution
- Safest possible approach
- Learning how the appliance works
- Determining whether repair or replacement is better long-term

When goals are known, the Reasoning Engine and Conversation Engine should adjust question priority, guidance style, and prevention recommendations accordingly. Goal information should be treated as contextual rather than mandatory.

---

## Graceful Degradation

The Butler must continue to provide useful assistance even when operating under limited conditions. The system must define fallback behavior for situations such as:

- No internet connection
- Cloud AI services unavailable
- Knowledge Graph does not contain the specific appliance or failure
- Photo or voice input fails
- Partial or missing household history

In all degraded states, the system must:

- Continue using whatever local knowledge and evidence is available
- Clearly communicate its limitations when relevant
- Avoid unsafe recommendations
- Allow the user to continue the investigation

Graceful degradation ensures the app remains functional and safe even when ideal conditions are not met.

---

## Time as a Reasoning Factor

Time is an important dimension in diagnostic reasoning. The system must consider temporal information such as:

- When maintenance was last performed
- How long ago a part was replaced
- Age of the appliance
- Seasonal patterns
- Frequency of repeated issues over time

Time-based context should influence question ordering, hypothesis ranking, and prevention recommendations. For example, a belt replaced nine years ago carries different implications than one replaced last month.

---

## User Skill Model

The Butler should gradually build and maintain a model of the user’s skill level based on observed behavior rather than relying solely on self-reported categories.

Observable indicators may include:

- Correct identification of components
- Safe and accurate measurement of electrical values
- Successful completion of mechanical tasks
- Understanding of safety procedures

As the user demonstrates competence, the Conversation Engine and Reasoning Engine should naturally adapt question complexity, guidance detail, and the level of scaffolding provided. The skill model must be updated continuously and remain private to the household.

---

## Stopping Rules

The diagnostic process must not continue indefinitely. The system requires clear rules for when to stop asking questions or pursuing further investigation.

Stopping rules should consider factors such as:

- Sufficient confidence in a leading hypothesis
- High enough confidence to issue safe guidance
- Multiple remaining possibilities with similar probability
- Safety constraints that limit further investigation
- Diminishing returns on additional evidence
- User fatigue or explicit desire to stop

When stopping criteria are met, the system should either issue guidance, recommend professional service, or clearly explain the remaining uncertainty.

---

## Economic Intelligence (Future Architecture)

Long-term architecture may include the ability to provide economic context after a diagnosis has been reached. This may include considerations such as:

- Estimated repair cost
- Parts availability and lead time
- Expected remaining service life
- Energy efficiency impact
- Maintenance burden
- Environmental considerations

This capability must remain secondary to accurate diagnosis and root cause analysis. Economic recommendations should only be offered after the technical diagnosis is reasonably established.

---

## Explainability History

At any point during or after a session, the user must be able to request an explanation of how the investigation reached its current state.

The system should be able to present a clear, chronological summary showing:

- Key observations recorded
- Questions asked and why they were selected
- How evidence affected confidence in hypotheses
- Why certain paths were prioritized or deprioritized
- How contradictions were resolved

This history should be presented in an understandable format that builds user trust and understanding.

---

## Responsibilities

**Reasoning Engine**  
Responsible for managing confidence scores, incorporating source trust levels, handling contradictions, and maintaining hypothesis rankings.

**Evidence Engine**  
Responsible for recording the trust level and provenance of each piece of evidence.

**Conversation Engine**  
Responsible for presenting confidence information and explainability history to the user in clear language.

**Household Memory Engine**  
Responsible for storing and surfacing time-based history and prior root cause information.

**Learning Engine**  
Responsible for improving confidence calibration and contradiction handling over time based on verified outcomes.

---

## Failure Recovery

The system must handle situations involving high uncertainty, conflicting information, or incomplete data without losing evidence or creating unsafe recommendations. In such cases, it must:

- Clearly communicate current uncertainty
- Offer safe next steps or professional referral when appropriate
- Preserve all collected evidence for later review
- Allow the user to provide additional information or correct previous answers

---

## Version History

**Version 1.0** — 2026-07-18  
Initial locked specification establishing requirements for confidence management, trust differentiation, contradiction handling, goal awareness, graceful degradation, temporal reasoning, user skill modeling, stopping rules, and explainability history.

---

## Implementation Notes

This document defines architectural requirements that affect confidence scoring, evidence weighting, conversation flow, and long-term adaptation. All implementation of the Reasoning Engine, Evidence Engine, and Conversation Engine must respect these constraints.

This document forms part of the permanent Product Bible. Any future changes to uncertainty handling or adaptive behavior must be evaluated against this specification.

---

*This document is binding. All handling of confidence, trust, contradictions, and adaptive behavior must conform to the requirements defined herein.*