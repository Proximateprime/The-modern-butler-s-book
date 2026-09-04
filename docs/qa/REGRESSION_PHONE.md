# Phone regression (manual)

One walkthrough on a **phone** (or Android emulator): dryer no-heat, washer won’t-drain, dishwasher standing-water / tub filter. Covers **inspect**, **tools**, **Continue repair**, and **Repair history**. Labels match the UI. Frozen chrome: [`GOLDEN_LABELS.md`](GOLDEN_LABELS.md).

Hand to testers: [`TESTER_BRIEF.md`](TESTER_BRIEF.md) · Phase 2 [`TESTER_BRIEF_PHASE2.md`](TESTER_BRIEF_PHASE2.md). Phase 1 kit: [`REGRESSION_PHASE1.md`](REGRESSION_PHASE1.md). Phase 2 kit: [`REGRESSION_PHASE2.md`](REGRESSION_PHASE2.md). Discriminator scenarios: [`scenarios/README.md`](scenarios/README.md). Do not file [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md).

Not an in-app checklist. Sample: [`DEMO_RESET.md`](DEMO_RESET.md) (**Include sample open session** off). Resume table: [`RESUME_CASES.md`](RESUME_CASES.md). Inspect authoring: [`INSPECT_STEP_AUTHORING.md`](INSPECT_STEP_AUTHORING.md). Inventory share: [`EXPORT_INVENTORY.md`](EXPORT_INVENTORY.md). Airplane / offline: [`OFFLINE_SMOKE.md`](OFFLINE_SMOKE.md).

```bash
flutter run
```

Use a device or emulator. Chrome is not this script (add-appliance scan and live inspect camera are phone behaviors).

---

## Setup (once)

If **What Butler does** appears (greeting, no **1 of 3**): **Skip**, or tap through **What it doesn’t do** and **Your household stays here**. Then **Safety disclaimer** → **I understand**. Details: [`FIRST_RUN.md`](FIRST_RUN.md).

Starting a repair may show **Safety disclaimer**. Tap **I understand**.

Load or reset **Sample home**. Dryer and washer are canned. Dishwasher is **not** in the sample — add one in §C.

Pass: home shows **Laundry Room Dryer** and **Laundry Room Washer**.

---

## Shared chrome (every path)

**Inspect** (on the lint/hood/hose easy-check, and after **I'll repair** / Parts, **before Tools**, if those templates are not recorded). **Most likely** → **Review what you checked** (does not restart the interview).

| Role | Exact label |
|---|---|
| Progress | `Inspect N of M` |
| LOOK FOR | Specific sentence (required) |
| Camera | **Use camera while I look** (optional flashlight; no part picture) |
| Blocking line | `Finish this look before opening a panel or pulling the appliance out.` |
| Chips | `Matches / OK` · `Doesn't match / Not OK` · `Can't see` · `Already checked` |

Chips write existing templates. **Can't see** / **Already checked** still advance. Camera never diagnoses. Location pictures and Show me where are parked. Denied camera: text inspect still works.

**Tools** (when the leader has a real checklist):

| Role | Exact label |
|---|---|
| Card | `Tools` |
| Helper | `Required tools must be marked I have before panel steps unlock.` |
| Marks | `I have this` · `I don't` |
| Optional save | `Also save to my tools` (must not save on its own) |
| Owned | `In your tools` |
| Continue | `Continue` (if still on the card) |

**I don't** on a **Required** row must not unlock invasive guidance. **I don't** on **Optional** must not block.

**Resume:** **Exit** in the session bar → detail **Continue repair** (home may show it too) → first incomplete **Safe Guidance** step. Do not re-ask the starter chips. See [`RESUME_CASES.md`](RESUME_CASES.md).

**History:** **Record outcome** → **Fixed — problem resolved** → **Save to household memory** → Done wrap-up → **Save & go home**. Detail **Repair history**: newest first, subtitle `YYYY-MM-DD · Fixed`. In-progress is not a row. Empty copy **No repairs yet** only when that appliance has no completed outcomes.

---

## A. Dryer — No heat, drum turns

Packages: **dryer-core 1.4.1**.

1. Open **Laundry Room Dryer** (Whirlpool **WED5000DW**) → **Start repair** (not **Continue repair**).
2. **What's going on?** Helper: *Describe what you notice — not what you think is broken*. **No heat** → **Confirm and continue**. **Starting from: No heat**.
3. If asked *Is the dryer set to a heat cycle rather than air-only / fluff?* → **Yes, heat cycle**.
4. *Does the drum turn during the cycle?* → **Turns normally**.
5. If asked *Is there any warmth after the dryer has run briefly?* → **No warmth**.
6. Easy checks use inspect LOOK FOR cards (same chips: **Matches / OK**, **Doesn't match / Not OK**, **Can't see**, **Already checked**), in this order:
   1. **Look at the lint filter** → **Matches / OK** (Clean) unless you want a clogged-filter path.
   2. **Check the outside vent hood** → **Matches / OK** (Normal), or **Doesn't match / Not OK** (Weak) if you want a vent leader.
   3. **Look at the visible vent hose** → **Matches / OK** (Looks clear).
7. If more questions: **Skip to best guess**.
8. **Most likely** → **Continue** → **How do you want to handle this?** → **I'll repair** (leave **Call a pro**). **Back** returns to **Most likely**.
9. **Parts & cost** if shown: *Estimates only. Not a quote.* Only the part this path replaces (screenshot table: [`PARTS_COST.md`](PARTS_COST.md)). No lint-filter / vent-kit purchase lines on an airflow-cleaning path. No washer drain-trap / inlet-hose rows on a dryer fuse or vent outcome. **Continue**.
10. **Inspect** only if lint / exterior airflow / vent hose were **not** recorded in interview: **Inspect 1 of 3** **Look at the lint filter** → **2 of 3** **Check the outside vent hood** → **3 of 3** **Look at the visible vent hose**. If interview already answered those three, skip this phase. See [`INSPECT_TEXT_PATH.md`](INSPECT_TEXT_PATH.md).
11. **Tools** if shown (fuse/panel leader): **Screwdriver** **Required**, **Flashlight** **Optional**. Heating-element / beginner-only leaders may skip **Tools**.
12. **Safe Guidance** **Step 1 of N**. Title **Check the lint filter**. Body starts *Check airflow before opening the cabinet. Pull the lint filter…* **I did this** (or **I already did this**). Do **not** see **Open the heater service panel** on step 1.
13. Tap **I did this** at least twice more. **Exit** → **Continue repair**. Land on the first incomplete step (after three **I did this**, **Step 4 of N** if more remain).
14. Finish **I did this**. Optional **While you’re here** → **Skip all**. Verification → **Confirmed**. **End Session — Ready to resolve**.
15. **Fixed — problem resolved** → **Save to household memory** → **Save & go home**.
16. Dryer **Repair history**: new row at the top (`YYYY-MM-DD · Fixed`). Sample home already has older **Fixed** rows below.

Pass: easy checks and inspect (when shown) are filter → hood → hose; required tools and incomplete inspect block the heater panel; resume is mid-guidance; history has the new **Fixed** row.

---

## B. Washer — Won't drain

Packages: **washer-core 0.2.3**. Full trust-bar paths: [`WASHER_PATHS.md`](WASHER_PATHS.md).

1. Open **Laundry Room Washer** (Whirlpool **WTW5000DW**) → **Start repair**. First screen is **What is the washer doing?** — not dryer **What's going on?**
2. **Won't drain**.
3. *Does the door close firmly until you feel or hear a solid click?* → **Yes**.
4. *Can you see an accessible drain filter or pump trap at the front or bottom (without opening a sealed cabinet)?* → **Yes**.
5. If more questions (hazard, etc.): **Skip to best guess**. **Best match so far** may show **Clogged drain filter or pump trap**. **Accept as Primary & verify** or skip, then **Most likely**. No live % during questions.
6. **Continue** → **I'll repair**.
7. **Parts & cost** only if this path has a purchase part. Drain-filter **cleaning** does not list a drain-trap purchase.
8. **Tools**: **Shallow pan and towel** **Required** → **I have this**. **Flashlight** **Optional**. **I don't** on the pan must not unlock opening the filter.
9. **Inspect** if door/filter templates were not recorded: **Inspect 1 of 2** **Check that the door latches** → **2 of 2** **Look at the drain filter or coin trap**. Then **Safe Guidance**. Interview answers skip inspect.
10. **Safe Guidance** **Step 1 of N**. Title **Safety limit for this check**. Body: *Check that the washer door closes firmly until you feel or hear a click. Do not bypass the door switch.* Do **not** see *Unplug the washer* or *Open only the user-accessible filter* on step 1.
11. **I did this** through the door look and *Look for an accessible drain filter…* **Exit** → **Continue repair** on the first incomplete step.
12. Finish guidance (unplug, pan, open accessible filter, debris, restore power). **Confirmed** on *After unplugging and cleaning the accessible drain filter or pump trap, does the washer drain a short test cycle?* **End Session — Ready to resolve**.
13. **Fixed** → save. Wrap-up may show *Typical interval: about every 30 days* for the drain-filter prevention note.
14. Washer **Repair history**: new top row (often **Won't drain** / **Drain filter path**). Dryer history unchanged.

Pass: inspect/guidance order is door → filter look before opening the trap; pan required; resume mid-guidance; one **Fixed** history row.

---

## C. Dishwasher — Standing water (tub filter)

Packages: **dishwasher-core 0.2.3**. Ready for this path (inspect + close path + history). Not in Sample home.

1. Home → **Add Dishwasher** → **Save appliance** (or type brand/model). Phone may show **Scan rating plate** with *Scan the rating plate for brand and model only, then edit anything that looks wrong.* If scan is hidden: *Enter the brand, model, and serial from the rating plate.* Open the dishwasher → **Start repair**.
2. **What is the dishwasher doing?** → **Standing water** (not **Won't fill** / **Poor clean**). That ranks **Clogged tub filter**.
3. Easy checks when asked: door click **Yes**; filter debris *After unplugging, can you see food debris in the accessible filter…* → **Yes** if you want the filter leader. **Skip to best guess** if needed.
4. **Most likely** **Clogged tub filter** → **Continue** → **I'll repair**.
5. **Parts & cost** only if a purchase row exists for this path. **Tools** may be skipped (`None for beginner external checks`).
6. **Inspect** if templates unrecorded: **Inspect 1 of 3** **Look at the tub filter and sump** → **2 of 3** **Check that the door latches** → **3 of 3** **Look at the drain hose, high-loop, or air gap**. **Matches / OK** on the filter step stores **No** (mesh looks clear) — that is the template polarity, not a bug. Then **Safe Guidance**.
7. **Safe Guidance** step 1 starts *Look at the accessible tub filter under the lower rack. Do not open a sealed pump.* Do **not** see *Remove and rinse only the user-accessible filter* on step 1.
8. **I did this** twice → **Exit** → **Continue repair**.
9. Finish, **Confirmed** on *After unplugging and cleaning the accessible tub filter, does a short drain or rinse leave the tub empty?* **Fixed** → save.
10. **Repair history**: new top row (**Tub filter path** / standing-water summary). `YYYY-MM-DD · Fixed`.

Pass: inspect is filter → door → hose when shown; rinse/open-filter stays after the look; resume mid-guidance; one **Fixed** row. Other DW starters: [`DW_PATHS.md`](DW_PATHS.md).

---

## Maintenance (optional)

On the appliance **Maintenance** list (checkbox — no push):

| State | Copy |
|---|---|
| Not done, future | **Next due YYYY-MM-DD** |
| Past due | **Next due YYYY-MM-DD · Overdue** |
| Done, no interval | **Last done YYYY-MM-DD** — no invented **Next due** |
| Done, repeating | **Last done** today, **Next due** rolled forward, **About every N days** |

Sample **Clean lint system** is a 30-day dryer item: **Done** stamps last completed and rolls **Next due**. Every-load lint **filter** copy does not invent a calendar interval. Drain-filter / tub-filter / vent-hose notes may also show **About every 30 days**.

---

## Out of scope

Ranking internals, live electrical, sealed tub/pump/refrigerant, fridge, fill/spin/leak paths, Chrome-only scan copy, new in-app QA screens. **I don't** on a required tool still blocks invasive steps.
