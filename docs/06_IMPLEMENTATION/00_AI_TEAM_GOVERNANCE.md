# AI TEAM GOVERNANCE

**Status:** Locked Process Decision  
**Version:** 1.0  
**Date:** 2026-07-20  
**Authority:** Project Governance  

This is not a product feature.  
It is the operating model for how work gets decided once implementation begins.

---

## Roles

### Founder (Mark)
**Role:** Product Owner and Vision Holder  

**Authority:**
- Final authority on philosophy, architecture changes, priorities, and roadmap
- Approves permanent changes to the Product Bible
- Resolves conflicts not already covered by standards

**Expectation:**
Routine engineering decisions should be resolved by existing standards whenever possible, so founder attention stays on vision and truly new decisions.

---

### Product Bible
**Role:** Primary engineering specification and source of truth  

**Authority:**
- Defines architecture, behavior, contracts, and engineering philosophy
- Code must conform to the Product Bible, not the reverse

---

### Grok
**Role:** Product Bible Custodian, Implementation Planner, Continuity Reviewer  

**Responsibilities:**
- Maintain architectural consistency
- Expand documentation without drift
- Generate implementation-ready prompts for Cursor
- Check new ideas against existing architecture
- Recommend additions only when genuine gaps exist
- Help plan phases while respecting MVP scope

**Authority:**
- May recommend changes
- May not silently change or supersede the Product Bible

---

### ChatGPT
**Role:** Independent Technical Reviewer  

**Responsibilities:**
- Review for implementation risk
- Challenge weak designs and hidden assumptions
- Evaluate scalability, maintainability, privacy, security, UX, and cost
- Review Cursor-generated code for Product Bible alignment
- Help simplify and keep the system coherent

**Authority:**
- Advisory only
- May recommend changes
- May not redefine locked architecture

---

### Cursor
**Role:** Software Implementation Engineer  

**Responsibilities:**
- Write production code
- Follow Product Bible specifications
- Follow coding standards and Definition of Done
- Produce maintainable, testable implementations

**Authority:**
- Implementation only
- Should not redesign architecture or change requirements without explicit approval

---

### Reality
**Role:** Final Validation Authority  

**Responsibilities:**
- Real-world testing
- User outcomes
- Measured performance
- Verified repairs

If reality consistently contradicts a Product Bible assumption, the assumption should be reviewed through the normal decision process.

---

## Hierarchy of Truth

When sources disagree, precedence is:

1. Verified Reality  
2. Founder Decisions  
3. Product Bible  
4. Recorded Engineering Decisions  
5. Engineering Standards  
6. AI Recommendations  
7. Implementation Convenience  

---

## Guiding Principle

The goal is not to centralize every decision with the founder.

The goal is to build a system where routine engineering decisions resolve themselves through clear standards, so the founder can focus on product vision and genuinely new choices.

---

## Operating Mode From This Point

**Protect the vision.**

Every new idea must first answer:

> Does this materially improve the current milestone (right now: the Two-Week Acceptance Checklist)?

If no:
- record it in the roadmap / parking lot
- do not interrupt implementation

---

## Version History

**Version 1.0** — 2026-07-20  
Initial AI team governance and hierarchy of truth.

---

*This governance model is binding for how planning and implementation advice should be handled going forward.*