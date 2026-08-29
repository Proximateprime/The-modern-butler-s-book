# ENGINEERING STYLE GUIDE

**Status:** Implementation Guidance  
**Date:** 2026-07-20  
**Authority:** Pre-Cursor Preparation  

---

## Purpose
Keep implementation aligned with the Product Bible when multiple AI tools and rapid coding are involved.

---

## Non-Negotiable Rules

1. **Product Bible is authoritative**  
   Do not invent engines, states, or safety behavior that contradict locked modules.

2. **Deterministic core, flexible communication**  
   Diagnosis, confidence direction, safety gates, and question selection policy must be stable.  
   Natural language phrasing may vary.

3. **Observation before conclusion**  
   Users provide observations. The system interprets.

4. **Safety gates are hard**  
   No feature may bypass Risk & Safety decisions.

5. **Local / deterministic before cloud AI**  
   Do not use an LLM to re-solve problems already solved by structured logic or the Knowledge Graph.

6. **MVP scope is law during the 2-week push**  
   If it is not required for the acceptance checklist, it waits.

---

## Code Organization Preferences

- Prefer clear module boundaries matching engines/responsibilities
- Keep side effects explicit
- Prefer simple readable code over clever abstractions early
- Make state transitions obvious
- Log enough to debug a diagnostic path

---

## AI Usage in Code

- LLM is for translation, explanation, and natural phrasing
- Structured systems own:
  - hypothesis ranking
  - confidence updates
  - safety decisions
  - next-question selection policy
- Never let prompt output silently become a safety decision

---

## Testing Expectations (Minimum)

- At least one full dryer path can be run repeatedly
- Safety block path can be demonstrated
- Session save/resume does not lose core evidence

---

## What to Do When Unsure

1. Check Design Principles
2. Check MVP Acceptance Checklist
3. Check relevant locked module
4. Choose the smaller, safer implementation

---

*This guide exists to prevent elegant architecture from turning into messy code under time pressure.*