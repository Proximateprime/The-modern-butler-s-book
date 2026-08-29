# MODULE 4.3 — EVIDENCE ACQUISITION & TRANSLATION ENGINE

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
- Module 3.8 — Uncertainty Management & Adaptive Intelligence  
- Module 3.12 — Human-Centered Reasoning & Adaptive Communication  
- Module 4.0 — Repair Session Data Model  
- Module 4.1 — Evidence Data Model  
- Module 4.2 — Household Memory Data Model

---

## Purpose

The Reasoning Engine determines **what** evidence is required to reduce uncertainty.

The Evidence Acquisition & Translation Engine determines **how** that evidence should be obtained from the current user.

This engine’s primary responsibility is to translate engineering evidence requirements into the safest, simplest, fastest, and most understandable interaction possible for a human being.

It does **not** decide what evidence is needed.  
It does **not** perform diagnostic reasoning.  
It does **not** own conversation flow.

It owns the critical translation layer between engineering need and human observation.

The quality of this translation is one of the largest determinants of whether the Butler feels like a competent technician or like a rigid questionnaire.

---

## Core Philosophy

Humans naturally think in observations.  
Engineers think in evidence.

The Butler exists between those two worlds.

The user should never be expected to think like an engineer.  
The user should only be asked to:

- Look  
- Listen  
- Feel  
- Smell  
- Notice  
- Compare  
- Answer simple, concrete questions  

The system is responsible for converting those natural human observations into structured, trustworthy Evidence objects.

**Critical Design Principle:**

The system must never expose its internal engineering reasoning directly to the user.

Instead of asking:  
> “Is the compressor energized?”

The Butler should ask something closer to:  
> “Place your hand on the back of the refrigerator for about five seconds. Do you feel a gentle vibration or humming?”

Both requests can produce the same underlying evidence. Only one of them is usable by a normal person without specialized knowledge.

---

## Position in the Architecture

This engine sits between the Reasoning Engine and the Conversation Engine.

```
Reasoning Engine
      │
      │  (requests specific evidence)
      ▼
Evidence Acquisition & Translation Engine
      │
      │  (selects best acquisition method + human phrasing)
      ▼
Conversation Engine
      │
      │  (presents interaction to user)
      ▼
User Response
      │
      ▼
Evidence Engine
      │
      ▼
Back to Reasoning Engine
```

It is deliberately not part of the Reasoning Engine.  
Keeping this responsibility separate ensures that diagnostic logic remains clean and that communication strategy can evolve independently.

---

## Responsibilities

This engine owns the following:

- **Observation Strategy Selection**  
  Choosing the best available method of obtaining a required piece of evidence.

- **Human Translation**  
  Converting engineering evidence requirements into natural, safe, everyday language and interactions.

- **Interaction Method Selection**  
  Deciding whether the evidence should be collected via text question, photo, sound recording, guided observation, diagram, or future sensors.

- **Accessibility Adaptation**  
  Adjusting requests based on the user’s current capabilities, device, environment, and past success.

- **Question Optimization**  
  Learning which ways of asking for the same observation consistently produce higher-quality evidence.

- **Alternative Evidence Paths**  
  Maintaining multiple valid ways to collect the same evidence so the system can fall back when one method is unavailable or fails.

- **Evidence Quality Optimization**  
  Preferring acquisition methods that historically produce more reliable and less ambiguous evidence.

---

## Engine Inputs

The engine receives:

- A structured evidence request from the Reasoning Engine (what is needed and why)
- Current Repair Session context
- Current active hypotheses and confidence levels
- User skill / comfort signals (if available)
- Device capabilities (camera, microphone, etc.)
- Accessibility preferences or constraints
- Household Memory relevant to the appliance
- Safety constraints from the Risk & Safety Engine
- Past performance data for different acquisition methods (when available)

---

## Engine Outputs

The engine produces:

- Selected acquisition method
- Fully formed human-facing interaction (question, instruction, or multi-modal request)
- Explanation of why this method was chosen (for internal explainability)
- Fallback acquisition methods (ordered by preference)
- Predicted follow-up branches (for integration with the Predictive Conversation Engine)
- Expected evidence type that will be returned

---

## Interaction with Other Engines

### Reasoning Engine
- Receives evidence requests
- Never decides the content of the question
- Only states the engineering need

### Conversation Engine
- Receives the prepared human interaction
- Handles presentation, timing, and basic conversational management
- Reports user response back into the system

### Evidence Engine
- Receives the user’s response after it has been structured
- Applies trust metadata and provenance

### Knowledge Graph
- May be consulted to understand available observation methods associated with a component or failure mode

### Household Memory
- Provides context about previous successful or unsuccessful ways of collecting similar evidence with this user or appliance

### Risk & Safety Engine
- Can veto or force modification of any proposed acquisition method that is considered unsafe

---

## Observation Strategies

For any given evidence requirement, the engine should evaluate multiple possible acquisition methods and select the best one according to a scoring model.

**Example:**

Evidence needed: `compressor_running`

Possible acquisition methods:

| Method                        | Safety | Effort | Clarity | Device Requirements | Preference Score |
|-------------------------------|--------|--------|---------|---------------------|------------------|
| Listen for humming            | High   | Low    | Medium  | None                | High             |
| Feel for vibration            | High   | Low    | High    | None                | Very High        |
| Camera observation            | High   | Medium | Medium  | Camera              | Medium           |
| Thermal sensor (future)       | High   | Low    | High    | Thermal camera      | High (future)    |
| Smart appliance API (future)  | High   | None   | Very High | Connected appliance | Highest (future) |

The engine scores available methods and selects the highest-value option that is currently feasible and safe.

The same principle applies to every other evidence type (water present, airflow restricted, belt tension, heating element active, etc.).

---

## Adaptive Communication

In addition to selecting the acquisition method, the engine is responsible for adapting the presentation of the request based on context:

- Wording and reading level
- Sentence length and complexity
- Amount of explanation provided
- Use of visual aids, diagrams, or animations
- Use of photos or AR overlays (when available)
- Use of voice prompts
- Step-by-step versus single-request formats

Adaptation factors include:

- Current user comfort / past success with similar tasks
- Device capabilities
- Safety criticality of the observation
- Current uncertainty level in the diagnostic process
- Accessibility needs

---

## Question Optimization

One of the long-term responsibilities of this engine is to improve how evidence is collected from humans.

This is **not** learning engineering knowledge.  
It is learning better communication.

If different phrasings or methods of requesting the same observation consistently produce higher completion rates, clearer answers, and fewer contradictions, the engine should gradually prefer the more effective versions after sufficient validation.

All optimization of this type must be versioned, reversible, and must never alter engineering truth or diagnostic logic.

---

## Predictive Question Preparation

This engine must integrate with the Predictive Conversation Engine (Module 3.7).

While the user is reading or answering the current request, the system should already be preparing the most likely next evidence acquisition methods and their human translations.

If the prediction is incorrect, unused branches are discarded with no visible impact on the user. The goal is near-instant follow-up questions without creating a sense of being rushed.

---

## Future Extensibility

The architecture must support the addition of new acquisition methods without requiring redesign of the engine. Future methods may include:

- Computer vision analysis of user-submitted photos
- Audio analysis of recorded sounds
- Thermal cameras
- Smart appliance integrations
- Wearables and environmental sensors
- Bluetooth or IoT devices

New methods should be added as additional scored strategies rather than special cases.

---

## Explainability

The engine must always be capable of answering:

- Why this particular observation was requested
- Why this interaction method was chosen over alternatives
- Why another method was not selected
- How the user’s response improved (or failed to improve) confidence

These explanations support both user-facing transparency and internal debugging.

---

## Common Sense Goal

The primary long-term objective of this engine is practical common sense.

At every decision point it should choose the observation request that:

- Minimizes confusion
- Minimizes effort
- Maximizes evidence quality
- Maximizes the chance of user success
- Remains fully safe

When this goal is achieved consistently, the Butler will feel less like a system asking questions and more like an experienced technician who already knows the easiest way for a person to help diagnose the problem.

---

## Version History

**Version 1.0** — 2026-07-18  
Initial locked specification defining the Evidence Acquisition & Translation Engine, its responsibilities, position in the architecture, observation strategy selection, adaptive communication, and future extensibility.

---

## Implementation Notes

This module defines architecture and responsibilities only.  
It does not define database schemas, APIs, or concrete algorithms.

All future implementation of how evidence requirements are turned into human interactions must conform to the principles and boundaries established in this document.

This document forms part of the permanent Product Bible.

---

*This document is binding. The separation between deciding what evidence is needed and deciding how to obtain that evidence from a human must be preserved in all future implementation.*