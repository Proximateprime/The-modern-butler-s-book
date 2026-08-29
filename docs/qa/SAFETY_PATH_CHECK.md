# Safety path check (P1-05)

Audit of **dryer, washer, and dishwasher** guidance that the session can show. Fridge is filtered by the same helper but is not a Phase 1 table row.

Runtime filter: `lib/helpers/forbidden_guidance.dart` via `visibleSafeGuidanceSteps` (`lib/helpers/expert_mode.dart`). Tests: `test/safety_path_check_test.dart`.

## Forbidden as how-to (always)

Even with Expert Mode on:

| Topic | Allowed | Not allowed |
|---|---|---|
| Gas | External supply valve / cycle look; **call a gas technician**; “do not disassemble…” | Replace/repair/disassemble gas valve, igniter, burner, flame sensor |
| Sealed system / refrigerant | “Do not add, recover, or handle refrigerant” | Pierce lines, add/recover refrigerant, open a sealed cooling system as a repair |
| Live electrical | Unplug; breaker glance; “do not measure live voltage” | Multimeter / ohm / continuity / live probe how-to |
| Safeties | “Never bypass the door switch / fuse / high-limit” | Jumper, foil, tape, or defeat interlocks |

Hard-stop evidence (not guidance): gas smell / gas-like odor, live-voltage language, smoke/fire words — `lib/helpers/safety_stop.dart`.

## Expert Mode

Settings adult confirm already exists. Extra **mechanical** steps flagged `expert_ok` may appear (unplugged belt panel; unplugged heater-panel fuse locate). Gas, refrigerant, live metering, and safety-bypass how-to stay stripped.

If a mode has no Expert Mode skill gate, keep those steps off beginner guidance (do not invent a second skill system).

## Escalation when a pro is required

| Path | What the user should see |
|---|---|
| Thermal fuse | After lint/hood/hose: isolate power, **do not meter/jumper**, **call a technician**. Confirmed ≠ Fixed. |
| Heating element / high-limit / supply | External checks, then call a technician. No live heater-circuit test. |
| Gas no ignition | External valve + heat cycle only, then **qualified gas technician**. |
| Motor / start capacitor | Listen only; escalate. |
| Burning/smoke hazard | Stop, unplug, professional inspection. |
| Washer / DW door switch | Firm click; **do not bypass**. Latch service is pro if click fails. |
| DW / washer sealed pump | User-accessible filter/hose only. |

## Checklist (supported packages)

Run `flutter test test/safety_path_check_test.dart`.

- [x] Every dryer / washer / DW close-path **visible** step (beginner and Expert Mode) passes `isAlwaysForbiddenInstruction == false`
- [x] Beginner thermal-fuse path has no heater-panel / fuse-replace how-to
- [x] Observation HOW blocks are not meter/bypass procedures
- [x] Inspect LOOK FOR / preambles are look-along, not defeat instructions
- [x] Gas-like odor answers hard-stop

## Residual risks

Listed in [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md).
