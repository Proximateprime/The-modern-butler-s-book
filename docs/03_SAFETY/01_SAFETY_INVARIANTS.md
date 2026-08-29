# SAFETY INVARIANTS
## The Modern Butler's Book  
**Status:** Locked — Non-Negotiable  
**Version:** 1.0  
**Date:** 2026-07-16  
**Authority:** Highest. Overrides any other document or feature request.

---

## Purpose

These rules exist to keep users safe, protect the company from liability, and preserve long-term trust.  
They apply to **every** skill level, including Expert Mode and verified adult users.

---

## 1. Hard Safety Gates (Never Unlock)

The following categories of guidance are **permanently restricted** at every skill level:

- Internal electrical work (opening live electrical panels, working on wiring, live circuits, control boards under power)
- Gas appliances or gas lines (any intervention involving gas valves, gas supply, burners, or gas components)
- Sealed refrigerant systems (any work that would open or puncture sealed cooling systems)
- High-pressure systems that require specialized certification
- Structural modifications or heavy structural lifting beyond normal appliance movement
- Any action the Risk & Safety Engine classifies as High Risk when confidence is low or conditions are unclear

**What the app MAY do in these areas:**
- Help the user understand symptoms and gather evidence
- Explain how systems generally work (high-level)
- Help prepare a clear summary for a professional technician
- Recommend calling a licensed professional
- Show external observation steps that do not require opening dangerous systems

**What the app must NEVER do:**
- Provide step-by-step instructions that involve opening live electrical compartments
- Guide users to work on gas components
- Instruct users to release refrigerant or open sealed systems
- Suggest bypassing safety devices or interlocks
- Claim that a high-risk repair is “safe enough” for DIY

---

## 2. Skill-Level Adaptation Rules

Skill level **does** adapt:

- Explanation depth and terminology
- Amount of scaffolding and “why this matters”
- Visual density (AR, diagrams)
- Number of simultaneous options
- Preparation checklists and time estimates
- Verification strictness
- Tone and number of safety reminders

Skill level **does NOT**:

- Unlock hard-gated categories listed above
- Reduce the requirement for professional recommendation when risk is high
- Allow the app to skip Risk Engine evaluation
- Let Expert Mode override Safety Gates

**Expert Mode (Adults Only)** means:
- Richer technical context
- Better system explanations
- More precise AR risk visualization
- Stronger pre-step checklists and PPE reminders
- Clearer packaging of “this is the limit — call a certified technician”
- Still no how-to for hard-gated work

---

## 3. Risk Engine Authority

The Risk & Safety Engine has **final authority**.

- It can override or restrict any guidance proposed by the Reasoning Engine.
- Low confidence + elevated risk → prefer observation or professional recommendation.
- The UI and Conversation Engine must never hide or soften a Safety Gate message.

---

## 4. Communication Requirements

Whenever guidance is limited:

- Explain *why* clearly and calmly.
- Use language such as:  
  “This area involves risks that require specialized training and equipment. I can help you understand the symptoms and prepare information for a professional.”
- Never make the user feel stupid or blamed.
- Always leave the final decision with the user while remaining firm on safety.

---

## 5. Progressive Unlocking Philosophy

Progression is about **understanding and safe observation**, not permission to perform dangerous physical work.

Users grow by:
- Completing verified safe sessions
- Demonstrating good observation habits
- Building real household memory
- Learning system relationships

They never “earn” the right to receive high-risk intervention instructions from the app.

---

## 6. Enforcement Points

These invariants must be checked at:

- Candidate generation
- Question selection
- Guidance packaging
- Explanation generation
- Learning update proposals
- Any future “advanced mode” or professional features

---

## 7. Change Control

Any proposed change to these Safety Invariants requires:

1. Explicit written justification
2. Review against liability and user-safety impact
3. Versioned update to this document
4. Communication to all contributors and AI code-generation prompts

Until that process is completed, these rules stand.

---

## One-Sentence Summary

**Skill level makes the Butler a better teacher and safer guide. It never turns the Butler into a guide for high-risk electrical, gas, or sealed-system work.**

---

*This document is the highest-priority safety reference in the entire handbook. Every volume and every line of code must remain consistent with it.*