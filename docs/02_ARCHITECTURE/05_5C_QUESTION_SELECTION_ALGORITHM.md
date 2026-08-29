# MODULE 5.5C — QUESTION SELECTION ALGORITHM

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-19  
**Authority:** Architecture Specification  

**Depends On:**  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 3.7 — Predictive Conversation Engine  
- Module 4.3 — Evidence Acquisition & Translation Engine  
- Module 4.5 — Question Generation Model  
- Module 5.5 — Confidence & Decision Engine  
- Module 5.5B — Confidence Calculation Rules  
- Module 5.1 — Risk & Safety Engine  
- Design Principles

---

## Purpose

This document defines how the Butler selects the **next best question** (or observation request) during a diagnostic session.

The system already knows that it should ask adaptive, high-value questions.  
This document makes the selection policy explicit so that different implementations behave consistently.

This is **not** a new engine.  
It is a formal decision policy used by the Reasoning Engine and Evidence Acquisition & Translation Engine.

---

## Core Principle

The Butler does not ask questions randomly, in fixed order, or simply to prolong conversation.

It selects the observation request that is expected to produce the best overall outcome for the user, considering:

- Reduction of diagnostic uncertainty
- Safety
- User effort
- Reliability of the resulting evidence
- Current confidence and remaining hypotheses

This aligns with the principle: **Optimize for Outcome, Not Conversation Speed**.

---

## Question Utility Model

Every candidate question / observation request is scored across multiple dimensions.

Conceptual model:

```
Question Utility ≈
    Information Gain
  + Safety Value
  + Diagnostic Discrimination
  − User Effort
  − Required Skill Burden
  − Time Cost
  + Evidence Reliability Bonus
```

The exact weighting may be tuned over time. The architecture requires that these dimensions are considered.

---

## Scoring Dimensions

### 1. Information Gain
How much is this answer expected to reduce uncertainty across the current set of candidate failure modes?

Higher when:
- The answer is likely to eliminate one or more strong hypotheses
- The question splits the remaining probability mass effectively

### 2. Safety Value
Does this question help identify or rule out a hazardous condition?

Safety-related questions may override pure information gain when appropriate.  
Hard safety constraints from the Risk & Safety Engine always take priority.

### 3. Diagnostic Discrimination
How effectively does this question distinguish between the currently leading hypotheses?

### 4. User Effort
How much physical or cognitive effort is required?

Examples of lower effort:
- Looking at a display
- Listening for a sound
- Checking whether a door is closed

Examples of higher effort:
- Moving an appliance
- Removing panels
- Using tools

When diagnostic value is similar, lower-effort questions are preferred.

### 5. Required Skill / Accessibility
Does the user need special knowledge, tools, or physical ability to answer reliably?

The system should prefer questions the current user can answer successfully.  
This may be informed by the user’s Repair Confidence Profile (when available).

### 6. Time Cost
How long is the observation expected to take?

Faster checks are preferred when value is otherwise similar.

### 7. Evidence Reliability
How objective and trustworthy is the resulting evidence likely to be?

Prefer:
- Clear visual checks
- Distinct sounds
- Binary or low-ambiguity observations

Over:
- Highly subjective judgments
- Ambiguous “does it seem normal?” questions

---

## Selection Policy

At each decision point the system should:

1. Generate a set of candidate observation requests that could provide useful evidence.
2. Eliminate any candidates blocked by the Risk & Safety Engine.
3. Score remaining candidates using the dimensions above.
4. Select the highest-utility safe candidate.
5. Pass the selected request to the Evidence Acquisition & Translation Engine for human-friendly phrasing and method selection.

---

## Stopping Consideration

Question selection is tightly linked to the decision of whether to ask another question at all.

The system should stop asking further questions when:

- Expected information gain of remaining candidates is low
- Confidence is sufficient and safety checks pass
- Further questions are unlikely to improve the final outcome enough to justify the cost
- The user indicates they want to stop or escalate

This again follows: optimize for outcome, not for asking more questions.

---

## Explainability Requirement

The system must be able to explain why a particular question was selected.

Example style:

> “I asked whether the washer fills with water because that answer most effectively distinguishes between a water supply issue, a lid switch problem, and a control issue, while requiring no tools.”

This capability depends on the selection dimensions being explicit.

---

## Relationship to Other Modules

- **Reasoning Engine** determines what evidence would be valuable.
- **This policy** ranks which candidate observation is best to request next.
- **Evidence Acquisition & Translation Engine** turns the chosen evidence need into the best human interaction.
- **Conversation Engine** presents it.
- **Risk & Safety Engine** can veto any candidate.
- **Confidence & Decision Engine** uses the resulting evidence to update beliefs and decide whether to continue.

---

## Version History

**Version 1.0** — 2026-07-19  
Initial locked specification of the Question Selection Algorithm and utility dimensions.

---

*This document is binding. All implementations of next-question selection must consider the dimensions and priorities defined herein.*