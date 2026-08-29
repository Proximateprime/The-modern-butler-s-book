# Butler Knowledge Package — Release Checklist

**One page. Print it. Use it.** Mechanical gates (does not publish): [`docs/knowledge/PACKAGE_RELEASE_CHECKLIST.md`](../knowledge/PACKAGE_RELEASE_CHECKLIST.md).

**Package Name / Version:** _______________________________  
**Reviewer:** _______________________________  
**Date:** _______________

---

### Identity
- [ ] Package version assigned
- [ ] Version history updated
- [ ] Dependencies / required patches declared

### Knowledge Quality
- [ ] Highest-frequency failure modes covered
- [ ] Common misdiagnoses / “Against” evidence present
- [ ] Root-cause thinking applied (especially protective devices)
- [ ] Prevention recommendations specific and reviewed

### Safety
- [ ] All hard safety gates verified
- [ ] No unsafe beginner guidance present
- [ ] Escalation paths clear and calm
- [ ] Domain boundaries respected (no gas / sealed / live electrical DIY)

### Regression & Determinism
- [ ] Existing regression suite still passes
- [ ] New scenarios added for any new behavior
- [ ] Previous bug scenarios still fixed
- [ ] All tests pass with zero LLM calls (Deterministic Core)

### Confidence
- [ ] Confidence progression reviewed
- [ ] No unjustified High confidence on weak evidence
- [ ] Contradictory evidence handled correctly

### Offline & Resume
- [ ] Package loads and runs offline
- [ ] No hard cloud dependency for core diagnosis
- [ ] Resume / evidence half-life behavior tested

### Final Sign-off
- [ ] Human review completed
- [ ] Approved for Production Ready status

**Signature / Approval:** _______________________________

---

*Nothing ships until every box is checked.*
