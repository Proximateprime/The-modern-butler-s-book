# MODULE 5.11 — SESSION RESUME & CONTINUITY

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-19  
**Authority:** Architecture Specification  

**Depends On:**  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 4.0 — Repair Session Data Model

---

## Purpose

This document defines how the Butler handles interrupted diagnostic sessions and resumes them later in a natural, context-aware way.

Users frequently leave mid-diagnosis (phone call, dinner, work, etc.). The system must make returning feel continuous rather than starting over.

---

## Core Principles

1. **Preserve all collected evidence and state.**
2. **Never force the user to re-answer questions they already answered.**
3. **Provide a clear, concise summary of where the session left off.**
4. **Allow the user to continue, review, or abandon cleanly.**

---

## Resume Behavior

When a user returns to an incomplete session, the Butler should:

1. Recognize the existing session.
2. Summarize key progress in plain language (what has been verified, what remains).
3. Offer to continue from the exact point of interruption.
4. Allow the user to review previous evidence or change earlier answers if needed.

**Example tone:**

> “Welcome back. Earlier we confirmed the dryer has power and the door switch appears fine. We still need to check the heating system. Would you like to continue from there?”

---

## Time-Based Considerations

- Short interruptions (minutes to a few hours): Resume with minimal re-confirmation.
- Longer interruptions (days+): Offer a slightly more thorough re-orientation and allow the user to confirm that conditions have not changed.
- Very old sessions: Treat as potentially stale and offer to start a fresh investigation while preserving the old record.

---

## Version History

**Version 1.0** — 2026-07-19  
Initial locked specification for Session Resume & Continuity.

---

*This document is binding. All session interruption and resume behavior must follow these principles.*