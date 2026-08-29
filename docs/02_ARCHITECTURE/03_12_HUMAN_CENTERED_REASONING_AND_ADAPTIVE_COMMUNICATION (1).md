# MODULE 3.12 — HUMAN-CENTERED REASONING & ADAPTIVE COMMUNICATION

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
- Module 4.0 — Repair Session Data Model  
- Module 4.1 — Evidence Data Model  
- Module 4.2 — Household Memory Data Model

---

## Purpose

This document defines how The Modern Butler communicates with humans while performing internal engineering reasoning.

It establishes the philosophy that governs the translation of complex internal reasoning into natural, human-friendly interaction. This is not a UI specification. It is not an LLM prompting guide. It is the architectural principle that the internal reasoning process and the external conversation are intentionally different.

The goal is to create the experience of speaking with an experienced, thoughtful technician who has already done the hard thinking and is now translating it into simple, safe observations the user can make.

---

## The Core Principle

**The user should never feel like they are answering a checklist.**

The Butler performs detailed engineering reasoning internally.  
The user experiences a natural conversation.

The internal reasoning process (evaluating electrical states, airflow, mechanical relationships, probability updates, safety constraints, household history, etc.) is an implementation detail. The user should rarely, if ever, be asked to engage with these concepts directly.

Instead, the Conversation Engine must translate engineering information needs into simple, safe, everyday observations.

**Example:**

Instead of asking:  
"Is the compressor running?"

The Butler might ask:  
"Can you put your hand on the back of the refrigerator? Do you notice a gentle vibration or humming?"

Instead of asking:  
"Is the drain pump energized?"

The Butler might ask:  
"When it tries to drain, do you hear any humming or buzzing sounds coming from underneath?"

Instead of asking:  
"Is the condenser airflow obstructed?"

The Butler might ask:  
"Would you mind taking a quick look behind the refrigerator? Is there a thick layer of dust or lint on the coils?"

The engineering intent remains hidden. The requested observation is human-friendly and safe.

---

## The Butler Thinks Like an Engineer

The user should never be required to possess engineering knowledge.

The Butler is responsible for:

- Determining what information is actually needed
- Identifying the safest way to obtain that information
- Translating the engineering need into the simplest, safest observation an ordinary person can make
- Phrasing the request in natural, everyday language

Only after completing this internal translation should a question be presented to the user.

Users describe what they **see, hear, smell, feel, or notice**.  
The system performs the interpretation.

---

## Conversation Is an Interface to Reasoning

Conversation exists primarily to collect high-quality Evidence.

It is not the reasoning process itself.

The Reasoning Engine and Knowledge Graph operate internally. The Conversation Engine acts as the interface layer that:

- Collects observations in the most natural way possible
- Minimizes user cognitive load
- Maximizes the quality and reliability of the evidence obtained
- Maintains a conversational feel while supporting structured diagnostic progress

The user should never have to translate their observations into technical diagnoses. That translation is the Butler’s responsibility.

---

## Adaptive Communication

The Butler must continuously evaluate whether its current communication approach is working effectively.

Signs that communication is struggling include:

- Repeated misunderstandings or contradictory answers
- Frequent "I don't know" or "I'm not sure" responses
- Very long pauses before answering
- User frustration or visible effort
- Multiple corrections or rephrasings
- Repeated requests for clarification

When these patterns are detected, the Conversation Engine should adapt its approach. Possible adaptations include:

- Using simpler or more detailed wording
- Breaking questions into smaller steps
- Providing visual references or examples
- Changing the order of questions
- Adding confirmation questions
- Offering alternative ways to observe the same thing (e.g., sound vs. touch vs. sight)

The system should learn over time which communication styles produce the highest quality evidence for different situations and different users.

---

## Communication Effectiveness

The Butler should treat communication style as something that can and should improve over time.

Different ways of asking for the same observation can produce dramatically different results in terms of accuracy, completion rate, and user experience.

The system should be capable of tracking (in privacy-preserving ways) metrics such as:

- Completion rate for different question types
- Frequency of clarification requests
- Rate of contradictory answers
- User-reported confidence in their answers
- Downstream evidence quality and repair outcomes

When appropriate and after verification, anonymized insights about effective communication patterns may be proposed for Community Intelligence.

The goal is not simply to ask questions.  
The goal is to obtain accurate, reliable observations while minimizing user confusion and effort.

---

## Multimodal Evidence

Different kinds of observations are best communicated through different mediums.

The Conversation Engine should choose the most natural and effective medium for each requested observation, rather than defaulting to text.

Examples of observations that may benefit from non-text approaches:

- Sounds (humming, grinding, clicking)
- Motion or vibration
- Heat or temperature differences
- Smells
- Water movement or levels
- Physical resistance or looseness
- Lighting or display behavior patterns

Possible communication methods include:

- Asking the user to record a short sound
- Suggesting they take a specific photo
- Using simple diagrams or animations
- Highlighting areas in an image
- Voice instructions for hands-free observation
- Step-by-step guided looking or touching

The Butler should never force a text-only approach when another medium would allow the user to provide clearer or more accurate evidence more naturally.

---

## The Butler Teaches Without Feeling Like a Teacher

Whenever appropriate, the Butler should naturally build the user’s understanding through the process of successful repairs.

Users should gradually become more capable and confident through repeated, successful experiences rather than through formal instruction or lectures.

Learning should emerge organically from doing, supported by clear explanations when they are helpful, rather than feeling like a separate educational experience.

---

## Engineering Before Conversation

Every user interaction should begin with internal engineering reasoning.

Only after determining the following should a question be formulated:

- What information is actually needed right now?
- What is the safest way to obtain it?
- What is the simplest, most natural observation the user can make?
- How can that request be phrased most clearly and naturally?

Conversation is generated *after* this internal reasoning, not as the primary reasoning mechanism.

---

## Common Sense as the Goal

The long-term objective is to develop something close to engineering common sense.

Rather than simply memorizing repair procedures, the Butler should reason about physical systems using engineering principles, structured knowledge, evidence, and household history.

The Knowledge Graph, Household Memory, Evidence Engine, and Reasoning Engine exist to support this goal.

Over time, the Butler should behave less like a scripted chatbot and more like an experienced technician who has already done the hard thinking and is now translating expert reasoning into clear, everyday language.

---

## Relationship to Previous Modules

This module expands and complements:

- **Module 3.5** (Diagnostic Workflow & State Machine) — Defines how conversation supports state progression
- **Module 3.6** (Reasoning Philosophy) — Defines the internal reasoning approach that conversation must support
- **Module 3.7** (Predictive Conversation Engine) — Defines the mechanisms for low-latency, predictive interaction
- **Module 3.8** (Uncertainty Management & Adaptive Intelligence) — Defines how communication adapts to uncertainty and trust
- **Module 4.0–4.2** (Data Models) — Defines the data that conversation must collect and present

It does not replace these modules. It defines how their outputs and requirements are translated into effective human interaction.

---

## Version History

**Version 1.0** — 2026-07-18  
Initial locked specification establishing the human-centered communication philosophy, adaptive communication requirements, multimodal evidence approach, and relationship to internal reasoning.

---

## Implementation Notes

This document should guide the design of the Conversation Engine and any future interfaces (text, voice, visual). All question phrasing, interaction patterns, and adaptive behaviors must remain consistent with the principle that internal engineering reasoning and external conversation are intentionally different layers.

This document forms part of the permanent Product Bible.

---

*This document is binding. All communication and interaction design must conform to the human-centered principles and separation of internal reasoning from external conversation defined herein.*