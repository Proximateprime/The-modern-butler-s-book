# BUTLER VERIFICATION FRAMEWORK

**Status:** Locked Implementation Specification  
**Version:** 1.0  
**Date:** 2026-07-21  
**Authority:** Lead Verification Engineer / QA  

**Depends On:**  
- Deterministic Core Principle  
- Test Scenario Specification  
- Engineering Simplifications (DecisionContext, EvidenceRequest, should_continue_investigation)  
- Knowledge Authoring Style Guide  
- Dryer Regression Test Corpus v1  
- Safety Invariants  
- Non-Negotiables  

---

## Purpose

This document defines the permanent quality assurance process for every Knowledge Package and for the core diagnostic engines.

No Knowledge Package may be marked **Production Ready** until it has passed the gates defined here.

The goal is simple:

> Every future change to knowledge or reasoning must be proven correct before it can affect real users.

---

## 1. Required Regression Tests

Every Knowledge Package must maintain a regression suite written in the official Test Scenario Specification format.

**Minimum requirements for a Production Ready package:**

- At least 15–20 focused scenarios covering the highest-frequency failure modes
- At least 3 safety-critical scenarios (hard stops, escalations, prohibited guidance)
- At least 2 contradiction / evidence conflict scenarios
- At least 1 resume / evidence half-life scenario
- At least 1 Household Memory influence scenario (if the package is expected to use history)
- At least 1 offline / no-AI scenario proving the deterministic core still works

The Dryer Regression Test Corpus v1 is the reference implementation of this requirement.

---

## 2. Minimum Package Quality Gates

A package may not be released until it satisfies all of the following:

### Structural
- Follows the official Knowledge Package Template
- Contains Always-Early Safe Checks
- Contains explicit Hard Safety Rules
- Every major Failure Mode has both Suggesting and Against evidence
- Prevention recommendations are present and specific

### Safety
- No path recommends live electrical testing for beginners
- No path recommends gas work, sealed-system work, or safety-device bypass
- Thermal / protective devices are treated as symptoms that usually have underlying causes
- All guidance that reaches the user can be validated by the deterministic Safety Validator

### Diagnostic Quality
- High-frequency problems produce sensible leading hypotheses
- The system prefers low-effort exterior observations before higher-effort or higher-risk checks
- Premature part replacement is resisted when a root-cause path still exists

### Determinism
- All scenarios in the package’s regression suite pass with zero LLM calls
- Given the same DecisionContext + Evidence + Package, results are identical across runs

---

## 3. Knowledge Validation Checklist

Before any package is marked Production Ready, a human (or designated reviewer) must complete:

- [ ] Template compliance
- [ ] Safety rules are complete and non-negotiable
- [ ] Evidence For / Against balance exists for major modes
- [ ] No unsafe instructions appear as normal steps
- [ ] Common misdiagnoses or “Against” evidence are present where useful
- [ ] Prevention advice is specific and actionable
- [ ] Question themes favor high information gain + low user effort
- [ ] Confidence notes distinguish verified vs symptom-only
- [ ] Always-early safe checks are present
- [ ] Root-cause thinking is visible (especially for protective devices)
- [ ] Language follows “Speak Human. Record Engineering.”
- [ ] Regression suite exists and passes
- [ ] Version history and package metadata are complete

---

## 4. Confidence Validation Process

Exact numeric confidence is internal and uncalibrated in early versions.

**Rules:**
- User-facing confidence may only be Low / Medium / High
- No percentage may be shown to users until a formal calibration process exists
- After a sufficient number of verified real-world outcomes, confidence bands must be reviewed against actual success rates
- Any change to confidence calculation logic requires re-running the full relevant regression suites

---

## 5. Safety Validation Checklist

Every package and every core logic change must be checked against:

- [ ] Hard Safety Gates are still enforced
- [ ] No new path allows prohibited electrical / gas / sealed-system guidance
- [ ] Safety Validator is the final gate for all user-visible guidance
- [ ] Escalation language is calm, clear, and non-shaming
- [ ] Expert Mode (if present) still cannot unlock hard gates
- [ ] Safety-critical regression scenarios still pass

---

## 6. Bug Reproduction Workflow

Every significant bug must be turned into permanent knowledge.

**Required process:**

1. Create a Bug ID (e.g. BUG-0043)
2. Write a reproduction scenario in the official Test Scenario format
3. Link the scenario to the regression suite of the affected package(s)
4. Fix the issue
5. Confirm the new scenario now fails on the old code and passes on the fixed code
6. Keep the scenario forever

This prevents the same class of mistake from returning.

---

## 7. Regression Suite Maintenance Policy

- Every Knowledge Package change that affects diagnostic behavior requires the suite to be re-run
- New real-world failure modes that surprise the system should be added as new scenarios
- Scenarios that become obsolete must be marked deprecated rather than silently deleted
- The suite is living documentation of expected behavior

---

## 8. Release Criteria — “Production Ready”

A Knowledge Package may be marked **Production Ready** only when all of the following are true:

1. It passes the Minimum Package Quality Gates
2. Its regression suite meets the required coverage
3. All scenarios in its suite pass under the Deterministic Core (no LLM required)
4. The Knowledge Validation Checklist has been completed and recorded
5. The Safety Validation Checklist has been completed
6. Version number and changelog are updated
7. A designated reviewer has approved the release

Until these criteria are met, the package remains in Draft or Staging status and must not be served to real users as production knowledge.

---

## Relationship to the Knowledge Factory

- The Knowledge Factory creates and updates packages
- The Verification Framework proves those packages are safe and correct
- No package may skip the Verification Framework

Together they form the long-term quality system of the Butler.

---

## Version History

**Version 1.0** — 2026-07-21  
Initial locked Butler Verification Framework.

---

*This framework is binding. Future Knowledge Packages and core diagnostic changes must satisfy these requirements before reaching production users.*
