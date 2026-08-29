# Golden labels (regression freeze)

Exact **primary** question and button labels for two paths, as of **2026-08-22**. If the running app differs, that is a regression — update this file only after an intentional copy change.

Source of truth in code: dryer inspect titles in `lib/knowledge_factory/dryer_inspect_steps.dart`; washer prompts in `lib/knowledge_factory/washer_mvp_v01.dart`; close-path steps in `lib/helpers/dryer_close_path.dart`; session chrome in `lib/ui/session_screen.dart`; House Book / Settings / Tools in `lib/helpers/user_facing_error.dart` and those screens.

Kit: [`REGRESSION_PHASE1.md`](REGRESSION_PHASE1.md). Phone walkthrough: [`REGRESSION_PHONE.md`](REGRESSION_PHONE.md). Dryer inspect taps: [`INSPECT_TEXT_PATH.md`](INSPECT_TEXT_PATH.md). Setup: [`DEMO_RESET.md`](DEMO_RESET.md) (sample open session **off**).

Ranking labels (**Most likely** cause names) can vary with answers. Freeze the **chrome** below, not a specific fuse vs element title.

---

## Phase 1 kit — critical buttons

| Surface | Exact label |
|---|---|
| Load sample | `Load sample home` |
| Reset sample | `Reset sample data` |
| Reset snackbar | `Sample data reset` |
| Include open sample | `Include sample open session` |
| Clear session | `Clear open session` · confirm `Clear session` |
| Idle clear snackbar | `No repair is in progress` |
| House Book | `Appliances` · `Export inventory` |
| Export helper | `Readable list for insurance or a move. Built on this device — not uploaded.` |
| Export snackbar | `Inventory ready to share on this device.` |
| Tools (home tooltip / Settings / screen title) | `Tools` |
| Tools empty | `No tools listed yet. Add them below, or tap “Also save to my tools” during a repair.` |
| Add catalog | section `Add a tool` · chip `Screwdriver` |
| Offline banner | `Offline — guides on this device still work` |
| Offline app bar | `Offline` |
| Simulate offline | `Simulate offline` |
| Session leave | `Exit` |
| Resume | `Continue repair` |
| New session | `Start repair` |
| Add DW | `Add Dishwasher` |

---

## Dryer — No heat + drum turns

Path: **No heat** → **Turns normally** → easy checks → **Most likely** → **I'll repair** → **Tools** (when the leader has required tools) → first **Safe Guidance** step.

### Start

| Role | Exact label |
|---|---|
| Detail CTA | `Start repair` |
| Starter title | `What's going on?` |
| Starter helper | `Describe what you notice — not what you think is broken` |
| Chip | `No heat` |
| Also shown | `Takes too long to dry` · `Won't start` · `Drum doesn't turn` · `Too hot or overheating` · `Unusual noise` · `Burning smell / smoke` · `Other` |
| Unknown energy | After **No heat**, first question is `Is this dryer gas or electric?` (sample home is electric, so this is skipped) |
| Primary button | `Confirm and continue` |
| After confirm | `Starting from: No heat` |
| Interview heading | `Current question` |
| Optional skip | `Skip to best guess` |

### Drum turns

| Role | Exact label |
|---|---|
| Question | `Does the drum turn during the cycle?` |
| Primary answer | `Turns normally` |

### Easy checks (interview inspect cards)

Lint / hood / hose use `InspectStepCard` (not the old long airflow question as the heading). Each card: title, `LOOK FOR`, `OK looks like`, `Not OK looks like`, chips `Matches / OK` · `Doesn't match / Not OK` · `Can't see` · `Already checked`. No generated picture.

| Order | Card title | Matches / OK stores | Doesn't match stores |
|---|---|---|---|
| 1 | `Look at the lint filter` | `Clean` | `Heavily clogged` |
| 2 | `Check the outside vent hood` | `Normal` | `Weak` |
| 3 | `Look at the visible vent hose` | `Looks clear` | `Yes, restricted` |

If a card is skipped, `Can't see` → `Not sure`. `Already checked` still records the template.

Answer-panel heading when a question is **not** an inspect card: `Answer this observation`.

### Conclusion → I'll repair → tools

| Role | Exact label |
|---|---|
| Section | `Most likely` |
| Cue title | `Next: review the most likely cause` |
| Primary button | `Continue` |
| Decision title | `How do you want to handle this?` |
| Cue title | `Next: I'll repair or call a pro` |
| Primary button | `I'll repair` |
| Secondary | `Call a pro` |
| Back | `Back` |
| Parts card (if shown) | `Parts & cost` |
| Parts helper | `Estimates only. Not a quote.` |
| Parts rows | Only the part this close path replaces (e.g. `Thermal fuse`). No lint-filter or vent-kit purchase lines on airflow-cleaning paths. No washer drain-trap or inlet-hose rows on a dryer fuse/vent outcome. |
| Parts continue | `Continue` |
| Tools card | `Tools` |
| Tools helper | `Required tools must be marked I have before panel steps unlock.` |
| Tools continue (if still on the card) | `Continue` |
| Tool mark | `I have this` · `I don't` |

Fuse beginner path: no required panel tools. Optional **Screwdriver** (Expert Mode panel) and **Flashlight** if the tools card appears. Unplugged heater-panel extras appear only in **Expert Mode**. Heating-element / other beginner-only leaders may skip the tools card.

### Inspect (easy-check questions, or after Parts / I'll repair, before Tools)

Shows on the matching easy-check (lint / hood / hose) and on the close path if those templates were not recorded. **Most likely** also has **Review what you checked** (read-only; does not restart the interview).

| Role | Exact label |
|---|---|
| Progress | `Inspect 1 of 3` then `Inspect 2 of 3` then `Inspect 3 of 3` |
| Order | Lint filter mesh → outside vent hood → visible vent hose |
| Diagram | None (generated / untrusted pictures parked) |
| Caption | Omitted until a real curated diagram exists |
| Camera | Optional **Use camera while I look** (flashlight). Same LOOK FOR text. No part box. |
| Blocking line | `Finish this look before opening a panel or pulling the appliance out.` |
| Chips | `Matches / OK` · `Doesn't match / Not OK` · `Can't see` · `Already checked` |

Camera does not diagnose. No part box and no generated location picture.

### First Safe Guidance step

| Role | Exact label |
|---|---|
| Card | `Safe Guidance` |
| Progress | `Step 1 of N` (N is the gated step count) |
| Title | `Check the lint filter` |
| Step body (starts with) | `Check airflow before opening the cabinet. Pull the lint filter and look at the screen.` |
| Primary | `I did this` |
| Easy-check extra | `I already did this` |
| Secondary | `I couldn't` |
| Back | `Back` |

Do **not** see `Open the heater service panel` on step 1 (beginner path never shows that panel how-to).

---

## Washer — Won't drain

Path: **Won't drain** → door click → drain-filter look → **Most likely** → first **Safe Guidance** step (easy door check). **I'll repair** / **Tools** sit between conclusion and guidance when you continue the close path; they are listed here because the phone walkthrough uses them before step 1.

### Start + easy checks

| Role | Exact label |
|---|---|
| Detail CTA | `Start repair` |
| Interview heading | `Current question` |
| Question | `What is the washer doing?` |
| Primary chip | `Won't drain` |
| Easy check 1 (inspect title) | `Check that the door latches` |
| Easy check 2 (inspect title) | `Look at the drain filter or coin trap` |
| Inspect chips | `Matches / OK` · `Doesn't match / Not OK` · `Can't see` · `Already checked` |

### Conclusion → I'll repair → tools (before guidance)

| Role | Exact label |
|---|---|
| Section | `Most likely` |
| Typical leader | `Clogged drain filter or pump trap` |
| Primary button | `Continue` |
| Decision | `How do you want to handle this?` |
| Primary button | `I'll repair` |
| Tools card | `Tools` |
| Required row | `Shallow pan and towel` + `Required` |
| Optional row | `Flashlight` + `Optional` |
| Tool mark | `I have this` · `I don't` |

### Inspect (if door / filter templates were not already recorded)

After tools, before Safe Guidance. **Door → filter.** Skip if interview already recorded those templates. Interview also uses the same cards (titles below).

| Role | Exact label |
|---|---|
| Progress (close path) | `Inspect 1 of 2` then `Inspect 2 of 2` |
| Order | `Check that the door latches` → `Look at the drain filter or coin trap` |
| Diagram | None (generated pictures parked) |
| Chips | `Matches / OK` · `Doesn't match / Not OK` · `Can't see` · `Already checked` |
| Camera | Optional `Use camera while I look`. Caption if shown: `Camera does not diagnose. Confirm what you see with the buttons.` |

### First Safe Guidance step

| Role | Exact label |
|---|---|
| Card | `Safe Guidance` |
| Progress | `Step 1 of N` |
| Title | `Safety limit for this check` |
| Step body | `Check that the washer door closes firmly until you feel or hear a click. Do not bypass the door switch.` |
| Primary | `I did this` |
| Easy-check extra | `I already did this` |
| Secondary | `I couldn't` |

Do **not** see `Unplug the washer` or `Open only the user-accessible filter` on step 1.

---

## Dishwasher — Standing water / won't drain (inspect order)

Starter: `What is the dishwasher doing?` Chip `Standing water` (or `Won't drain`). Before tools, if drain inspect templates are unrecorded: **filter → door → hose**. Progress **Inspect 1 of 3** `Look at the tub filter and sump`, **2 of 3** `Check that the door latches`, **3 of 3** `Look at the drain hose, high-loop, or air gap`. Camera never diagnoses. Kit: [`REGRESSION_PHASE1.md`](REGRESSION_PHASE1.md) §C. Authoring: [`INSPECT_STEPS.md`](INSPECT_STEPS.md).

---

## Phase 2 chrome (candidate)

Kit: [`REGRESSION_PHASE2.md`](REGRESSION_PHASE2.md).

| Surface | Exact label |
|---|---|
| Explain | `Why ask this?` |
| Standing (when shown) | `More of your answers match this than the other possibilities` (never `%`) |
| Owned tool | `In your tools` |
| Missing required tool | `Not in your tools` |
| Missing-tool panel | `Get this tool first` · `Stop` · `Call a professional` · `Exterior checks only` |
| Fixed memory | `What failed` · `Root cause not sure` · `Contributing factors` · `Prevention` · `Update maintenance schedule` |
| Pattern hint | `From your household history` · `Dismiss` |
| Pro-only warning | `A full fix likely needs a pro` (on **Most likely** and again at guidance) |
| Pro-only parts | `Pro ~ $…` only — no `DIY ~` row, no `I'll repair` |
| Paused interview | `No more questions for now — we have a most likely cause.` |
| Pro debug | `Household Pro (debug)` — debug builds only |
