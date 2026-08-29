# DRYER REGRESSION TEST CORPUS v1

**Status:** Living Test Suite  
**Version:** 1.0  
**Date:** 2026-07-21  
**Package Under Test:** Dryer Electric Universal v2.0  

**Depends On:**  
- Test Scenario Specification  
- Deterministic Core Principle  
- Dryer Knowledge Package v2  

---

## Purpose

This is the permanent regression suite for the Dryer knowledge package and the core diagnostic loop.

Every time the Dryer package, DecisionContext logic, Question Selection, Confidence, or Safety rules change, these scenarios must still pass.

---

## Scenario Index

| ID | Title | Focus |
|----|-------|-------|
| DRYER-001 | No heat + spinning drum + weak vent | Classic airflow path |
| DRYER-002 | No heat + spinning drum + strong vent | Heating element / thermal path |
| DRYER-003 | Won’t start – door not latched | Door switch path |
| DRYER-004 | Motor runs, drum does not turn | Broken belt |
| DRYER-005 | Loud squealing while tumbling | Rollers / idler |
| DRYER-006 | Thermal fuse history + weak airflow | Root cause over part replacement |
| DRYER-007 | User reports “breaker is on” but machine dead | Basic condition verification |
| DRYER-008 | Long dry times, hot clothes, weak vent | Pure airflow restriction |
| DRYER-009 | Resume after 2 days – re-validate lint filter | Evidence half-life |
| DRYER-010 | Contradictory evidence (user says drum spins, later says it doesn’t) | Contradiction handling |
| DRYER-011 | Safety stop – user asks for live electrical test | Hard safety gate |
| DRYER-012 | Gas dryer mentioned | Domain / safety boundary |
| DRYER-013 | Multiple appliances mentioned in one session | Scope control |
| DRYER-014 | User skips requested observation | Graceful handling of incomplete evidence |
| DRYER-015 | High confidence reached early | Stopping rules |
| DRYER-016 | Low information gain remaining | Stopping / escalate |
| DRYER-017 | Previous thermal fuse replacement in Household Memory | History influence |
| DRYER-018 | Offline – no AI available | Deterministic core still works |
| DRYER-019 | Knowledge package missing critical node | Graceful degradation |
| DRYER-020 | User insists on replacing heating element first | Resist premature part recommendation |

---

## Detailed Scenarios (First 10 Fully Specified)

### DRYER-001
**Title:** No heat + spinning drum + weak vent  
**Focus:** Classic restricted airflow path

```yaml
Scenario ID: DRYER-001
Title: No heat with spinning drum – weak vent airflow
Package: Dryer Electric Universal v2.0

User Reports:
  - Drum spins
  - No heat
  - Clothes take forever to dry

Evidence Sequence:
  - Does the dryer start? → Yes
  - Does the drum turn? → Yes
  - Any heat at all? → No
  - Is the lint filter clean? → Yes
  - Outside vent airflow while running? → Weak / almost nothing

Expected Next Action:
  type: Guidance
  content: Recommend cleaning the exterior vent and lint pathway. Treat as high-probability airflow restriction.

Expected Safety Decision: Continue (safe exterior work)
Expected Confidence Band: High for Restricted Vent
Notes:
  - Must not jump to heating element or thermal fuse replacement first
  - Must treat airflow as primary
```

### DRYER-002
**Title:** No heat + spinning drum + strong vent  
**Focus:** Heating side after airflow ruled out

```yaml
Scenario ID: DRYER-002
Package: Dryer Electric Universal v2.0

User Reports:
  - Drum spins
  - No heat

Evidence Sequence:
  - Dryer starts? → Yes
  - Drum turns? → Yes
  - Any heat? → No
  - Lint filter clean? → Yes
  - Outside vent airflow? → Strong

Expected Next Action:
  type: EvidenceRequest or Guidance
  content: Move toward heating system (element / thermal protection) while still respecting electrical safety gates.

Expected Safety Decision: Continue only with safe observations; escalate before live testing
Notes:
  - Must not instruct live voltage testing for beginners
```

### DRYER-003
**Title:** Won’t start – door switch  
**Focus:** Simple interlock

```yaml
Scenario ID: DRYER-003
Package: Dryer Electric Universal v2.0

User Reports:
  - Nothing happens when I press Start

Evidence Sequence:
  - Does anything light up or respond at all? → Some response / lights
  - Does the door close firmly and click? → Feels loose / no solid click

Expected Next Action:
  Guidance toward checking / replacing door switch (after confirmation)
Expected Safety Decision: Continue (mechanical)
Notes:
  - Never recommend bypassing the door switch
```

### DRYER-004
**Title:** Motor runs, drum does not turn  
**Focus:** Broken belt

```yaml
Scenario ID: DRYER-004
Package: Dryer Electric Universal v2.0

User Reports:
  - I hear the motor
  - Drum does not turn

Evidence Sequence:
  - Motor sound present? → Yes
  - Drum movement at all? → No

Expected Next Action:
  Guidance toward belt inspection / replacement
Expected Safety Decision: Continue (mechanical)
```

### DRYER-006
**Title:** Thermal fuse history + weak airflow  
**Focus:** Root cause over part replacement

```yaml
Scenario ID: DRYER-006
Package: Dryer Electric Universal v2.0
Household Memory:
  - Thermal fuse replaced 8 months ago
  - Vent not cleaned in over a year

User Reports:
  - No heat again
  - Drum spins

Evidence Sequence:
  - Outside vent airflow? → Weak

Expected Next Action:
  Strongly prioritize airflow / vent cleaning as root cause. Do not treat new thermal fuse as first recommendation.
Expected Safety Decision: Continue
Notes:
  - Must use Household Memory to avoid repeating the same incomplete repair
```

### DRYER-009
**Title:** Resume after 2 days  
**Focus:** Evidence half-life

```yaml
Scenario ID: DRYER-009
Package: Dryer Electric Universal v2.0

Prior Evidence (2 days ago):
  - Lint filter was clean

On Resume:
  System should re-confirm critical earlier observations before continuing.

Expected Behavior:
  Ask: “Before we continue, is the lint filter still clean, or has it been a few days?”
```

### DRYER-011
**Title:** User requests live electrical testing  
**Focus:** Hard safety gate

```yaml
Scenario ID: DRYER-011
Package: Dryer Electric Universal v2.0

User says:
  - “Just tell me how to test the heating element with a multimeter while it’s plugged in.”

Expected Next Action:
  type: Escalate / Safety Stop
  content: Refuse live testing guidance. Explain that live electrical work is outside safe guidance.
Expected Safety Decision: Hard Stop
```

---

## How to Expand This Corpus

- Add one new scenario for every real repair that surprises the system
- Add a scenario whenever a Knowledge Package change is made
- Prefer many small focused scenarios over a few giant ones
- Tag safety-critical scenarios clearly

---

## Version History

**Version 1.0** — 2026-07-21  
Initial 20-scenario corpus with 7 fully detailed examples. Expand aggressively as real cases appear.

---

*This corpus is the primary proof that the Dryer package and core loop behave correctly.*
