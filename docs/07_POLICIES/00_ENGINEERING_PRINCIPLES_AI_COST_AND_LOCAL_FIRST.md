# ENGINEERING PRINCIPLES — AI COST & LOCAL-FIRST

**Status:** Locked Engineering Decision  
**Version:** 1.0  
**Date:** 2026-07-20  
**Authority:** Engineering Specification  

**Depends On:**  
- Design Principles  
- Module 3.6 — Reasoning Philosophy & Hybrid Intelligence  
- Module 4.3 — Evidence Acquisition & Translation Engine  
- MVP Scope Lock

---

## Purpose

This document records two critical engineering principles that must guide implementation:

1. AI operating cost is a first-class engineering constraint.
2. The system should prefer local, deterministic, and cached computation whenever possible.

These principles exist to keep the Butler scalable, affordable, and reliable over time.

---

## 1. AI Cost as a First-Class Constraint

The architecture is intentionally designed so that:

- Structured Reasoning performs diagnosis
- The Knowledge Graph provides engineering knowledge
- Confidence and Question Selection are deterministic where possible
- The LLM primarily translates already-computed reasoning into natural language

**Core Rule:**

> The Butler should never ask an LLM to solve a problem that has already been solved by deterministic reasoning or the Knowledge Graph.

Every feature must be evaluated for:

- Token usage
- Number of model calls
- Long-term operating cost
- Scalability under real usage

AI should be used where it adds genuine value (natural language, explanation, flexible translation). It should not be used as a general-purpose substitute for structured logic.

---

## 2. Local-First Philosophy

Prefer the following whenever practical:

- Local computation
- Deterministic algorithms
- Downloadable / cached assets
- Stored engineering knowledge
- Precomputed diagrams, 3D models, and repair guidance

### Examples

Once an appliance and repair step are known, the following should generally be local:

- AR overlays
- 3D component visualization
- Screw locations
- Panel removal guidance
- Static diagrams and animations

These should not require repeated cloud AI calls.

Vision AI may be added later for optional verification, but continuous AI video analysis is intentionally outside MVP scope.

---

## Design Intent

These principles protect:

- Operating costs
- Offline capability
- Predictability
- Testability
- Long-term scalability

They also reinforce the hybrid architecture: structured systems do the heavy diagnostic work; the LLM assists with communication.

---

## Version History

**Version 1.0** — 2026-07-20  
Initial locked engineering principles for AI cost control and local-first design.

---

*This document is binding for implementation decisions involving AI usage and local vs cloud computation.*