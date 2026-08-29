# MODULE 3.11 — KNOWLEDGE TRUST & EVIDENCE RANKING SPECIFICATION

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-18  
**Authority:** Architecture Specification  
**Depends On:**  
- Safety Invariants  
- Non-Negotiables  
- App Promise  
- Module 3.6 — Reasoning Philosophy & Hybrid Intelligence  
- Module 3.8 — Uncertainty Management & Adaptive Intelligence

---

## Purpose

This document defines how the Butler evaluates and weights different sources of information. It establishes requirements for assigning trust to knowledge sources and how that trust influences reasoning and conclusions.

Different sources of information have different levels of reliability. The system must account for this when combining evidence and generating hypotheses.

This specification is binding on the Reasoning Engine and Evidence Engine.

---

## Trust Metadata Model

Every piece of knowledge used by the Butler should carry structured trust metadata rather than a single opaque trust score. The recommended metadata includes:

- **Source Type**: Manufacturer documentation, Knowledge Graph (verified), Household Memory, User observation, Community report, etc.
- **Confidence Score**: A value between 0 and 1 representing the estimated reliability of the information.
- **Verification Status**: Verified, Unverified, Experimental, or Deprecated.
- **Date / Recency**: When the information was created or last validated.
- **Evidence Count**: How many independent sources support this information.
- **Review Status**: Whether the information has been reviewed by experts or the community.

The Reasoning Engine must combine these factors when determining how much weight to give a particular piece of information.

---

## Trust Levels by Source Type

The following are example trust characteristics (these may be refined during implementation):

| Source Type                    | Typical Confidence | Verification Status | Notes |
|--------------------------------|--------------------|---------------------|-------|
| Manufacturer Service Manual    | 0.95 – 0.99        | Verified            | Highest trust when applicable |
| Knowledge Graph (curated)      | 0.85 – 0.95        | Verified            | Structured and reviewed |
| Direct measurement / sensor    | 0.90 – 0.98        | Verified            | High when properly obtained |
| Clear photo evidence           | 0.80 – 0.92        | Verified            | Depends on clarity and relevance |
| Household Memory (recent)      | 0.70 – 0.85        | Unverified          | User-reported but contextual |
| Household Memory (old)         | 0.40 – 0.65        | Unverified          | Subject to memory degradation |
| Community reports (verified)   | 0.70 – 0.85        | Verified            | After quality review |
| Community reports (unverified) | 0.40 – 0.60        | Unverified          | Useful for hypothesis generation only |
| General internet sources       | 0.20 – 0.50        | Unverified          | Low influence on conclusions |

The Reasoning Engine should use these characteristics when weighting evidence and hypotheses.

---

## Evidence Ranking

When multiple pieces of evidence support or contradict a hypothesis, the system should rank them according to:

1. **Trustworthiness of the source**
2. **Recency and relevance**
3. **Consistency with other high-trust evidence**
4. **Quantity of supporting evidence**

Higher-trust evidence should have proportionally greater influence on confidence scores and hypothesis rankings. Low-trust evidence may still be useful for generating hypotheses but should carry less weight in final conclusions.

---

## Dynamic Trust Adjustment

Trust in certain sources may change over time:

- Community reports can increase in trust after multiple independent verifications.
- Older household memory may decrease in trust unless corroborated.
- New manufacturer information may supersede older documentation.

The system should support mechanisms to update trust metadata as new information becomes available.

---

## Version History

**Version 1.0** — 2026-07-18  
Initial locked specification defining the trust metadata model and evidence ranking approach.

---

## Implementation Notes

The Evidence Engine and Reasoning Engine must implement support for trust metadata when processing and combining information. All future additions to the Knowledge Graph or community intelligence should include appropriate trust metadata.

This document forms part of the permanent Product Bible.

---

*This document is binding. All weighting and combination of evidence from different sources must follow the trust and ranking principles defined herein.*