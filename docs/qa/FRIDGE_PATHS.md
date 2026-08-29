# Fridge observational paths (trust bar)

Observational only — not an encyclopedia. **fridge-core 1.0.1**. No AR / AI images. No refrigerant. No sealed-system DIY. No compressor live diagnostics. No beginner live-electrical DIY. No gas.

Read from code on **2026-08-22**. Tests: `test/fridge_mvp_test.dart`, `test/inspect_step_test.dart` (temps → gasket → vents → coils). Inventory: [`PACKAGE_INVENTORY.md`](PACKAGE_INVENTORY.md). **Not** in Sample home.

Starter: **What is the fridge doing?** (never dryer **What's going on?**).

Beyond these looks (warm after settings/vents/seal/coils, grinding from the machine, dark with a firm plug and breaker on): **call a technician**. Do not invent a sealed-system procedure.

---

## Trust bar (every path)

| Piece | What “done” looks like |
|---|---|
| Discriminators | Observation chips that split competing modes (not “is the compressor dead?”) |
| Easy checks first | Interview order from `fridgeEasyCheckOrderForEvidence`. Coil vacuum / pull-out stays gated until temps, door seal, and vents (or **Already checked** / inspect chips) |
| Text inspect | LOOK FOR on cooling / door / setpoint paths. Optional flashlight camera. **Camera never diagnoses.** Leak, ice, noise, and won’t-run have **no** inspect chain (looks stay in the interview) |
| Safety | Unplug before pulling the cabinet or touching coils / drip pan. Hard-stops: sealed cooling / refrigerant, live electrical, compressor live diagnostics, smoke/spark/burning smell |
| Guidance | **I did this** / **I already did this** / **I couldn't**. Observational looks before vacuum coils |
| Verify | Close-path **Confirmed** then **End Session — Ready to resolve**. Cooling recovers over **hours**, not one cycle |
| History | Appliance **Repair history**: newest first. In-progress omitted |

---

## Path map

| Starter chip | Competing modes | First easy checks | Inspect |
|---|---|---|---|
| **Not cooling** | Dirty coils / tight clearance vs door gasket vs temp setpoints | Temps → door seal → internal vents → coils/space (unplug for coils) | Temps → gasket → vents → coils |
| **Fridge warm, freezer cold** | Blocked internal vents vs door gasket | Door seal → internal vents | Gasket + vents |
| **Too cold** | Temp controls at an extreme | Temps | Temps + gasket |
| **Water leak** | Visible drain / drip pan (not a cut tube) | Drain or pan look | None |
| **Ice maker** | Switch/supply off vs bin/dispenser jam | Ice maker on + tap/line → bin jam | None |
| **Noisy** | Cabinet not level or items rattling | Level / rattle look | None |
| **Door won't close** | Gasket dirty, torn, or door ajar | Door seal | Gasket |
| **Won't run** | Unplugged / breaker off | Plug and breaker look (no meter) | None |

---

## A. Not cooling

**Discriminators:** mid-range vs extreme setpoints; gasket seated vs ajar; vents clear vs blocked; accessible coils/grille dusty or cabinet packed to the wall.

1. **Add Fridge** → **Start repair** → **Not cooling**.
2. Temps **Yes — mid-range**. Door seal **Yes**. Internal vents **No** (clear). Coils/space **Yes** if you want the coils leader.
3. **I'll repair**. Vacuum accessible coils / grille only after unplug. **No** sealed-system **purchase** row.
4. Inspect if unrecorded: temperature controls → door gasket → internal vents → coils (LOOK FOR; **Matches / OK** on temps means mid-range).
5. Guidance: look at settings, gasket, and vents **before** unplug / vacuum. **Do not** see coil vacuum on step 1. Wait several hours to judge cooling.
6. Verify colder interior after hours → **Fixed** → fridge history row.

Pass: observational looks before pull-out; no refrigerant; no compressor testing.

---

## B. Fridge warm, freezer cold

**Discriminators:** food covering internal vents vs a door that does not seal.

1. **Fridge warm, freezer cold**. Door seal then vents.
2. Guidance stays **inside** the compartments. Unplug language is a stop before coil/compressor work — do not open the sealed system.
3. Verify fridge side colder after hours with vents clear and doors shut → **Fixed**.

Pass: this is not a “recharge the system” path.

---

## C. Water leak / ice (observational)

**Leak:** water from a **visible** freezer drain, drip pan, or compartment — not from a cut tube. Unplug before moving or emptying a slide-out pan. Warm water in a **user-accessible** drain hole only. No piercing lines.

**Ice maker:** switch/arm on; water tap behind the fridge open; accessible line unkinked. Empty clumped ice from the **user-accessible bin**. Do not dismantle a sealed ice-maker body.

If the leak is a cut cooling tube, or ice never forms after switch and tap are confirmed: **call a technician**.

---

## D. Noise / won't run

**Noisy:** cabinet rocks or bottles rattle. Ice dropping into the bin can be normal. Grinding or screeching from the machine itself → **call a technician**. No compressor live diagnostics.

**Won't run:** seat the plug; breaker on once. **Do not test live voltage.** If it stays dark with a firm plug and breaker on → **call a technician**.

---

## Safety (all paths)

If *Do you notice smoke, sparking, or a sharp burning-electrical smell?* → **Yes**: hard-stop. No **Fixed**. Call a professional.

Never: add / recover / handle refrigerant, open the sealed cooling system, pierce or puncture cooling tubes, test the compressor or start relay while energized, use a meter on live circuits.

Do not file sealed-system encyclopedia modes — out of this observational trust bar.
