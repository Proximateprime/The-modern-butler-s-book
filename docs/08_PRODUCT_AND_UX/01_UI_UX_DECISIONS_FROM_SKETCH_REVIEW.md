# UI / UX DECISIONS FROM SKETCH REVIEW

**Status:** Implementation Guidance  
**Date:** 2026-07-21  
**Authority:** Product Decision Record  

**Depends On:**  
- Butler Communication Personality  
- Module 3.12 — Human-Centered Reasoning  
- Two-Week MVP Acceptance Checklist  
- MVP Scope Lock

---

## Purpose

Record agreed UI/UX decisions from the first hand-drawn repair UI review so Cursor does not invent conflicting patterns.

This is **not** new architecture.  
This is product/UX guidance for implementation.

---

## Agreed Decisions

### 1. Fixed questionnaire layout
The repair questionnaire screen structure stays stable during a session.

Only these change:
- current question
- supporting image/video if any
- answer controls
- progress indicators

Why: muscle memory during longer repairs.

### 2. Permanent elements during questionnaire
Keep visible:
- appliance name/model
- safety indicator light (Green / Yellow / Orange / Red)
- evidence / clues collected
- current path
- “Something else I noticed” observation box
- back navigation
- exit repair

### 3. Observation box naming
Use:

> Something else I noticed

Not generic “Notes.”

Purpose: capture useful observations that are not direct answers to the current question  
Examples: burning smell, water under machine, earlier loud pop.

This still becomes Evidence. It is not freeform junk storage.

### 4. Diagnosis screen order
Present in this order:

1. Most Likely Cause  
2. Why I Think This  
3. What You Observed  
4. Other Possibilities (collapsed)  
5. Next Steps  

### 5. Verification remains mandatory philosophy
Whenever practical, verify before recommending parts purchases.

Already aligned with Product Bible.

### 6. Confidence display
Do **not** keep confidence permanently visible during early questioning.

Show confidence when it becomes meaningful:
- diagnosis summary
- verification complete
- final recommendation

### 7. Technical vocabulary policy
New UX principle:

> **Speak Human. Record Engineering.**

During the live repair flow:
- plain language
- observational language
- minimal jargon

In reports / Household Memory:
- precise engineering terms
- official component names
- durable technical record

### 8. Theme proposal: Butler’s Book
Future appearance option:
- Modern
- Dark
- Butler’s Book

Butler’s Book characteristics:
- cream paper background
- subtle page-flip animations
- history presented like a household ledger
- not exaggerated old-parchment cosplay
- animations optional / disableable

This is identity polish, not MVP-critical.

---

## Deferred Beyond 2-Week MVP

These are good ideas, but **not required** for the first acceptance checklist:

### Repair Readiness
Before verification/repair, optionally check whether the user has:
- required tools
- replacement part
- required skill level

Goal is good, but full readiness gating is post-core-loop.

### Tool ownership integration
Household Memory remembering owned tools is valuable later.
Do not block the first diagnostic loop on this.

---

## 2-Week Implementation Guidance

For the first coding push, prioritize only:

- stable question screen structure
- clear evidence collection
- “Something else I noticed”
- simple diagnosis summary order
- verification step
- human-facing wording
- safety indicator if easy; otherwise minimal safety messaging is acceptable at first

Do not delay the core loop for themes, tool inventory, or full readiness systems.

---

## Version History

**Version 1.0** — 2026-07-21  
Recorded sketch-review UI/UX decisions and separated MVP-critical items from later polish.

---

*UI may evolve, but these decisions should not be casually contradicted.*