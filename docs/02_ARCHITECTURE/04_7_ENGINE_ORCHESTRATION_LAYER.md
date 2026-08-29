# MODULE 4.7 — ENGINE ORCHESTRATION LAYER

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-18  
**Authority:** Architecture Specification  
**Depends On:**  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 3.6 — Reasoning Philosophy & Hybrid Intelligence  
- Module 4.4 — Reasoning Data Flow

---

## Purpose

This document defines the **Engine Orchestration Layer** — how the various engines in the system coordinate and communicate during a diagnostic session.

The goal is to provide clear boundaries and interaction patterns so that implementation remains maintainable and consistent with the architecture.

---

## Core Engines

- **State Machine Controller**
- **Reasoning Engine**
- **Conversation Engine**
- **Evidence Engine**
- **Risk & Safety Engine**
- **Household Memory Engine**
- **Learning Engine**
- **Root Cause & Prevention Engine**

---

## Orchestration Principles

1. **Clear Responsibility Boundaries**  
   Each engine owns specific responsibilities and should not duplicate work belonging to another engine.

2. **State Machine as Coordinator**  
   The State Machine Controller acts as the central coordinator. Other engines are called as needed based on the current state.

3. **Event-Driven Interaction**  
   Engines communicate primarily through well-defined events and data objects rather than direct method calls where possible.

4. **Evidence as Central Currency**  
   Most engine interactions revolve around creating, reading, or updating Evidence and Hypothesis objects.

---

## Typical Interaction Pattern

Example flow during the Investigation Loop:

1. **State Machine Controller** determines current state requires question selection.
2. It requests the **Reasoning Engine** to evaluate current hypotheses and suggest the best next question.
3. **Reasoning Engine** consults **Evidence Engine** and **Knowledge Graph**.
4. **Conversation Engine** presents the question to the user.
5. New Evidence is created via **Evidence Engine**.
6. **Reasoning Engine** updates hypotheses and confidence.
7. **Risk & Safety Engine** evaluates the current state.
8. **State Machine Controller** decides the next state transition.

---

## Version History

**Version 1.0** — 2026-07-18  
Initial locked specification for the Engine Orchestration Layer.

---

## Implementation Notes

The orchestration layer should be designed to keep engines loosely coupled while maintaining clear data contracts. This will make future changes and additions easier to manage.

---

*This document is binding. All engine interactions must respect the responsibilities and coordination patterns defined herein.*