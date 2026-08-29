# DEFINITION OF DONE

**Status:** Locked Engineering Standard  
**Version:** 1.0  
**Date:** 2026-07-20  
**Authority:** Engineering Specification  

**Depends On:**  
- Two-Week MVP Acceptance Checklist  
- Cursor Coding Standards  
- Engineering Style Guide  
- Security as Tier-1 Principle  
- Butler Communication Personality

---

## Purpose

A feature is not done when it compiles.  
A feature is not done when Cursor finishes generating code.

A feature is done only when it meets the standards below.

This exists to prevent a pile of “almost finished” work.

---

## Butler Definition of Done

A feature is considered complete only if:

1. **Matches the Product Bible**  
   Behavior aligns with locked architecture and principles.

2. **Stays inside current milestone scope**  
   For the first push, this means the Two-Week Acceptance Checklist unless explicitly expanded by the Founder.

3. **Has appropriate tests**  
   At minimum, the critical path relevant to the feature can be verified.

4. **Has appropriate logging**  
   Enough to debug real diagnostic behavior.

5. **Has appropriate error handling**  
   Failures preserve progress where possible and use clear user-facing language.

6. **Respects privacy rules**  
   No unnecessary data collection or careless sync.

7. **Respects security standards**  
   No secret leakage, unsafe defaults, or bypassed controls.

8. **Respects AI cost rules**  
   Does not use cloud AI where local/deterministic logic should own the work.

9. **Supports required offline behavior**  
   Where the architecture says local-first, the feature does not hard-depend on cloud without cause.

10. **Uses Butler communication guidelines**  
    No shame, bluffing, panic, or generic “unknown error” junk for user-facing paths.

11. **Can recover from interruption where relevant**  
    Session-related features must not throw away progress casually.

12. **Is understandable by another engineer**  
    Naming, structure, and intent are clear enough for review and continuation.

---

## Special Rule for the 2-Week Push

During the first implementation push, a feature may be accepted with reduced polish **only if**:

- it materially advances the acceptance checklist, and
- it does not create unsafe behavior, hidden architecture drift, or obvious debt that blocks the core loop

Polish is optional.  
Integrity is not.

---

## Version History

**Version 1.0** — 2026-07-20  
Initial Definition of Done for Butler implementation.

---

*If a feature fails this list, it is not done.*