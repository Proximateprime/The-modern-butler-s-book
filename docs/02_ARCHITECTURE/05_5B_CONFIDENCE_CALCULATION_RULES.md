# MODULE 5.5B — CONFIDENCE CALCULATION RULES

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-19  
**Authority:** Architecture Specification  

**Depends On:**  
- Module 3.10 — Confidence & Explainability Policy  
- Module 5.5 — Confidence & Decision Engine  
- Module 3.11 — Knowledge Trust & Evidence Ranking  
- Module 6.1 — Evidence Provenance

---

## Purpose

This document provides more concrete rules for how confidence in hypotheses should be adjusted as evidence arrives.

It does not define exact formulas that must be used in code. It defines the **factors** that must influence confidence and the **direction** of their influence so that implementations remain consistent with the product philosophy.

---

## Core Principles

- Confidence must be driven by evidence, not by the system’s desire to appear helpful.
- Higher-trust evidence moves confidence more than lower-trust evidence.
- Direct observation generally outweighs inference.
- Contradictory high-trust evidence should significantly reduce confidence.
- Confidence should remain calibrated and rarely approach absolute certainty.

---

## Factors That Increase Confidence

| Factor | Typical Influence | Notes |
|--------|-------------------|-------|
| Direct supporting observation | Strong increase | User saw/heard/felt something that matches the hypothesis |
| Multiple independent supporting observations | Strong increase | Convergence of evidence |
| High-trust source (photo, measurement, manufacturer data) | Stronger increase | Trust weighting applies |
| Elimination of major competing hypotheses | Moderate to strong increase | Remaining hypothesis becomes more likely |
| Consistent with Household Memory patterns | Mild to moderate increase | Past root causes on same appliance |
| Verified outcome in similar past cases | Moderate increase | When available and relevant |

---

## Factors That Decrease Confidence

| Factor | Typical Influence | Notes |
|--------|-------------------|-------|
| Direct contradictory observation | Strong decrease | Especially from high-trust sources |
| New plausible competing hypothesis supported by evidence | Moderate decrease | Distribution of probability |
| Low-trust or ambiguous evidence | Weak or no increase | Should not strongly drive confidence |
| User uncertainty (“I’m not sure”) | Mild decrease or hold | Treat as low information |
| Evidence later contradicted within the same session | Strong decrease | Update both hypotheses |

---

## Special Cases

### Inferred vs Observed
Evidence that is directly observed should generally move confidence more than evidence that is inferred by the system.

### Repeated Failures
If Household Memory shows the same root cause has occurred before on this appliance, confidence in that hypothesis may rise faster when early symptoms match.

### Safety-Critical Hypotheses
Even high confidence in a safety-critical hypothesis does not authorize unsafe guidance. Safety rules still apply.

---

## Stopping Considerations

Confidence is only one input to the decision to stop investigating. The system should also consider:

- Remaining information gain of further questions
- Safety constraints
- User goals
- Diminishing returns

High confidence alone is not always sufficient to stop; low confidence alone is not always sufficient to continue.

---

## Version History

**Version 1.0** — 2026-07-19  
Initial locked rules for confidence adjustment factors.

---

*This document is binding. Confidence updates must remain consistent with these directional rules and trust principles.*