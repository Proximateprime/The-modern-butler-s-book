# DRYER KNOWLEDGE PACKAGE V1

**Status:** Production-Oriented Seed Package  
**Version:** 1.0  
**Date:** 2026-07-21  
**Scope:** Common electric dryer failures first  
**Authority:** Implementation Knowledge Asset  

**Depends On:**  
- Module 8.0 Local-First Knowledge Package Architecture  
- Knowledge Authoring Style Guide  
- Butler Language Guide  
- Never Break These  
- Risk & Safety rules  

---

## Package Intent

This is not every dryer failure on earth.

This is a high-confidence, high-frequency package designed to make the Butler feel genuinely useful on common problems:

- no heat
- poor drying
- won’t start
- won’t tumble
- noise
- overheating / airflow problems

Gas dryer internal work remains outside guided repair.
Live electrical work remains safety-gated.

---

## Engineering Philosophy for This Package

Preferred order:

```
Observation
→ Safe verification
→ Diagnosis confirmation
→ Repair
→ Prevention
→ Household Memory
```

Never:

```
Guess
→ Buy parts
→ Hope
```

Verify before recommending replacement parts whenever practical.

---

## Always-Early Safe Checks

Ask or confirm these early when relevant:

1. Does the dryer respond at all when started?
2. Does the drum turn?
3. Is there any heat at all?
4. Is the lint filter clean?
5. Is the exterior vent airflow weak or strong while running?
6. Are clothes taking much longer than normal?
7. Any burning smell, repeated stopping, or recent vent changes?
8. Is a low-heat / air-fluff style cycle selected by mistake?

These checks are low effort and high value.

---

## Hard Safety Rules

Never instruct:
- live electrical testing for beginners
- bypassing thermal fuses
- bypassing door switches
- defeating safety interlocks
- gas valve / gas combustion repairs
- sealed or advanced internal electrical diagnosis as casual DIY

Always:
- inspect venting whenever overheating or long dry times are suspected
- escalate when remaining paths require high-voltage or gas work
- preserve uncertainty instead of bluffing

---

## Problem Families

### A. No Heat / Poor Heat
### B. Long Dry Times / Clothes Stay Damp
### C. Won’t Start
### D. Motor Runs but Drum Doesn’t Turn
### E. Noise while Running
### F. Overheating Signs / Hot Machine / Weak Exhaust

---

## Failure Modes

### 1. Restricted Vent / Exhaust Airflow Problem
**Commonality:** Very high  

**Plain description:**  
Air cannot leave the dryer well, so drying becomes slow and the machine can overheat.

**Suggesting symptoms:**
- clothes take multiple cycles
- dryer becomes very hot
- exterior vent airflow is weak
- lint filter fills unusually fast
- may eventually contribute to thermal protection trips

**Against symptoms:**
- strong exterior airflow and still no heat at all

**Safe observations:**
- lint filter condition
- exterior vent airflow while running
- crushed/kinked visible vent hose
- long dry times vs normal

**Unsafe / escalate:**
- invasive electrical testing
- ignoring overheating signs

**Verification:**
- airflow improves after cleaning
- dry times improve

**Repair direction:**
- clean lint pathway and vent system

**Prevention:**
- clean lint filter every load
- periodic full vent cleaning

**Confidence notes:**
- high after weak exterior airflow + long dry times are confirmed


### 2. Clogged Lint Filter Housing / Lint Pathway Restriction
**Commonality:** High  

**Plain description:**  
Lint is blocking the path after the filter, reducing airflow even if the filter itself looks “sort of okay.”

**Suggesting symptoms:**
- poor drying
- high temperatures
- filter area shows packed lint beyond the screen

**Safe observations:**
- inspect filter slot/housing for packed lint
- exterior airflow

**Verification:**
- drying improves after thorough cleaning

**Repair direction:**
- clean housing and accessible lint pathway

**Prevention:**
- do not wait until airflow is obviously bad

**Confidence notes:**
- medium-high with visible packed lint and weak drying


### 3. Thermal Fuse Open
**Commonality:** High  

**Plain description:**  
A protective fuse has opened after the dryer got too hot. The drum may still turn, but heat is gone.

**Suggesting symptoms:**
- tumbles normally
- no heat
- history of poor venting / long dry times / overheating

**Safe observations:**
- no heat with tumbling present
- check for vent restriction first
- do not jump straight to part replacement without airflow review

**Verification philosophy:**
- part confirmation may require testing beyond beginner-safe guidance
- always inspect venting because a blown thermal fuse is often a symptom, not the root cause

**Repair direction:**
- replace fuse only after addressing overheating cause
- never bypass fuse

**Prevention:**
- restore proper airflow
- maintain vent system

**Confidence notes:**
- medium until verified
- high only with proper verification and airflow cause addressed

**Safety:**
- do not instruct fuse bypass under any circumstance


### 4. Heating Element Open / Failed
**Commonality:** High on electric dryers  

**Plain description:**  
The heating element no longer produces heat.

**Suggesting symptoms:**
- drum turns
- no heat
- airflow may be normal
- thermal fuse may still be good

**Safe observations:**
- confirm true no-heat condition
- rule out obvious cycle setting mistakes
- rule out major airflow issues first when dry times/overheating history exist

**Verification:**
- component testing may exceed beginner-safe live/electrical guidance
- escalate rather than push unsafe meter work

**Repair direction:**
- replace heating element after proper confirmation

**Confidence notes:**
- medium on symptoms alone
- higher only after safer causes ruled out and proper verification


### 5. Broken Drive Belt
**Commonality:** High  

**Plain description:**  
Motor may run, but the belt no longer turns the drum.

**Suggesting symptoms:**
- motor sounds like it is running
- drum does not turn
- clothes do not tumble

**Safe observations:**
- listen for motor running without drum movement
- drum moves too freely / no resistance pattern depending on design
- visible belt inspection only if user already has safe access and guidance remains within scope

**Verification:**
- inspect belt condition/presence

**Repair direction:**
- replace belt

**Confidence notes:**
- high when motor runs and drum never turns


### 6. Door Switch Failure
**Commonality:** Common  

**Plain description:**  
The dryer thinks the door is open, so it will not start normally.

**Suggesting symptoms:**
- nothing happens when Start is pressed
- interior light behavior seems wrong on some machines
- door must feel fully closed

**Safe observations:**
- door firmly latched
- machine response when door opened/closed
- start attempt response

**Verification:**
- switch actuation behavior
- deeper electrical testing may escalate

**Repair direction:**
- replace door switch after confirmation

**Safety:**
- never bypass door switch


### 7. Worn Drum Rollers
**Commonality:** Common  

**Plain description:**  
Rollers that support the drum are worn and noisy.

**Suggesting symptoms:**
- loud squealing or thumping
- drum still rotates
- noise changes with drum speed/movement

**Safe observations:**
- noise while tumbling
- whether drying still occurs
- access-based inspection only when safe and appropriate

**Verification:**
- spin/inspect rollers if safely accessible

**Repair direction:**
- replace worn rollers

**Confidence notes:**
- medium-high with classic squealing and continued rotation


### 8. Idler Pulley Wear
**Commonality:** Common  

**Plain description:**  
The pulley that keeps tension on the belt is worn or dry and squeaks.

**Suggesting symptoms:**
- loud squeak
- belt still present
- drum may still turn

**Safe observations:**
- squeak linked to running
- belt intact
- distinguish from roller noise when possible

**Verification:**
- inspect pulley when safely accessible

**Repair direction:**
- replace idler pulley

**Confidence notes:**
- medium until inspected


### 9. Motor Failure / Motor Won’t Take Load
**Commonality:** Moderate  

**Plain description:**  
Motor hums or struggles and cannot properly start or turn the system.

**Suggesting symptoms:**
- hums
- won’t start turning
- may trip or smell hot in advanced failure

**Safe observations:**
- hum without successful start
- drum status
- whether machine was already noisy or hard to turn

**Verification / repair:**
- deeper motor diagnosis and replacement often escalate beyond casual beginner guidance

**Confidence notes:**
- medium on symptoms
- escalate rather than force unsafe electrical diagnosis


### 10. Loose / Faulty Electric Supply Connection
**Commonality:** Moderate  
**Risk:** High  

**Plain description:**  
Electric dryer is not getting the power configuration needed for heat, even if some functions still run.

**Suggesting symptoms:**
- drum turns
- no heat
- other causes less likely after basic checks

**Safety:**
- high voltage
- beginners should not perform live measurements
- escalate to qualified person

**Safe Butler behavior:**
- identify as possible advanced electrical supply issue
- do not walk unqualified users through live testing
- recommend professional service

**Confidence notes:**
- keep controlled
- never imply casual DIY high-voltage work is safe

---

## Suggested Question Themes by Family

### Long dry times / very hot dryer
1. Is the lint filter clean?
2. At the outside vent, is airflow weak while running?
3. Are clothes hot but still damp?
4. Has this gotten worse over time?

### No heat but tumbles
1. Does the drum turn normally?
2. Is there any warmth at all after several minutes?
3. Any history of long dry times or weak vent airflow?
4. Any recent overheating signs?

### Won’t start
1. Does anything happen at all when you press start?
2. Does the door close firmly?
3. Any lights/response at all?
4. Did this start suddenly?

### Motor runs, drum doesn’t
1. Do you hear the motor?
2. Does the drum move at all?
3. Any recent squealing before failure?

### Noise
1. Is it a squeal, thump, grind, or squeak?
2. Does the drum still turn?
3. Does drying still work?

---

## Confidence Display Rules for This Package

- Do not show confidence during early questioning
- Show confidence at diagnosis / recommendation points only
- High = verified or extremely strong convergent evidence
- Medium = strong symptom match, verification pending
- Low = multiple still-plausible causes

Never imply fake precision like “99%.”

---

## Verification Before Parts

Whenever practical:

1. Confirm the symptom clearly  
2. Do safe exterior checks  
3. Distinguish airflow problems from heat-production problems  
4. Only then move toward part replacement direction  
5. If verification requires unsafe electrical work, escalate  

Special rule:
If a thermal fuse appears involved, treat vent/airflow as part of the root-cause investigation, not optional trivia.

---

## Prevention Defaults

After airflow-related successes:
- clean lint filter every load
- do not run with restricted exterior vent
- schedule periodic vent cleaning

After mechanical noise successes:
- don’t ignore early squealing
- catch wear before belt/motor collateral damage when possible

---

## Minimum Useful Package Checklist

This V1 package is useful if the Butler can handle:

- [x] long dry times / weak airflow path
- [x] no heat with tumble path at high level
- [x] won’t start / door path at high level
- [x] motor runs but no tumble path
- [x] common noise paths
- [x] thermal protection linked to airflow
- [x] clear escalation for high-voltage / gas / unsafe testing

---

## Implementation Notes

For the 2-week MVP:
- encode these as structured failure modes + symptoms + safe checks + escalate rules
- keep user-facing wording human
- store technical names in memory/report layer
- do not require full package-manager sophistication to use this seed

Later:
- split electric brand-family packages
- add model patches
- deepen verification guidance only where safety allows

---

## Version History

**Version 1.0** — 2026-07-21  
Initial high-frequency dryer package from real common failure patterns and Mark-informed cases.

---

*This package should feel useful on ordinary dryer problems before it tries to become encyclopedic.*