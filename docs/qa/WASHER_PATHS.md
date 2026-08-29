# Washer Phase 1 paths (trust bar)

Top paths only — not an encyclopedia. **washer-core 0.2.3**. No AR / AI images. No beginner live-electrical DIY. No sealed tub/pump. No gas.

Read from code on **2026-08-22**. Tests: `test/washer_mvp_test.dart`, `test/washer_easy_checks_test.dart`, `test/inspect_step_test.dart`. Changelog: [`docs/knowledge/washer/CHANGELOG.md`](../knowledge/washer/CHANGELOG.md). Phone walkthrough for drain: [`REGRESSION_PHONE.md`](REGRESSION_PHONE.md) §B. Sample: [`DEMO_RESET.md`](DEMO_RESET.md) (**Include sample open session** off).

Each path below: discriminators → easy checks first → text inspect when useful → safety stops → guidance **I did this** → verify → **Fixed** history.

Starter: **What is the washer doing?** (never dryer **What's going on?**).

---

## Trust bar (every path)

| Piece | What “done” looks like |
|---|---|
| Discriminators | Observation chips that split competing modes (not “is the pump dead?”) |
| Easy checks first | Interview order from `washerEasyCheckOrderForEvidence`. Repair/unplug stays gated until those looks (or **Already checked** / inspect chips) |
| Text inspect | LOOK FOR + **Matches / OK** · **Doesn't match / Not OK** · **Can't see** · **Already checked**. Optional flashlight camera. **Camera never diagnoses.** |
| Safety | Unplug before opening a filter or loosening a coupling. Hard-stops: sealed tub/pump, live electrical, gas, smoke/spark/burning smell |
| Guidance | **I did this** / **I already did this** / **I couldn't**. Easy look before open-filter / pull-out |
| Verify | Close-path **Confirmed** then **End Session — Ready to resolve** |
| History | Appliance **Repair history**: newest first, `YYYY-MM-DD · Fixed`. In-progress omitted |

**Skip to best guess** is OK after the easy looks if you need the conclusion card.

---

## Path map

| Starter chip | Competing modes | First easy checks | Inspect (if templates not already recorded) |
|---|---|---|---|
| **Won't drain** | Drain filter / coin trap vs kinked or stuffed drain hose | Door click → packed-vs-clear filter look → hose look | Door latch → coin trap → (hose run on hose leader) |
| **Won't fill** | Closed/kinked supply vs packed hose-end screens | Taps/hose (screens only after taps are open) | Taps and inlet hose → screens (screens leader) |
| **Won't spin** | Unbalanced load vs water still in drum (raises drain-filter) | Water in drum → load bunched | None (looks are in-drum; no AR) |
| **Won't start** | Door not latched vs no power / breaker / control lock | Door click → plug, breaker, lock light | Door latch and/or power-lock look |
| **Leaks** | Loose inlet coupling vs drain hose not in standpipe | Leak at tap → standpipe/hose slipped | Coupling drips and/or standpipe + hose run |

**Door won't close** uses the door-latch mode (same inspect/guidance as won't-start latch). Not a fifth encyclopedia family.

---

## A. Won't drain

**Discriminators:** door click; accessible coin-trap **packed vs clear**; drain hose kinked/stuffed vs clear. Inspect **Matches / OK** on the coin trap means the trap looks clear (`No` on the packed question).

1. Sample washer → **Start repair** → **Won't drain**.
2. Door click **Yes**. Drain filter access **Yes** if you want the filter leader; hose look **Yes** if you want the hose leader.
3. **I'll repair**. No drain-trap **purchase** row (cleaning path). **Shallow pan and towel** **Required**.
4. Inspect only if those templates were not recorded: **Check that the door latches** then **Look at the drain filter or coin trap** (hose leader also **Look at how the drain hose is run**).
5. Guidance step 1: door click. **Do not** see unplug / open the filter on step 1. **I did this** through the looks, then unplug, pan, open **user-accessible** filter only.
6. Verify: *After unplugging and cleaning the accessible drain filter…* **Confirmed** → **Fixed** → washer history row.

Pass: door → filter look before opening the trap; no dryer lint inspect; no meter.

---

## B. Won't fill

**Discriminators:** taps/hose closed or kinked vs grit in hose-end screens (taps already open).

1. **Won't fill**. *Are both water taps fully open…?* → **Yes** (open) or **No** (closed/kinked leader).
2. If taps **Yes**: *After unplugging and closing the taps, do the small screens at the hose ends look packed…?* → **Yes** for screens leader.
3. **I'll repair**. Stay at hose ends — no inlet-valve body.
4. Inspect if unrecorded: **Look at the taps and inlet hose**; screens leader also **Look at the inlet-hose screens**.
5. Guidance: look at taps first; unplug/close taps before loosening a coupling. **I did this**.
6. Verify fill on a short wash → **Fixed** → history.

Pass: taps before screens; no live electrical; no cabinet wiring.

---

## C. Won't spin

**Discriminators:** bunched load vs standing water (that path should become drain, not a motor teardown).

1. **Won't spin**. *Is there still a pool of water in the drum…?* then *Is the load bunched…?*
2. Water **Yes** supports the drain-filter mode — continue as §A (easy drain looks), not a spin-motor panel.
3. Load **Yes** and water **No**: unbalanced-load leader. No inspect chain (in-drum look). Guidance: wait for stop, redistribute, no transmission open, no meter.
4. Verify even spin → **Fixed** → history.

Pass: standing water does not skip to motor; no live electrical.

---

## D. Won't start

**Discriminators:** door/lid not clicked vs unplugged / breaker off / control-lock light.

1. **Won't start**. Door click **No** → latch leader. Door **Yes** then power/lock **No — unplugged, off, or locked** → power/lock leader.
2. Inspect if unrecorded: **Check that the door latches** and/or **Look at power and control lock** (look only — **Do not test live voltage**).
3. Guidance: latch path does **not** walk the drain filter. Power path: seat plug, breaker once, clear lock from the owner book. **Never** open the control box or use a meter.
4. Verify Start begins a cycle → **Fixed** → history.

Pass: two observational leaders only; camera does not diagnose; no voltage procedure.

---

## E. Leak (observational / safe)

**Discriminators:** drip at tap coupling vs hose slipped out of standpipe.

1. **Leaks**. *Is the leak at the tap or the inlet hose coupling?* → **Yes** for loose inlet. *Is the leak behind the washer at the standpipe…?* → **Yes** for not-seated hose.
2. Inspect if unrecorded: **Look at the inlet coupling for drips** and/or **Look at the drain hose in the standpipe** then **Look at how the drain hose is run**.
3. Guidance: look first; unplug before tightening a nut or pulling the washer. Hand-tighten the accessible coupling or reseat/clip the drain hose. No sealed pump split.
4. Verify leak gone on next fill/drain → **Fixed** → history.

Pass: floor water is not a “replace the tub” path; no AR pins.

---

## Safety (all paths)

If *Do you notice smoke, sparking, or a sharp burning-electrical smell?* → **Yes**: hard-stop. No **Fixed**. Call a professional.

Do not file missing spin-motor, inverter, or hall-sensor encyclopedia modes — out of Phase 1 trust bar.
