# TWO-WEEK MVP ACCEPTANCE CHECKLIST

**Status:** Locked for 2-Week Push  
**Date:** 2026-07-20  
**Goal:** A working core diagnostic loop — not polish, not full coverage, not public platform, not perfect UI.

---

## Definition of Success

At the end of 2 weeks, the following must work end-to-end on **Dryer**:

### Must Pass
- [ ] User can create / select a Dryer appliance
- [ ] User can start a Repair Session
- [ ] System enters diagnostic flow (state machine skeleton is real, not fake)
- [ ] System asks observation-based questions (not engineering jargon)
- [ ] User answers are stored as Evidence
- [ ] System maintains session state across steps
- [ ] Basic hypothesis ranking runs from seed knowledge
- [ ] Confidence is shown in some simple form
- [ ] Risk & Safety gates can block prohibited guidance
- [ ] Session can reach one of:
  - Safe guidance, or
  - Clear “call a professional” outcome
- [ ] Session can be saved
- [ ] Session can be resumed at a basic level
- [ ] One real dryer-style problem can be walked through without crashing

### Explicitly Not Required
- [ ] Beautiful UI
- [ ] Full knowledge coverage
- [ ] Public website
- [ ] Voice mode
- [ ] AR
- [ ] Perfect confidence math
- [ ] Learning from community
- [ ] Multi-appliance excellence
- [ ] Payments / subscriptions
- [ ] Offline perfection

---

## Daily Reality Check Question
At the end of each day ask:

> “Did we get closer to a complete diagnostic loop, or did we add something outside the loop?”

If outside the loop → cut it.

---

## Pass / Fail Rule
If the Must Pass list is complete, the 2-week goal is achieved — even if rough.

If the loop is incomplete, the goal is missed — even if other features look impressive.

---

*This checklist is the finish line for the first coding push.*