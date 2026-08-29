# CURSOR IMPLEMENTATION CHARTER
## The Modern Butler’s Book — Phase 1 Kickoff

**Status:** Binding for all Cursor work  
**Date:** 2026-07-21  
**Authority:** Founder + Product Bible  

This is the single authoritative onboarding document for Cursor (and any future developer).

Read this document fully before writing any significant code.

**Feature freeze (2026-08-17):** [`docs/FEATURE_FREEZE.md`](../FEATURE_FREEZE.md). After freeze, **bugfixes only**. No new appliances, ranking redesign, or cloud sync.

---

## 1. Mission

Help ordinary people safely understand, diagnose, repair, and maintain the systems in their homes — without requiring them to think like professional technicians.

The Butler prioritizes:
- Safety over completion
- Observation before conclusion
- Verification before learning
- Deterministic reasoning over LLM guessing
- Long-term trust over short-term cleverness

---

## 2. Current Goal (Two-Week Sprint)

**Not polish. Not full knowledge coverage. Not public platform. Not perfect UI.**

Success = a working core diagnostic loop on Dryer:

1. User can create / select a Dryer
2. User can start a Repair Session
3. System asks observation-based questions
4. Evidence is collected and stored
5. Hypotheses are ranked from the Knowledge Package
6. Safety gates are respected
7. System can reach safe guidance or clear escalation
8. Session can be saved and resumed at a basic level

Reference: `01_TWO_WEEK_MVP_ACCEPTANCE_CHECKLIST.md`

---

## 3. Deterministic Core Principle (Non-Negotiable)

All diagnostic reasoning, confidence updates, safety decisions, question selection, and investigation flow **must be deterministic** and fully testable without an LLM.

Language models may only be used for:
- Natural language phrasing of already-decided questions
- Explanations
- Soft educational content

They must never be the sole source of diagnostic logic or safety-critical decisions.

---

## 4. Engineering Simplifications (Locked)

You must follow these rules:

- Use a shared `DecisionContext` — no engine keeps private copies of hypotheses, confidence, or safety state
- `SessionOutcome` is the single source of truth for Root Cause + Prevention
- Reasoning only emits an `EvidenceRequest`; Conversation only consumes it
- One function decides whether to continue: `should_continue_investigation(DecisionContext)`
- Runtime only sees loaded Knowledge Packages + Household Memory
- **No user-visible guidance may bypass the deterministic Safety Validator**
- User-facing confidence is only Low / Medium / High during this sprint

---

## 5. Safety Invariants (Hard Gates)

These never unlock for any skill level:

- No live internal electrical work guidance
- No gas appliance / gas line work
- No sealed refrigerant system work
- No bypassing of safety devices (thermal fuses, door switches, interlocks)

The Safety Validator has the final word on every message that reaches the user.

---

## 6. Preferred Folder Structure (Starting Point)

```
/app                 # UI / screens / navigation
/domain              # core domain types (DecisionContext, Evidence, etc.)
/reasoning           # ranking, confidence, question selection, stopping
/knowledge           # packages, loading, seed data
/household           # appliances, memory, history
/communication       # phrasing, explanations
/security            # auth, privacy helpers
/api                 # AI Service Interface only
/tests               # scenario tests, safety tests
/docs                # Product Bible exports
```

Do not invent major new top-level folders without discussion.

---

## 7. Shared Interfaces (Define These Early)

Create these core types first. Every module must use them instead of inventing local versions:

- `DecisionContext`
- `Evidence`
- `EvidenceRequest`
- `SessionOutcome`
- `KnowledgePackage`
- `RepairSession`
- `Hypothesis`

Keep them clean and minimal.

---

## 8. Golden Path Build Order

Build one vertical slice first. Do not wander.

Recommended order:

1. Project setup + basic navigation
2. Appliance model + create/select Dryer
3. RepairSession creation
4. Knowledge Package loader (even if just the seed)
5. DecisionContext
6. Simple Evidence collection
7. Question / EvidenceRequest loop (one question at a time)
8. Safety Validator stub
9. Basic session save / resume
10. First real Dryer path (no heat + spinning drum)

Only after the golden path works should broader features be added.

---

## 9. Day 1 Definition of Done

By the end of the first serious coding day we should be able to:

- Open the app
- Create or select a Dryer
- Start a Repair Session
- See the first observation question appear

That is enough for Day 1.

---

## 10. Sprint 1 Definition of Done

The Two-Week Acceptance Checklist is the finish line.  
Do not expand scope. Do not polish. Do not build Version 2 features.

---

## 11. Things Cursor Must Never Do

- Invent new modules or engines
- Replace deterministic reasoning with LLM reasoning
- Move safety decisions into free-form prompts
- Increase API / token usage without explicit approval
- Ignore Knowledge Packages and invent knowledge at runtime
- Build AR, voice, public platform, monetization, or multi-appliance excellence in this sprint
- Rewrite architecture because “there is a better way”
- Skip the Safety Validator
- Show numeric confidence percentages to users

---

## 12. When to Stop and Ask the Human

If you discover what appears to be a better architecture or a significant design conflict:

1. Stop
2. Explain the tradeoff clearly
3. Do **not** rewrite the Product Bible or change locked rules
4. Wait for human approval

Implementation never overrides the Product Bible or locked engineering decisions.

---

## Hierarchy of Authority

1. Founder decisions  
2. Product Bible (especially Safety Invariants, Deterministic Core, Engineering Simplifications)  
3. This Implementation Charter  
4. Current sprint goals  
5. Implementation convenience  

---

## Final Instruction

Build the smallest thing that correctly implements the architecture.  
Prefer clarity over cleverness.  
Prefer determinism over flexibility.  
Prefer safety over completeness.

When in doubt, re-read the Deterministic Core Principle and the Safety Invariants.

Now begin.
