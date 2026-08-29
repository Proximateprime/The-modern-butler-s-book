# MODULE 6.4 — REASONING EXPLAINABILITY ENGINE

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-19  
**Authority:** Architecture Specification  

**Depends On:**  
- Module 3.10 — Confidence & Explainability Policy  
- Module 3.12 — Human-Centered Reasoning & Adaptive Communication  
- Module 5.5 — Confidence & Decision Engine

---

## Purpose

The Reasoning Explainability Engine is responsible for generating clear, structured, user-facing explanations of why the Butler is asking questions, why it believes certain hypotheses, and why it is making particular recommendations.

This is distinct from the Reasoning Engine itself. The Reasoning Engine reaches conclusions. The Explainability Engine translates the relevant parts of that reasoning into understandable explanations.

---

## Core Requirements

The system must be able to answer, in plain language:

- Why was this question asked?
- Why is this hypothesis currently leading?
- Why was another hypothesis reduced or eliminated?
- Why did confidence change after the last piece of evidence?
- Why is the system recommending a particular action or professional help?
- Why did the system stop investigating?

---

## Explanation Principles

- Explanations should reference evidence and relationships, not internal chain-of-thought.
- Explanations should increase user understanding.
- Explanations should be available on demand without forcing them on the user.
- Explanations must remain consistent with Safety and Privacy constraints.

---

## Example Explanation Style

> “I asked whether both the refrigerator and freezer were warm because if they are, the shared cooling system is more likely at fault than a single compartment damper.”

> “I am not asking about the condenser fan right now because earlier observations made that possibility much less likely.”

> “I recommend professional service because two remaining possibilities both require high-voltage testing that is outside safe guidance.”

---

## Version History

**Version 1.0** — 2026-07-19  
Initial locked specification for the Reasoning Explainability Engine.

---

*This document is binding. All user-facing explanations of reasoning must follow the principles defined herein.*