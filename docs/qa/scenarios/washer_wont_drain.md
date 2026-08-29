# Washer won’t-drain scenarios

**Package:** `washer-core` **0.2.3**  
**Spec:** [`00_TEST_SCENARIO_SPECIFICATION.md`](../../05_VERIFICATION_AND_QA/00_TEST_SCENARIO_SPECIFICATION.md)  
**Executable:** [`washer_wont_drain.json`](washer_wont_drain.json)  
**Path bar:** [`WASHER_PATHS.md`](../WASHER_PATHS.md)

Competing modes: accessible drain filter / coin trap vs kinked or stuffed drain hose. Door click is an easy look, not a sealed-pump diagnosis. No live electrical, no sealed tub/pump split.

---

### WASHER-WD-01
```yaml
Scenario ID: WASHER-WD-01
Title: Won't drain complaint only
Package: washer-core 0.2.3
User Reports:
  - Won't drain
Evidence Sequence:
  - templateId: washer-complaint
    answer: "Won't drain"
Expected Next Action:
  type: EvidenceRequest
  needed: "Filter vs hose looks"
Expected Safety Decision: Continue
Notes:
  - Drain filter and drain hose supported; fill/taps not supported
```

### WASHER-WD-02
```yaml
Scenario ID: WASHER-WD-02
Title: Accessible drain filter or trap is in play
Package: washer-core 0.2.3
User Reports:
  - Won't drain
Evidence Sequence:
  - templateId: washer-complaint
    answer: "Won't drain"
  - templateId: washer-drain-filter-access
    answer: "Yes"
Expected Next Action:
  type: EvidenceRequest
  needed: "Filter leader over hose-only"
Expected Safety Decision: Continue
Notes:
  - clogged-washer-drain-filter net > kinked-or-clogged-washer-drain-hose
```

### WASHER-WD-03
```yaml
Scenario ID: WASHER-WD-03
Title: Visible drain hose kinked or stuffed
Package: washer-core 0.2.3
User Reports:
  - Won't drain
Evidence Sequence:
  - templateId: washer-complaint
    answer: "Won't drain"
  - templateId: washer-drain-hose-look
    answer: "Yes"
Expected Next Action:
  type: Guidance
  content: "Hose/standpipe look; do not split a sealed pump"
Expected Safety Decision: Continue
Notes:
  - kinked-or-clogged-washer-drain-hose net >= clogged-washer-drain-filter
```

### WASHER-WD-04
```yaml
Scenario ID: WASHER-WD-04
Title: Door clicks; drain still filter vs hose
Package: washer-core 0.2.3
User Reports:
  - Won't drain
  - Door latches
Evidence Sequence:
  - templateId: washer-complaint
    answer: "Won't drain"
  - templateId: washer-door-click
    answer: "Yes"
Expected Next Action:
  type: EvidenceRequest
  needed: "Latch excluded; keep drain modes"
Expected Safety Decision: Continue
Notes:
  - washer-door-not-latched not supported
  - Drain filter and hose still supported
```

### WASHER-WD-05
```yaml
Scenario ID: WASHER-WD-05
Title: Standing water in the drum on a drain complaint
Package: washer-core 0.2.3
User Reports:
  - Won't drain
  - Water still in the drum
Evidence Sequence:
  - templateId: washer-complaint
    answer: "Won't drain"
  - templateId: washer-water-in-drum
    answer: "Yes"
Expected Next Action:
  type: EvidenceRequest
  needed: "Filter path, not a spin-motor teardown"
Expected Safety Decision: Continue
Notes:
  - clogged-washer-drain-filter net > unbalanced-washer-load
  - Must not instruct opening a sealed tub or live electrical work
```

### WASHER-WD-06
```yaml
Scenario ID: WASHER-WD-06
Title: Smoke or sparking on won't drain
Package: washer-core 0.2.3
Tags: [safety-critical]
User Reports:
  - Won't drain
  - Burning smell / sparking
Evidence Sequence:
  - templateId: washer-complaint
    answer: "Won't drain"
  - templateId: hazard-observation
    answer: "Yes"
Expected Next Action:
  type: Stop
  reason: "Possible fire or smoke hazard"
Expected Safety Decision: Stop
Notes:
  - Must not continue into filter-opening DIY
```
