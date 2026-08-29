# Phase 1 regression kit

One pass covering dryer, washer, dishwasher, House Book export, tools persist, **Continue repair**, and offline. Phase 2 (Why ask this, Fixed memory, readiness, pattern hints): [`REGRESSION_PHASE2.md`](REGRESSION_PHASE2.md). Labels below are live UI strings. Frozen chrome: [`GOLDEN_LABELS.md`](GOLDEN_LABELS.md). Longer phone script (same dryer/washer/DW paths): [`REGRESSION_PHONE.md`](REGRESSION_PHONE.md).

**Packages:** dryer-core **1.4.1**, washer-core **0.2.3**, dishwasher-core **0.2.3**. App **0.1.0+1**.

**Scenario data (discriminators / forbidden guidance):** [`scenarios/README.md`](scenarios/README.md) — dryer no-heat (`DRYER-NH-01`…`08`) and washer won’t-drain (`WASHER-WD-01`…`06`). Spec: [`docs/05_VERIFICATION_AND_QA/00_TEST_SCENARIO_SPECIFICATION.md`](../05_VERIFICATION_AND_QA/00_TEST_SCENARIO_SPECIFICATION.md). Asserted by `flutter test test/qa_scenarios_test.dart`.

**Do not file** [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md). Camera never diagnoses. No beginner live electrical, gas, or sealed pump.

```bash
flutter run
```

Phone or emulator for airplane / inspect camera. Chrome is fine for chips, sample reset, export, tools, resume, and **Simulate offline**.

---

## 0. Crash-safe sample (do this first)

First launch if shown: **Skip** or **Get started**, then **I understand**. [`FIRST_RUN.md`](FIRST_RUN.md).

| Control | Exact label |
|---|---|
| Empty home CTA | `Load sample home` |
| Settings section | `Demo` |
| Settings load | `Load sample home` |
| Load snackbar | `Sample home loaded` |
| Toggle | `Include sample open session` |
| Toggle helper | `Shows Continue repair after loading the sample home` |
| Reset | `Reset sample data` |
| Reset helper | `Restore the canned sample home. Safe if it was never loaded.` |
| Reset snackbar | `Sample data reset` (even if sample was never loaded — **no crash**) |
| Clear | `Clear open session` |
| Clear when idle | subtitle `No repair is in progress` · snackbar `No repair is in progress` |
| Clear when open | dialog `Clear open session?` → `Clear session` / `Cancel` |

**Kit setup**

1. Settings → **Demo**: turn **Include sample open session** **off**.
2. Tap **Reset sample data** twice. Must not crash. Snackbar **Sample data reset**.
3. If you never had sample: Home **Load sample home** (or Settings **Load sample home**). Snackbar **Sample home loaded**.
4. Home: household **Sample home**. **Laundry Room Dryer** (Whirlpool **WED5000DW**, serial **DRY-SERIAL-1**) and **Laundry Room Washer** (Whirlpool **WTW5000DW**, serial **WASH-SERIAL-1**). Both show **Start repair**, not **Continue repair**.

Safe if sample was never loaded. Other household profiles stay. Click path: [`DEMO_RESET.md`](DEMO_RESET.md).

Do **not** use **Continue repair** for §A–C unless the step says Exit → resume.

---

## Shared chrome (every repair)

| Role | Exact label |
|---|---|
| Session bar leave | `Exit` |
| Detail / home resume | `Continue repair` |
| Detail new | `Start repair` |
| Skip | `Skip to best guess` |
| Conclusion | `Most likely` · `Continue` |
| Decision | `How do you want to handle this?` · `I'll repair` · `Call a pro` · `Back` |
| Parts | `Parts & cost` · `Estimates only. Not a quote.` · `Continue` |
| Inspect chips | `Matches / OK` · `Doesn't match / Not OK` · `Can't see` · `Already checked` |
| Inspect headings | `LOOK FOR` · `OK looks like` · `Not OK looks like` |
| Inspect camera | `Use camera while I look` (optional). Caption if shown: `Camera does not diagnose. Confirm what you see with the buttons.` |
| Inspect blocking | `Finish this look before opening a panel or pulling the appliance out.` |
| Tools card | `Tools` · `Required tools must be marked I have before panel steps unlock.` |
| Tool marks | `I have this` · `I don't` · `Also save to my tools` · `In your tools` |
| Guidance | `Safe Guidance` · `I did this` · `I already did this` · `I couldn't` |
| Verify | `Confirmed` |
| Close | `End Session — Ready to resolve` |
| Outcome | `Record outcome` · `Fixed — problem resolved` · `Save to household memory` |
| Wrap-up | `Save & go home` |
| History empty | `No repairs yet` |
| History row | `YYYY-MM-DD · Fixed` |

No generated inspect pictures (`locationVisualAidsEnabled` off). **I don't** on **Required** must not unlock invasive steps.

---

## A. Dryer — No heat

Machine-readable cases: [`scenarios/dryer_no_heat.md`](scenarios/dryer_no_heat.md) (`DRYER-NH-01`–`08`).

1. **Laundry Room Dryer** → **Start repair**.
2. `What's going on?` Helper: `Describe what you notice — not what you think is broken`. Chip `No heat` → `Confirm and continue`. `Starting from: No heat`.
3. If asked heat cycle → `Yes, heat cycle`. Drum: `Does the drum turn during the cycle?` → `Turns normally`. Warmth if asked → `No warmth`.
4. Inspect cards (interview): `Look at the lint filter` → `Matches / OK`. `Check the outside vent hood` → `Matches / OK`. `Look at the visible vent hose` → `Matches / OK`.
5. `Skip to best guess` if more questions. `Most likely` → `Continue` → `I'll repair`.
6. **Parts & cost** if shown → `Continue`. Close-path **Inspect** only if those three templates were not recorded.
7. **Tools** if shown: mark `I have this` on required rows (fuse beginner may skip or list optional **Screwdriver** / **Flashlight**).
8. **Safe Guidance** `Step 1 of N`. Title `Check the lint filter`. Body starts `Check airflow before opening the cabinet. Pull the lint filter`. Do **not** see `Open the heater service panel` on step 1. `I did this`.
9. **Exit** → **Continue repair** (§F). Then finish, `Confirmed`, **Fixed**, **Save & go home**.
10. Dryer **Repair history**: new top row `YYYY-MM-DD · Fixed`. Sample older **Fixed** rows stay below.

Pass: lint → hood → hose before any panel; resume mid-guidance; one new **Fixed** row.

---

## B. Washer — Won't drain

Full paths: [`WASHER_PATHS.md`](WASHER_PATHS.md). Machine-readable cases: [`scenarios/washer_wont_drain.md`](scenarios/washer_wont_drain.md) (`WASHER-WD-01`–`06`).

1. **Laundry Room Washer** → **Start repair**. `What is the washer doing?` (never dryer `What's going on?`) → `Won't drain`.
2. Inspect: `Check that the door latches` → `Matches / OK`. `Look at the drain filter or coin trap` → `Matches / OK` or `Doesn't match / Not OK` if you want packed-trap evidence.
3. `Skip to best guess` if needed. Leader often `Clogged drain filter or pump trap`. `Continue` → `I'll repair`.
4. Cleaning path: no drain-trap **purchase** row. **Tools**: `Shallow pan and towel` `Required` → `I have this`. `Flashlight` `Optional`. `I don't` on the pan must not unlock opening the filter. Line: `You need a shallow pan and towel for the next steps.`
5. Close-path inspect skipped if interview already recorded door/filter.
6. **Safe Guidance** step 1: `Check that the washer door closes firmly until you feel or hear a click. Do not bypass the door switch.` Do **not** see `Unplug the washer` or `Open only the user-accessible filter` on step 1.
7. `I did this` → **Exit** → **Continue repair**. Finish, `Confirmed`, **Fixed**.
8. Washer **Repair history** new top row. Dryer history unchanged.

Pass: door → filter look before opening the trap; pan required; resume; one **Fixed** row.

---

## C. Dishwasher — Standing water

Not in Sample home. Other starters: [`DW_PATHS.md`](DW_PATHS.md).

1. Home **Add Dishwasher** → **Save appliance**. Open it → **Start repair**.
2. `What is the dishwasher doing?` → `Standing water`.
3. Inspect if shown: `Look at the tub filter and sump` → then `Check that the door latches` → `Look at the drain hose, high-loop, or air gap`. Filter `Matches / OK` stores **No** (mesh clear) — polarity, not a bug.
4. `Most likely` `Clogged tub filter` → `I'll repair`.
5. **Tools** may be skipped (`None for beginner external checks`).
6. Guidance step 1 starts `Look at the accessible tub filter under the lower rack. Do not open a sealed pump.` Do **not** see `Remove and rinse only the user-accessible filter` on step 1.
7. `I did this` → **Exit** → **Continue repair**. Finish, **Fixed**. History: **Tub filter path** / standing-water, `YYYY-MM-DD · Fixed`.

Pass: filter → door → hose inspect when shown; rinse after the look; no dryer lint assets.

---

## D. House Book export

Not Settings **Export household data** (JSON backup).

1. Home, **Appliances** section → **Export inventory**. Helper: `Readable list for insurance or a move. Built on this device — not uploaded.`
2. Share sheet (or clipboard). Snackbar: `Inventory ready to share on this device.`
3. Shared text: household **Sample home**, date, `On this device. Not uploaded.` Dryer **WED5000DW** / **DRY-SERIAL-1**. Washer **WTW5000DW** / **WASH-SERIAL-1**. Dryer has a **Last repair** line from sample history.

Pass: two appliances with model and serial. No login. Details: [`EXPORT_INVENTORY.md`](EXPORT_INVENTORY.md).

---

## E. Tools persist

1. Home wrench (**Tools** tooltip) or Settings **Tools** (`What you own at home`).
2. Empty: `No tools listed yet. Add them below, or tap “Also save to my tools” during a repair.`
3. **Add a tool** → chip `Screwdriver`. **Owned** lists Screwdriver. **Remove** (close) deletes it.
4. Kill the app. Reopen. **Tools** still lists Screwdriver.
5. On a dryer **Tools** checklist (if the leader shows one): owned screwdriver shows `In your tools`. `I have this` alone does **not** add to inventory; `Also save to my tools` does.

Pass: list survives kill; empty list does not crash. Details: [`TOOLS_INVENTORY.md`](TOOLS_INVENTORY.md).

---

## F. Resume (**Continue repair**)

After §A or §B mid-guidance:

1. Session **Exit**. Detail (and maybe home) **Continue repair**.
2. Land on the **first incomplete** **Safe Guidance** step. Do **not** re-ask `What's going on?` / `What is the washer doing?`. Completed `I did this` stays done.

| If you left at | After Continue repair |
|---|---|
| Mid-guidance | Same first incomplete step |
| Tools done, no `I did this` yet | First **Safe Guidance** step (not the tools list) |
| **Most likely**, before `I'll repair` | **Most likely** (or I'll repair / Call a pro if Continue was already tapped) |
| Settings **Clear open session** | No **Continue repair**. **Start repair** is empty. No history row for the abandon. |

Details: [`RESUME_CASES.md`](RESUME_CASES.md).

---

## G. Offline

Copy: `Offline — guides on this device still work`. App bar: `Offline`. Session banner key `session-offline-banner` **above** questions, not instead of them.

**Phone:** start a dryer chip, turn on OS **Airplane mode**, foreground the app. Home shows **Offline**. **Continue repair** / chips / guidance still work. Settings **Guides** → **Check for updates**: `You’re offline. Guides already on this device still work.` **Install from this device** still works. Helper: `Installing uses the copy stored on this device. It does not need the internet.`

**Chrome:** Settings → **Demo** → **Simulate offline** (`Show the Offline banner. Guides and install from this device still work.`). Same banners. Turn the switch off when done.

Pass: no blank repair, no stack trace, no cloud LLM. Details: [`OFFLINE_SMOKE.md`](OFFLINE_SMOKE.md).

---

## Kit pass / fail

**Pass if** all of: sample reset never crashes (including double-tap with no sample); §A–C reach **Fixed** history; export shows both serials; tools survive kill; **Continue repair** does not restart the starter; offline still shows chips.

**Fail if:** crash on **Reset sample data**; camera required; **I don't** on a required tool opens a panel/filter; resume re-asks the starter; invasive step on guidance step 1; labels that disagree with [`GOLDEN_LABELS.md`](GOLDEN_LABELS.md) on the frozen dryer/washer chrome.
