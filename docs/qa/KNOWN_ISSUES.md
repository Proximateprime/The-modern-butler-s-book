# Known issues (do not file)

Expected product limits and authored quirks, **2026-08-25**. Not a backlog. Parking-lot ideas (AR, HVAC, cloud sync) stay out of this list.

## Expected limits

| What you will see | Why |
|---|---|
| Camera does not pick a part or draw a live “found it” box | Inspect is look-along. Chips diagnose; live CV is out of scope. |
| No **Show me where** button, no part diagrams anywhere | AR stays parked. The dead screen and its unbundled SVGs were deleted ([`AUDIT_POLISH_MVP.md`](AUDIT_POLISH_MVP.md)). |
| No **Multimeter** / **Voltage tester** to add under Tools | No supported path asks a beginner to measure a live circuit, so the app does not offer the tool. A meter saved by an older build still shows in your list. |
| On a pro-only path (thermal fuse, heating element, door switch) **Parts & cost** shows only a **Pro ~** price | Deliberate: the app will not quote you a self-repair it will not walk you through. A **resettable thermal cutoff** is a different path (`accessible-thermal-reset`) and can complete at home with vent/lint as the root cause. |
| Chrome: *Live camera works on a phone…*; no **Scan rating plate** | Web has no rating-plate scan. Inspect camera is phone. |
| Chrome export may be share sheet or clipboard, not a Downloads `.json` | Documented in [`BACKUP_SMOKE.md`](BACKUP_SMOKE.md). Restore still needs a file. |
| **Parts & cost** says *Estimates only. Not a quote.* | Stubs, not live quotes or payment. |
| Maintenance notification is not a calendar event | Local ping when the reminder is **already due**, or a home banner on next open if notifications are off. No Google/Apple Calendar. Future dues wait for the next app open. |
| Typed “Other” symptoms do not invent a procedure | Text is stored. Unmatched copy says guidance may be limited. Optional enrichment is a stub (`StubEnrichmentProvider`); it does not diagnose. |
| Sample home is dryer + washer only | No canned dishwasher or fridge. Add them to test those paths. |
| Sample dryer has no `From your household history` card | Canned closes pin thermal-fuse / dusty-lint, which must not become a DIY pattern hint. Need two verified Fixed records on another appliance. |
| No **Household Pro** switch in Settings on the release APK | It is debug-only now. Store billing is not wired and everything it changes is optional export formatting. [`MONETIZATION_HOOK.md`](MONETIZATION_HOOK.md). |
| Knowledge Factory folder is not in the app | `knowledge_factory/prototype/` is authoring-time only. |
| No iOS project in this repo | Android APK / `flutter run` on Android (or Chrome for web-only checks). |
| Inspect only on some modes | Dryer **13 / 41** heat-airflow modes (includes resettable cutoff); washer **4 / 9**; DW **3 / 6**; fridge **4 / 9**. Other modes skip inspect. See [`PACKAGE_INVENTORY.md`](PACKAGE_INVENTORY.md). |

## Authored close-path (not a bug)

**Thermal fuse** (`thermal-fuse-open`) and **heating element** (`heating-element-failed`): **Confirmed** does **not** unlock **Fixed**. Beginner checks identify the pattern; fuse swap / element service is professional. End Session is **Needs professional**. Same pattern on other heater-circuit DIY-cannot-complete leaders (high-limit, cycling thermostat, relay/control, thermistor, timer heat segment) and other `allowResolvedWhenConfirmed: false` modes (e.g. hard-stop hazard). Door-switch **Fixed** when a firm click actually starts the machine stays allowed.

**Resettable thermal cutoff** (`accessible-thermal-reset`) and **motor overheat protector** are the DIY split: cooldown / visible reset if present, then clear airflow. That is not a fuse swap. Device-test notes: [`TEST_FEEDBACK_AUG25.md`](TEST_FEEDBACK_AUG25.md).

## Inspect chip polarity (not a bug)

**Matches / OK** means the OK description. Some templates are “is the problem present?”, so OK stores **No**:

- Dishwasher tub-filter inspect: **Matches / OK** → `No` (mesh clear).
- Dishwasher hose / washer standpipe & hose-run inspect: **Matches / OK** → `No` (not kinked / not stuffed).
- Washer drain-filter inspect (`washer-core` **0.2.3**): **Matches / OK** → `No` (trap looks clear); **Doesn't match** → `Yes` (packed). Same split as the dishwasher filter.

## Not in this build

No cloud account, no push, no live quotes, no YOLO/CoreML, no HVAC/AC package, no sealed-system or live-electrical beginner how-to. No Store checkout. Dryer no-heat encyclopedia quality pass (P2-07) was not in this candidate.

## Safety residuals (P1-05)

| Residual | Why it remains |
|---|---|
| Expert Mode can show an **unplugged** heater-panel look / fuse swap on `thermal-fuse-open` | Skill gate already exists (Settings Expert Mode + adult confirm). Live metering, jumpers, gas, and refrigerant stay stripped. |
| Fridge close paths are not in the Phase 1 appliance table | Same `forbidden_guidance` filter still applies if those steps are shown. Observational trust bar: [`FRIDGE_PATHS.md`](FRIDGE_PATHS.md). |
| Dishwasher **Won't start** has only the door-latch path | No observational no-power look was authored. The path is honest about its limit rather than guessing. |
| Confirming thermal fuse still does not unlock **Fixed** | Pattern identification only; replacement is technician (or Expert Mode isolated swap). See authored close-path above. |

Safety checklist: [`SAFETY_PATH_CHECK.md`](SAFETY_PATH_CHECK.md).
