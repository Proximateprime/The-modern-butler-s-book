# SEED KNOWLEDGE PACKAGE — DRYER (VERSION 1)

**Status:** Seed Content for 2-Week Build  
**Date:** 2026-07-20  
**Appliance:** Dryer (electric focus first; gas internals remain safety-gated)

---

## Purpose
Provide enough structured knowledge for the core diagnostic loop to run on common dryer problems.

This is **not** complete coverage.  
It is a high-quality starting pack.

---

## Priority Problem Families

1. **No heat / poor heat**
2. **Runs but clothes stay damp / long dry times**
3. **Will not start**
4. **Tumbles poorly / noisy**
5. **Stops mid-cycle**

---

## Basic Condition Checks (Always Consider Early)
- Power available / machine responds at all
- Door fully closed
- Cycle selected and started
- Lint filter status
- Exhaust vent not obviously crushed/blocked
- Obvious user settings (air fluff / low heat selected)

---

## Example Failure Modes (Starter Set)

### Airflow Restriction / Restricted Exhaust
- **Symptoms:** long dry times, overheating smells, cycling on thermal protection, clothes hot but damp
- **Safe observations:** lint filter condition, exterior vent airflow, crushed vent hose visibility, excessive heat at machine
- **Common confusion:** heating element failure
- **Escalation:** if disassembly beyond safe exterior checks is required

### Dirty Lint Pathway / Filter System Issues
- **Symptoms:** weak airflow, long dry times
- **Safe observations:** filter cleanliness, visible lint accumulation in accessible areas
- **Notes:** maintenance-heavy; strong prevention candidate

### Heating System Fault (High-Level)
- **Symptoms:** tumbles but no heat
- **Safe observations:** confirm no-heat vs low-heat, rule out airflow first
- **Safety:** internal heating circuit diagnosis may escalate quickly

### Door Switch / Start Interlock Issues
- **Symptoms:** will not start, no response to start
- **Safe observations:** door closed firmly, machine reactions to door open/close
- **Safety:** electrical internals are not DIY guidance

### Mechanical Drive Issues (Belt / Rollers / Idler — High-Level)
- **Symptoms:** motor hums but drum doesn’t tumble, loud squealing/thumping
- **Safe observations:** listen/feel for motor effort, drum movement behavior
- **Safety:** internal access may be optional maintenance later; not required for first seed depth

---

## Question Themes the Butler Should Prefer Early
- What exactly happens when you press start?
- Does the drum turn?
- Is there any heat at all?
- How long has drying been taking vs normal?
- Is the lint filter clean?
- Can you check the outside vent for airflow while running?
- Any burning smell, repeated stopping, or recent changes?

---

## Safety Boundaries (Non-Negotiable)
- No live internal electrical work guidance
- No gas valve / gas combustion internal guidance
- No sealed-system style guidance
- Prefer exterior/safe observations first
- Escalate when remaining hypotheses require prohibited work

---

## Good First End-to-End Target Scenario
**“Dryer runs but clothes never fully dry / takes forever”**

Expected strong path:
1. Basic conditions
2. Heat present or not
3. Lint filter
4. Vent/airflow checks
5. Distinguish airflow restriction vs heating problem
6. Safe guidance or escalate

---

## Authoring Notes
- Keep relationships simple and explicit
- Prefer fewer high-quality links over many weak ones
- Mark anything uncertain as weak confidence
- Expand only after the loop works

---

*This seed package is enough to start coding the reasoning loop. Expand only after the loop is real.*