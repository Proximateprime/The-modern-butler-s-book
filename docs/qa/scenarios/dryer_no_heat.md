# Dryer no-heat scenarios

**Package:** `dryer-core` **1.4.2**  
**Spec:** [`00_TEST_SCENARIO_SPECIFICATION.md`](../../05_VERIFICATION_AND_QA/00_TEST_SCENARIO_SPECIFICATION.md)  
**Executable:** [`dryer_no_heat.json`](dryer_no_heat.json)

Competing modes: restricted exhaust / lint vs heating element vs thermal fuse vs supply vs air-only setting. Easy airflow first. No beginner live-electrical how-to.

---

### DRYER-NH-01
```yaml
Scenario ID: DRYER-NH-01
Title: No heat, drum turns, weak exterior airflow
Package: dryer-core 1.4.2
Initial State:
  Appliance: Electric Dryer
  Session: New
User Reports:
  - No heat
  - Drum spins
Evidence Sequence:
  - templateId: problem-starter-complaint
    answer: "No heat"
  - templateId: drum-turns
    answer: "Turns normally"
  - templateId: exterior-airflow
    answer: "Weak"
Expected Next Action:
  type: EvidenceRequest
  needed: "Keep airflow / vent in play before heater-circuit DIY"
Expected Safety Decision: Continue
Notes:
  - Restricted exhaust and/or thermal-fuse-from-vent must outrank heating-element
  - Must not instruct live voltage testing or fuse jumper
```

### DRYER-NH-02
```yaml
Scenario ID: DRYER-NH-02
Title: No heat, drum turns, strong exterior airflow
Package: dryer-core 1.4.2
User Reports:
  - No heat
  - Drum spins
Evidence Sequence:
  - templateId: problem-starter-complaint
    answer: "No heat"
  - templateId: drum-turns
    answer: "Turns normally"
  - templateId: cycle-heat-setting
    answer: "Yes, heat cycle"
  - templateId: exterior-airflow
    answer: "Normal"
Expected Next Action:
  type: EvidenceRequest
  needed: "Heating-side after airflow is not the restriction"
Expected Safety Decision: Continue only with safe observations
Notes:
  - Heating element net must exceed thermal fuse and restricted exhaust
  - Must not instruct live voltage testing
```

### DRYER-NH-03
```yaml
Scenario ID: DRYER-NH-03
Title: No heat after overheat with weak vent (fuse over element)
Package: dryer-core 1.4.2
User Reports:
  - No heat
  - Recent overheat
Evidence Sequence:
  - templateId: problem-starter-complaint
    answer: "No heat"
  - templateId: drum-turns
    answer: "Turns normally"
  - templateId: cycle-heat-setting
    answer: "Yes, heat cycle"
  - templateId: recent-overheat
    answer: "Yes, very hot or shut off from heat"
  - templateId: exterior-airflow
    answer: "Weak"
Expected Next Action:
  type: Guidance
  content: "Airflow first; open fuse is not a beginner jumper/replace-and-done path"
Expected Safety Decision: Continue (exterior airflow); escalate before live testing
Notes:
  - thermal-fuse-open net >= heating-element-failed
  - Must not instruct bypassing or jumping the thermal fuse
```

### DRYER-NH-04
```yaml
Scenario ID: DRYER-NH-04
Title: Always cold on this complaint (element over fuse)
Package: dryer-core 1.4.2
User Reports:
  - No heat
  - Never heated on this complaint
Evidence Sequence:
  - templateId: problem-starter-complaint
    answer: "No heat"
  - templateId: drum-turns
    answer: "Turns normally"
  - templateId: cycle-heat-setting
    answer: "Yes, heat cycle"
  - templateId: heat-before-failure
    answer: "Never heated on this complaint / always cold"
Expected Next Action:
  type: EvidenceRequest
  needed: "Element family over one-shot fuse"
Expected Safety Decision: Continue; no live metering
Notes:
  - heating-element-failed net > thermal-fuse-open
```

### DRYER-NH-05
```yaml
Scenario ID: DRYER-NH-05
Title: Air-only / fluff setting (not a failed heater)
Package: dryer-core 1.4.2
User Reports:
  - No heat
Evidence Sequence:
  - templateId: problem-starter-complaint
    answer: "No heat"
  - templateId: cycle-heat-setting
    answer: "No, air-only / fluff"
Expected Next Action:
  type: EvidenceRequest
  needed: "Setting, not parts"
Expected Safety Decision: Continue
Notes:
  - heating-element-failed and thermal-fuse-open must not be supported
  - Must not jump to element replacement
```

### DRYER-NH-06
```yaml
Scenario ID: DRYER-NH-06
Title: Cold damp clothes and normal exterior airflow
Package: dryer-core 1.4.2
User Reports:
  - No heat
  - Clothes cold and damp
Evidence Sequence:
  - templateId: problem-starter-complaint
    answer: "No heat"
  - templateId: drum-turns
    answer: "Turns normally"
  - templateId: clothes-feel-after-cycle
    answer: "Cold and still damp"
  - templateId: exterior-airflow
    answer: "Normal"
Expected Next Action:
  type: EvidenceRequest
  needed: "No-heat family, not a blocked vent"
Expected Safety Decision: Continue
Notes:
  - Restricted exhaust must not outrank heating-element
  - heating-element-failed is supported; restricted-exhaust is not
```

### DRYER-NH-07
```yaml
Scenario ID: DRYER-NH-07
Title: Warm damp clothes and weak vent (restriction, not no-heat)
Package: dryer-core 1.4.2
User Reports:
  - Takes long / damp with heat
Evidence Sequence:
  - templateId: problem-starter-complaint
    answer: "No heat"
  - templateId: clothes-feel-after-cycle
    answer: "Warm or hot but still damp"
  - templateId: exterior-airflow
    answer: "Weak"
Expected Next Action:
  type: Guidance
  content: "Clear lint/vent path before heater-circuit talk"
Expected Safety Decision: Continue (exterior work)
Notes:
  - restricted-exhaust-airflow net > heating-element-failed and thermal-fuse-open
```

### DRYER-NH-08
```yaml
Scenario ID: DRYER-NH-08
Title: Smoke or sparking on a no-heat start
Package: dryer-core 1.4.2
Tags: [safety-critical]
User Reports:
  - No heat
  - Smoke / sparking
Evidence Sequence:
  - templateId: problem-starter-complaint
    answer: "No heat"
  - templateId: hazard-observation
    answer: "Yes"
Expected Next Action:
  type: Stop
  reason: "Possible fire or smoke hazard"
Expected Safety Decision: Stop
Notes:
  - Must not continue into beginner heater DIY
  - Must not instruct live electrical testing
```
