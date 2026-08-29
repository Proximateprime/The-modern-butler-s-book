# USER-FACING STATUS AND ERROR LANGUAGE

**Status:** Implementation Specification  
**Version:** 1.0  
**Date:** 2026-07-20  
**Authority:** Engineering Specification  

**Depends On:**  
- Butler Communication Personality  
- Error Taxonomy  
- Module 5.12 — Failure Recovery

---

## Purpose

The Butler should never communicate failure like a broken server.

Bad:
- Unknown error
- Something went wrong
- Request failed

Better:
- Clear statement of what happened
- What the user can do next
- Whether progress was preserved

---

## Language Patterns

### Not enough evidence
“I don’t have enough information yet to choose a safe next step. Let’s gather one more observation.”

### Safety stop
“This path needs professional service because it involves risks I won’t guide you through.”

### Temporary technical problem
“I hit a temporary problem continuing that step. Your session progress is saved. You can retry or continue with what we already know.”

### Missing knowledge package / offline limit
“I don’t have enough local knowledge for this part yet. We can continue with basic checks, or try again when the package is available.”

### User cancellation
“Okay — we can stop here. Your progress is saved if you want to continue later.”

---

## Rules

1. Preserve dignity
2. Preserve progress when possible
3. Explain the blocker in plain language
4. Offer a next action
5. Never bluff past uncertainty

---

## Version History

**Version 1.0** — 2026-07-20  
Initial user-facing status and error language guidance.

---

*Implementation should prefer these patterns over generic technical errors.*