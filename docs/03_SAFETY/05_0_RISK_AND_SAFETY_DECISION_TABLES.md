# MODULE 5.0 — RISK & SAFETY DECISION TABLES

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-19  
**Authority:** Architecture Specification  

**Depends On:**  
- Safety Invariants  
- Module 5.1 — Risk & Safety Engine  
- Module 3.5 — Diagnostic Workflow & State Machine

---

## Purpose

This document defines the concrete decision rules that the Risk & Safety Engine must follow.  

While Module 5.1 defines the existence and authority of the Risk & Safety Engine, this document defines **when** it must act and **what** it must do.

These rules are intended to be unambiguous enough that any implementation (including AI-assisted code generation) can follow them without inventing new safety logic.

---

## Hard Stop Conditions (Must Never Proceed)

The system must immediately stop providing guidance and recommend professional service when any of the following are true:

- The required action involves live electrical work inside an appliance or electrical panel.
- The required action involves gas lines, gas valves, or gas combustion systems.
- The required action involves opening a sealed refrigerant system.
- The required action requires specialized certification or licensed work.
- Two or more high-risk failure modes remain plausible and both require dangerous testing.
- The user indicates they are uncomfortable or unable to perform a necessary safety-critical observation.
- The system detects conditions consistent with an active emergency (smoke, burning smell with heat, gas odor, etc.).

---

## Soft Stop / Escalation Conditions

The system should strongly recommend professional help (while still allowing limited safe observation) when:

- Confidence remains low after reasonable evidence collection and remaining hypotheses are safety-relevant.
- The user has repeatedly been unable to complete safe observations.
- The diagnostic path requires tools or access the user does not have.
- Household history shows repeated failures of the same safety-critical component.

---

## Expert Mode Limitations

Even in Expert Mode (adult users with higher skill signals):

- Hard Stop conditions still apply.
- The system may provide richer technical context and clearer packaging of information for a technician.
- The system must never provide step-by-step instructions that violate Safety Invariants.

---

## Confidence vs Safety

High confidence never overrides a Hard Stop condition.  
Safety decisions take absolute priority over diagnostic confidence.

---

## Emergency Detection

If the system receives evidence suggesting an active dangerous condition (fire risk, gas leak indicators, electrical burning, etc.), it must:

1. Immediately stop normal diagnostic flow.
2. Advise the user to prioritize safety (leave the area if appropriate, ventilate, call emergency services if needed).
3. Not continue appliance troubleshooting until the emergency context is resolved.

---

## Version History

**Version 1.0** — 2026-07-19  
Initial locked set of decision rules for the Risk & Safety Engine.

---

*This document is binding. All safety-related decisions must conform to these rules.*