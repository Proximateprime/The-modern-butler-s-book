# MODULE 3.7 — PREDICTIVE CONVERSATION ENGINE

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
- Critical Design Decisions Addendum (2026-07-17)

---

## Purpose

This document defines how the Butler conducts intelligent, low-latency conversations during troubleshooting.

The Conversation Engine is responsible for presenting questions, managing conversational flow, predicting likely user responses, pre-computing future conversation branches, and minimizing perceived latency. It works in close coordination with the Reasoning Engine and the state machine defined in Module 3.5, but it is a distinct component.

The goal is to make the diagnostic conversation feel natural, responsive, and prepared — as if the Butler is already thinking several steps ahead — while remaining fully grounded in evidence and safety constraints.

This specification is binding on the Conversation Engine and all components that manage user interaction during diagnostic sessions.

---

## Core Principles

The Conversation Engine operates under the following principles:

- **Predictive Preparation** — The system prepares likely next steps while the user is still processing the current question.
- **Information Gain Priority** — Questions are selected based on how much uncertainty they reduce, not on random or sequential order.
- **Dynamic Adaptation** — The conversation continuously adapts to new evidence, changing confidence, and safety constraints.
- **Low Perceived Latency** — The user should rarely feel like they are waiting for the system.
- **Explainability** — The system must be able to explain why a question was chosen and why previous questions were skipped or deprioritized.
- **Offline Capability** — Predictive conversation must function without internet when sufficient local knowledge is available.
- **Safety Integration** — The Conversation Engine must respect all decisions from the Risk & Safety Engine.

---

## Predictive Question Generation

While the user is reading or considering Question N, the Conversation Engine should begin preparing likely Question N+1 branches in the background.

For any given question, the system generates predicted follow-up questions for the most probable user responses before the user answers. When the user selects an answer, the next question should appear with minimal or no delay.

This predictive generation is based on:

- Current evidence and hypotheses
- The current state in the diagnostic state machine
- Appliance type and household history
- Common response patterns for similar situations

The system maintains multiple prepared branches and discards lower-probability ones as new information arrives.

---

## Branch Prediction

The Conversation Engine predicts the most likely user responses to each question. Predictions are based on:

- Current evidence set
- Active hypotheses and their confidence scores
- Appliance category and known characteristics
- Household Memory (previous behavior and answers)
- General patterns observed across similar diagnostic sessions

Common predicted response categories include:

- Boolean answers (Yes / No)
- Multiple-choice selections
- “Not sure” or “I don’t know”
- “Unable to perform” or “I can’t check that”
- Skipped or declined questions
- Common interpretations of free-text answers

The engine continuously updates its predictions as new evidence is collected.

---

## Question Cache

The Conversation Engine maintains a temporary cache of predicted conversation branches. This cache prioritizes branches with the highest predicted probability and information gain.

Cache management follows these rules:

- High-probability branches are pre-computed and stored.
- Low-probability branches may be discarded or computed on demand.
- The cache is updated whenever new evidence significantly changes hypothesis rankings.
- Unused branches are automatically cleared when they are no longer relevant.
- Cache size is managed to balance responsiveness with resource usage.

The cache exists to reduce latency and is not considered permanent storage.

---

## Information Gain

The Conversation Engine does not ask questions randomly or in fixed order. Every candidate question is evaluated based on its expected information gain.

Factors considered when selecting the next question include:

- Expected reduction in uncertainty across active hypotheses
- Safety impact of the information
- Difficulty and accessibility for the user
- Whether tools or partial disassembly are required
- Likelihood of eliminating one or more hypotheses
- Alignment with the current state in the diagnostic state machine

The system selects the question that provides the highest safe information gain at that moment.

---

## Dynamic Conversations

Conversations are not strictly linear. Every user answer can trigger multiple effects, including:

- Increasing or decreasing confidence in one or more hypotheses
- Eliminating hypotheses
- Generating new hypotheses
- Triggering safety rules or risk re-evaluation
- Returning to a previous investigation path
- Changing the priority of remaining questions

The Conversation Engine continuously adapts the active conversation path based on the latest evidence and state machine requirements.

---

## Latency Goals

The architecture targets the following latency behavior:

- The next question should appear **instantly** from the user’s perspective whenever possible.
- Background prediction and pre-computation should occur while the user is reading the current question.
- Cloud-based reasoning, when used, should overlap with user reading time rather than blocking the conversation.
- Offline reasoning should be preferred when local knowledge is sufficient.

The guiding principle is that the user should perceive little or no waiting time between their answer and the next relevant question.

---

## Offline Compatibility

The Conversation Engine must support predictive questioning in offline mode whenever sufficient local knowledge (from the Knowledge Graph, Household Memory, and cached predictions) exists.

Cloud reasoning may enhance conversations by providing more accurate branch predictions or deeper analysis, but it should not be required for every question. The system must gracefully degrade to offline predictive behavior when connectivity is limited or unavailable.

---

## Explainability

The Conversation Engine must be able to explain its decisions at any point, including:

- Why this specific question was selected as the next best question
- Why previous questions were skipped or deprioritized
- Why another branch became higher priority
- Why confidence in certain hypotheses changed after a user response
- Why the system is preparing certain future questions

Explanations must be available to the user in clear language.

---

## Failure Recovery

The Conversation Engine must handle the following situations without losing evidence or creating unsafe states:

- Incorrect predictions (user gives an unexpected answer)
- Cloud request failures
- Transition to offline mode
- New evidence that invalidates previously cached branches
- User changing a previous answer
- Conversation interruption or session pause

In all cases, the system must preserve existing evidence, allow the user to continue from the current state, and fall back to non-predictive questioning if necessary.

---

## Future Compatibility

The Conversation Engine architecture must remain compatible with future interaction methods and technologies, including:

- Voice-based conversations
- Text-based conversations
- Photo-guided conversations
- AR-guided conversations
- Multiple AI model providers
- Local on-device models
- Future symbolic or hybrid reasoning systems

The core principles of predictive preparation, information gain, and low-latency interaction must remain stable across these variations.

---

## Responsibilities

**Conversation Engine**  
Primary owner of question selection, branch prediction, cache management, and user-facing conversational flow. Works in coordination with the Reasoning Engine and State Machine Controller.

**Reasoning Engine**  
Provides hypothesis rankings, confidence scores, and information gain estimates that the Conversation Engine uses to select and prioritize questions.

**State Machine Controller**  
Ensures that question selection and conversation flow remain consistent with the required states and transitions defined in Module 3.5.

**Risk & Safety Engine**  
May interrupt or redirect conversation flow at any time based on safety evaluation.

**Household Memory Engine**  
Provides historical context that can influence branch prediction and question prioritization.

---

## State Interaction

The Conversation Engine operates within the states defined in Module 3.5. It is particularly active during:

- Collect Initial Observations
- Adaptive Question Selection & Evidence Collection
- Generate Safe Guidance
- User Performs Action + Verification

It must respect state transitions and never allow the user to bypass required phases through conversational shortcuts.

---

## Design Philosophy

The Butler should feel like an experienced technician who is already thinking several steps ahead. The user should never feel like they are waiting for the system to decide what to ask next. Instead, the conversation should feel prepared, responsive, and naturally flowing while remaining safe, evidence-based, and explainable.

---

## Version History

**Version 1.0** — 2026-07-18  
Initial locked specification defining the predictive conversation architecture, branch prediction, cache management, information gain, latency goals, and integration with the diagnostic state machine.

---

## Implementation Notes

This document defines the required behavior and constraints for the Conversation Engine. All implementation of question selection, predictive pre-computation, caching, and conversational flow must conform to the principles and requirements stated here.

This document forms part of the permanent Product Bible. Any changes to conversational behavior must be evaluated against this specification and Module 3.5.

---

*This document is binding. All conversational and predictive behavior in diagnostic sessions must conform to the architecture and constraints defined herein.*