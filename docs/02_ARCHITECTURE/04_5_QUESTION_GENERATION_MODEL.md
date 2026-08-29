# MODULE 4.5 — QUESTION GENERATION MODEL

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-18  
**Authority:** Architecture Specification  
**Depends On:**  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 3.7 — Predictive Conversation Engine  
- Module 3.8 — Uncertainty Management & Adaptive Intelligence  
- Module 4.4 — Reasoning Data Flow

---

## Purpose

This document defines the **Question Generation Model** — how the Butler decides what question to ask next during a diagnostic session.

It consolidates all previously discussed principles around question selection into one coherent specification.

---

## Core Principles

Question generation must follow these principles:

- **Highest Information Gain** — Prefer questions that most reduce uncertainty across active hypotheses.
- **Safety First** — Never ask a question that could lead the user into an unsafe action.
- **Accessibility** — Prefer easier/safer questions before difficult ones (e.g., visual checks before requiring tools).
- **Avoid Duplication** — Do not ask questions whose answers are already known from previous evidence or Household Memory.
- **Context Awareness** — Use current evidence, appliance type, household history, and user skill signals.
- **Predictive Preparation** — Prepare likely next questions in advance to reduce latency.

---

## Factors for Question Selection

When choosing the next question, the system should consider:

| Factor                        | Weight | Description |
|-------------------------------|--------|-----------|
| Expected reduction in uncertainty | High   | How much the answer is expected to change hypothesis rankings |
| Safety impact                 | Very High | Whether answering requires potentially dangerous actions |
| Difficulty for user           | High   | How easy it is for the user to answer (visual vs measurement) |
| Tool / disassembly required   | Medium | Whether special tools or opening the appliance is needed |
| Household history relevance   | Medium | Whether prior root causes make this question more valuable |
| Likelihood of eliminating hypotheses | High | Chance the answer will rule out one or more possibilities |
| User skill / confidence       | Medium | Adapt question complexity based on user signals |

The system should select the question with the highest overall value while respecting safety constraints.

---

## Predictive & Adaptive Behavior

- While the user is answering the current question, the system should pre-generate the most likely next questions for probable answers.
- If new evidence arrives that significantly changes the hypothesis set, pending predicted questions should be re-evaluated or discarded.
- The system should avoid asking questions that have already been effectively answered by previous evidence.

---

## Version History

**Version 1.0** — 2026-07-18  
Initial locked specification for the Question Generation Model.

---

## Implementation Notes

This model should be used by the Conversation Engine in coordination with the Reasoning Engine. It directly supports the Adaptive Question Selection state in Module 3.5 and the predictive behavior defined in Module 3.7.

---

*This document is binding. All question selection logic must follow the principles and factors defined herein.*