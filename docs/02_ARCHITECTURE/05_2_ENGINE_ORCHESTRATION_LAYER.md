# MODULE 5.2 — ENGINE ORCHESTRATION LAYER

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-19  
**Authority:** Architecture Specification  

**Depends On:**  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 3.6 — Reasoning Philosophy  
- Module 4.3 — Evidence Acquisition & Translation Engine  
- Module 5.1 — Risk & Safety Engine

---

## Purpose

The Engine Orchestration Layer defines how all major engines in The Modern Butler’s Book coordinate with one another.

Its purpose is to prevent ad-hoc communication patterns and ensure that every engine interaction follows a clear, consistent, and auditable structure.

Without this layer, different parts of the system risk inventing their own coordination methods, leading to fragile and hard-to-maintain architecture.

---

## Core Principles

1. **The State Machine is the Coordinator**  
   The Diagnostic State Machine (Module 3.5) acts as the primary controller of high-level flow. Engines are invoked according to the current state.

2. **Clear Contracts Between Engines**  
   Every interaction between engines should have well-defined inputs and outputs.

3. **No Hidden Side Effects**  
   Engines should not silently modify shared state. Changes should be explicit and traceable.

4. **Safety Has Veto Power**  
   The Risk & Safety Engine can interrupt any flow at any time.

5. **Loose Coupling**  
   Engines should know as little as possible about the internal implementation of other engines.

---

## Major Engines

- State Machine Controller
- Reasoning Engine
- Evidence Acquisition & Translation Engine
- Conversation Engine
- Evidence Engine
- Risk & Safety Engine
- Household Memory Engine
- Learning Engine
- Root Cause & Prevention Engine
- Knowledge Graph Query Engine

---

## Typical Coordination Pattern

A simplified high-level flow during investigation:

1. State Machine Controller determines the current required action.
2. Reasoning Engine is asked for the next evidence need or hypothesis update.
3. Evidence Acquisition & Translation Engine converts the evidence need into a human interaction.
4. Conversation Engine presents the interaction to the user.
5. User response is structured into Evidence by the Evidence Engine.
6. Reasoning Engine updates hypotheses and confidence.
7. Risk & Safety Engine evaluates the new state.
8. State Machine Controller decides the next state transition.

This pattern should be consistent across most diagnostic activity.

---

## Communication Style

Preferred communication style between engines:

- Explicit request / response messages
- Structured data objects (Evidence, Hypothesis, Risk Assessment, etc.)
- Clear ownership of each data object
- Versioned or timestamped updates where relevant

Direct, tightly coupled method calls between engines should be minimized.

---

## Failure Handling

If any engine fails or returns an error:

- The Orchestration Layer must prevent the session from entering an unsafe or inconsistent state.
- Evidence already collected must be preserved.
- The system should fall back to a safe state (for example, requesting professional help or allowing the user to pause).

---

## Version History

**Version 1.0** — 2026-07-19  
Initial locked specification for the Engine Orchestration Layer.

---

## Implementation Notes

This layer should be designed early. It becomes the “glue” that allows individual engines to be developed and improved somewhat independently.

This document forms part of the permanent Product Bible.

---

*This document is binding. All coordination between engines must follow the principles and patterns defined herein.*