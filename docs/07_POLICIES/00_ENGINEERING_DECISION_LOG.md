# ENGINEERING DECISION LOG

**Status:** Living Log  
**Started:** 2026-07-20  

This is a lightweight record of important decisions so future-you (and Cursor) can see why choices were made.

---

## Decision 1 — Local-First Knowledge Packages
**Date:** 2026-07-20  
**Decision:** Appliance knowledge is distributed as versioned local packages, not fetched from cloud AI during every repair.  
**Why:** Offline capability, privacy, lower API cost, faster runtime, scalable knowledge assets.  
**Rejected alternative:** Asking an LLM for appliance knowledge on each session.

## Decision 2 — AI as Translator, Not Encyclopedia
**Date:** 2026-07-20  
**Decision:** Deterministic systems own diagnosis; LLM owns communication/explanation.  
**Why:** Cost, testability, safety, determinism.  
**Rejected alternative:** End-to-end LLM diagnosis.

## Decision 3 — First Appliance Is Dryer
**Date:** 2026-07-20  
**Decision:** Dryer is the first implementation target.  
**Why:** Common problems, strong observational path, good testbed for the loop.  
**Rejected alternative:** Starting with too many appliances at once.

## Decision 4 — 2-Week Goal Is Core Loop Only
**Date:** 2026-07-20  
**Decision:** No polish, no public platform, no perfect UI, no full coverage in first push.  
**Why:** Need a real working diagnostic loop before expanding.  
**Rejected alternative:** Building many features in parallel.

## Decision 5 — Security Is Tier-1
**Date:** 2026-07-20  
**Decision:** Security is foundational, not deferred polish.  
**Why:** Household data, history, photos, and future payments create real trust risk.  
**Rejected alternative:** “Add security later.”

---

## Template for Future Entries

```
Decision #
Date:
Decision:
Why:
Alternatives rejected:
Impacted modules/systems:
```

---

*Add entries when a choice would be expensive to reverse or easy to forget.*