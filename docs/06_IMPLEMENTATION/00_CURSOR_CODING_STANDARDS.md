# CURSOR CODING STANDARDS

**Status:** Implementation Guidance  
**Version:** 1.0  
**Date:** 2026-07-20  
**Authority:** Pre-Cursor Preparation  

**Depends On:**  
- Engineering Style Guide  
- MVP Acceptance Checklist  
- Product Bible locked modules

---

## Purpose

When Cursor generates a lot of code quickly, quality drifts unless rules are explicit.

These standards exist to keep the first implementation coherent.

---

## Required Rules

1. **Follow the Product Bible**  
   Do not invent new engines, states, or safety behavior.

2. **Name things clearly**  
   Prefer explicit names over clever short ones.

3. **Keep side effects obvious**  
   Especially for session state, evidence writes, and safety decisions.

4. **Centralize AI calls**  
   All model access goes through the AI Service Interface.

5. **Deterministic core stays deterministic**  
   Do not hide safety, confidence, or ranking decisions inside free-form prompts.

6. **Log useful diagnostic context**  
   Enough to reconstruct what happened in a session path.

7. **Fail safely**  
   On uncertainty or failure, preserve evidence and avoid unsafe guidance.

8. **Write the smallest code that satisfies the acceptance checklist**  
   No speculative architecture during the 2-week push.

---

## Suggested Project Habits

- One clear module boundary per responsibility
- Shared types for Evidence, Session, Hypothesis, SafetyDecision
- Explicit error types from the Error Taxonomy
- Tests for:
  - one successful dryer path
  - one safety-stop path
  - session save/resume basics

---

## Code Review Questions

Every generated chunk should be checked against:

- Does this implement the Product Bible?
- Does it leak secrets?
- Is it deterministic where required?
- Is it testable?
- Is there a cheaper/local approach?
- Does it stay inside the 2-week acceptance checklist?

---

## Version History

**Version 1.0** — 2026-07-20  
Initial Cursor coding standards for the first implementation push.

---

*These standards are intentionally strict during the first build.*