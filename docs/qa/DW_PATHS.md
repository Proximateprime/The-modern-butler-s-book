# Dishwasher Phase 1 paths (trust bar)

Top paths only — not an encyclopedia. **dishwasher-core 0.2.3**. No AR / AI images. No beginner live-electrical DIY. No sealed pump. No gas. **No dryer lint-filter assets.**

Read from code on **2026-08-22**. Tests: `test/dishwasher_mvp_test.dart`, `test/inspect_step_test.dart`. Changelog: [`docs/knowledge/dishwasher/CHANGELOG.md`](../knowledge/dishwasher/CHANGELOG.md). Phone walkthrough for standing water: [`REGRESSION_PHONE.md`](REGRESSION_PHONE.md) §C. Dishwasher is **not** in Sample home — **Add Dishwasher** first. Sample reset: [`DEMO_RESET.md`](DEMO_RESET.md).

Each path below: discriminators → easy checks first → text inspect when useful → safety stops → guidance **I did this** → verify → **Fixed** history.

Starter: **What is the dishwasher doing?** (never dryer **What's going on?**).

---

## Trust bar (every path)

| Piece | What “done” looks like |
|---|---|
| Discriminators | Observation chips that split competing modes (not “is the pump dead?”) |
| Easy checks first | Interview order from `dishwasherEasyCheckOrderForEvidence`. Rinse / pull-out / disconnect stay gated until those looks (or **Already checked** / inspect chips) |
| Text inspect | LOOK FOR + **Matches / OK** · **Doesn't match / Not OK** · **Can't see** · **Already checked**. Optional flashlight camera. **Camera never diagnoses.** |
| Safety | Unplug before reaching into the tub or pulling the unit. Hard-stops: sealed pump, live electrical, gas, smoke/spark/burning smell |
| Guidance | **I did this** / **I already did this** / **I couldn't**. Easy look before rinse-filter / straighten-hose / lift-cap |
| Verify | Close-path **Confirmed** then **End Session — Ready to resolve** |
| History | Appliance **Repair history**: newest first, `YYYY-MM-DD · Fixed`. In-progress omitted |

**Skip to best guess** is OK after the easy looks if you need the conclusion card.

---

## Path map

| Starter chip | Competing modes | First easy checks | Inspect (if templates not already recorded) |
|---|---|---|---|
| **Standing water** | Clogged tub filter | Filter/sump → door click → drain hose / high-loop / knockout | Tub filter/sump → door latch → drain configuration |
| **Won't drain** | Kinked/blocked drain path vs clogged filter | Same three looks (filter first) | Same three looks |
| **Won't fill** | Closed under-sink supply vs packed air-gap cap | Supply tap + air-gap cap | **Look at the supply tap and air-gap cap** |
| **Poor clean** | Clogged spray arms vs dirty filter | Filter/sump → spray-arm holes | Filter/sump then **Look at the spray-arm holes** |
| **Leaks** | Door gasket drip vs visible sink hose | Door seal or under-sink hose | **Look at the door seal and visible sink hose** |
| **Won't start** / **Door won't close** | Door not latched | Door click | Door latch only — **not** the tub-filter walk |

---

## A. Won't drain / standing water

**Discriminators:** accessible tub filter packed vs not; drain hose kinked / no high loop / packed air gap / leftover disposal knockout.

1. **Add Dishwasher** → **Start repair** → **Standing water** or **Won't drain**.
2. Standing water ranks the filter leader. Won't drain ranks drain-path and filter.
3. **I'll repair**. Cleaning path — no sealed-pump **purchase** row.
4. Inspect if unrecorded: **Look at the tub filter and sump** → **Check that the door latches** → **Look at the drain hose, high-loop, or air gap** (knockout copy is on this step).
5. Guidance step 1 is a **look**. **Do not** see unplug / rinse-filter / straighten-kinks on step 1. **I did this** through the looks, then unplug, rinse **only** the user-accessible filter, or straighten a **visible** hose.
6. Verify: *After unplugging and cleaning the accessible tub filter…* (or drain-path verify) **Confirmed** → **Fixed** → dishwasher history row.

Pass: filter/sump and drain-configuration inspect before teardown; no dryer lint inspect; no meter; no sealed pump.

---

## B. Won't fill

**Discriminators:** under-sink supply closed vs air-gap cap packed.

1. **Won't fill**. *Is the under-sink dishwasher supply tap open, and is the air-gap cap clear…?* → **No** for this leader.
2. **I'll repair**. Stay under the sink — no fill-valve body, no sealed pump.
3. Inspect if unrecorded: **Look at the supply tap and air-gap cap**.
4. Guidance: look first; open the tap; lift/rinse an air-gap cap if present; unplug before moving the dishwasher. **I did this**.
5. Verify a short cycle starts filling → **Fixed** → history.

Pass: no live electrical; no cabinet wiring; no dryer assets.

---

## C. Poor clean

**Discriminators:** dirty accessible filter vs clogged spray-arm holes / packed load.

1. **Poor clean**. Filter debris **Yes** supports filter and spray-arm modes. Spray-hole **Yes** supports spray arms.
2. **I'll repair**.
3. Inspect if unrecorded: **Look at the tub filter and sump** then **Look at the spray-arm holes**. No drain-hose inspect on this leader.
4. Guidance: look with the door open; unplug before lifting arms or the filter; rinse the accessible filter; toothpick visible holes only. No sealed pump. **I did this**.
5. Verify a short rinse is cleaner → **Fixed** → history.

Pass: spray look is in-tub text, not AR; standing water is still §A, not a motor path.

---

## D. Door / latch (won't start or door won't close)

**Discriminators:** door/lid not clicked (Phase 1 does **not** add a live-electrical no-power encyclopedia mode).

1. **Won't start** or **Door won't close**. Door click **No** → latch leader.
2. Inspect if unrecorded: **Check that the door latches** only.
3. Guidance: remove anything in the seal; firm click; **do not** bypass the door switch; **do not** walk the tub-filter rinse. **Never** open the control box or use a meter.
4. Verify Start begins a cycle → **Fixed** → history.

Pass: latch look only; camera does not diagnose.

---

## E. Leak (observational / safe)

**Discriminators:** drip at the door gasket vs drip at a **visible** hose under the sink.

1. **Leaks**. *Is the leak at the door seal, or at a visible hose under the sink?* → **Door seal** or **Under the sink** (same observational leader). **Not leaking** excludes it.
2. Inspect if unrecorded: **Look at the door seal and visible sink hose**.
3. Guidance: wipe food from the gasket; firm latch; unplug before pulling the unit; hand-check a visible nut only. No sealed tub/pump split.
4. Verify leak gone on a short cycle → **Fixed** → history.

Pass: floor water is not a “replace the tub” path; no AR pins.

---

## Safety (all paths)

If *Do you notice smoke, sparking, or a sharp burning-electrical smell?* → **Yes**: hard-stop. No **Fixed**. Call a professional.

Do not file missing wash-motor, heater, or control-board encyclopedia modes — out of Phase 1 trust bar.
