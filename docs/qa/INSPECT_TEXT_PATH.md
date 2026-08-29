# Inspect — live text path (dryer tap script)

Inspect is part of the **repair session**, not Settings. Easy-check templates that have an authored `InspectStep` render `InspectStepCard` during interview. If those templates are still unrecorded after **I'll repair**, the close path shows inspect **after Parts (if any) and before Tools**.

No AI-generated part pictures. No AR. Optional **Use camera while I look** is flashlight + the same LOOK FOR text; the camera never diagnoses.

Read from code on **2026-08-20**. Frozen chrome: [`GOLDEN_LABELS.md`](GOLDEN_LABELS.md). Tests: `test/inspect_step_test.dart`.

---

## What each inspect card must show

On `InspectStepCard` (`lib/ui/inspect_step_card.dart`):

| Element | Live copy / behavior |
|---|---|
| Progress | Close path only: `Inspect N of M`. Interview uses heading **Current question** (or **Optional follow-up question**) instead. |
| Title | Step title (dryer: lint filter → outside hood → visible hose). |
| Safety | `safetyPreamble` on the card (`inspect-safety-preamble`). |
| LOOK FOR | Heading **LOOK FOR**, then `lookFor`. |
| OK / Not OK | Headings **OK looks like** and **Not OK looks like**, then `okMeans` / `notOkMeans`. |
| Chips → evidence | **Matches / OK** · **Doesn't match / Not OK** · **Can't see** · **Already checked**. Each writes `evidenceTemplateId` via `evidenceAnswerByChip`. |
| Pictures | None while `locationVisualAidsEnabled` is false. |
| Camera | Optional **Use camera while I look**. Overlay repeats LOOK FOR. Caption **Camera does not diagnose. Confirm what you see with the buttons.** Hide with **Hide camera**. Denied camera: stay on text; chips still work. |

**Can't see** and **Already checked** still record the template and advance. They count as a valid skip for the inspect / easy-check gate.

Invasive guidance (panel / replace-part language) stays gated until required inspect and easy-check templates are recorded (`blockingReasonInspectIncompleteLine`: **Finish this look before opening a panel or pulling the appliance out.**).

---

## Dryer minimum (no-heat, drum turns)

Package `dryer-core` **1.4.1**. Chain `dryerPackageInspectSteps` on the 12 heat/vent modes in `dryerEasyAirflowInspectModeIds` (`lib/knowledge_factory/dryer_inspect_steps.dart`).

| Order | Step id | Title | Template | Matches / OK stores | Doesn't match stores |
|---|---|---|---|---|---|
| 1 | `inspect-lint-filter` | Look at the lint filter | `lint-filter-condition` | Clean | Heavily clogged |
| 2 | `inspect-vent-hood` | Check the outside vent hood | `exterior-airflow` | Normal | Weak |
| 3 | `inspect-vent-hose` | Look at the visible vent hose | `vent-hose-condition` | Looks clear | Yes, restricted |

Can't see → `Not sure`. Already checked → `Already checked`.

Safety you must see:

1. Lint: unplug before reaching into the filter slot; do not open the cabinet or probe wiring.
2. Hood: stand to the **side** of the hood — not in the airstream; keep hands and face clear of the flap.
3. Hose: **unplug before pulling the dryer out** or reaching behind it; do not run it while you are behind it.

---

## Tap path A — inspect in interview (preferred)

Use a **new** dryer session (not **Continue repair**). Sample home: **Laundry Room Dryer** (Whirlpool **WED5000DW**). Demo reset: [`DEMO_RESET.md`](DEMO_RESET.md).

1. Home → **Laundry Room Dryer** → **Start repair**.
2. **What's going on?** → **No heat** → **Confirm and continue**. You should see **Starting from: No heat**.
3. If asked *Is the dryer set to a heat cycle rather than air-only / fluff?* → **Yes, heat cycle**.
4. *Does the drum turn during the cycle?* → **Turns normally**.
5. If asked *Is there any warmth after the dryer has run briefly?* → **No warmth**.
6. **Current question** becomes inspect (not a Settings page). Card **Look at the lint filter**. Confirm safety, **LOOK FOR**, **OK looks like**, **Not OK looks like**. No generated picture, no AR pin.
   - Packed mesh: **Doesn't match / Not OK** (stores Heavily clogged).
   - Clear mesh: **Matches / OK** (stores Clean).
   - Skip: **Can't see** or **Already checked**.
7. Next card: **Check the outside vent hood**. Stand-clear safety must be on screen. Chip **Matches / OK** (Normal) or **Doesn't match / Not OK** (Weak), or skip.
8. Next card: **Look at the visible vent hose**. Unplug-before-moving safety must be on screen. Chip **Matches / OK** (Looks clear) or **Doesn't match / Not OK** (Yes, restricted), or skip.
9. Optional: **Use camera while I look** on any of the three. Preview may show LOOK FOR overlay. Camera must not name a failure mode. **Hide camera** returns to text. Then chip as usual.
10. If more questions appear: **Skip to best guess** is allowed; the three templates should already be recorded.
11. **Most likely** → **Continue** → **How do you want to handle this?** → **I'll repair**.
12. **Parts & cost** if shown → **Continue**. **Inspect** close-path phase must **not** repeat those three looks (templates already recorded).
13. **Tools** if shown → complete / **Continue**.
14. **Safe Guidance** **Step 1** is still airflow / lint language — **not** **Open the heater service panel**. Invasive steps stay blocked until inspect + easy checks are recorded (they are, from steps 6–8).

Pass: lint → hood → hose appear in the live **Current question** flow; each has safety + LOOK FOR + OK/Not OK + chips; no AI images / AR; close-path inspect is skipped after those answers; guidance does not open a panel on step 1.

---

## Tap path B — inspect on the close path (skip interview looks)

Use this when interview never recorded the three templates (for example **Skip to best guess** right after drum / warmth).

1. Same start as path A through **Turns normally** (and warmth if asked).
2. **Skip to best guess** before answering lint / hood / hose inspect cards.
3. **Most likely** → **Continue** → **I'll repair**.
4. **Parts & cost** if shown → **Continue**.
5. **Inspect 1 of 3** **Look at the lint filter** — same card contents as path A. Chip to advance.
6. **Inspect 2 of 3** **Check the outside vent hood**. Chip.
7. **Inspect 3 of 3** **Look at the visible vent hose**. Chip.
8. Then **Tools** (if the path has a checklist) → **Continue** → **Safe Guidance**.

Pass: inspect is a session phase **before Tools**, not a dead page. Progress is 1 of 3 → 2 of 3 → 3 of 3. Leaving a template unanswered keeps you on inspect; you must not land on invasive panel guidance.

---

## Gating (what must not happen)

- Do not reach **Open the heater service panel** (or other invasive replace/panel copy) with lint / exterior airflow / vent hose still unrecorded, unless every remaining inspect chip was **Can't see** or **Already checked** (those **are** recorded).
- **I don't** on a **Required** tool still blocks invasive steps independently of inspect.
- Settings → tools inventory / package manager is **not** the inspect path.

---

## Washer / dishwasher (packages already support)

Not the dryer DoD, but the same card and chips. Interview swaps to `InspectStepCard` when the active observation id matches a step; otherwise the close path runs the chain if templates are incomplete.

**Washer** (`lib/knowledge_factory/washer_inspect_steps.dart`), drain / door modes:

| Title | Template |
|---|---|
| Check that the door latches | `washer-door-click` |
| Look at the drain filter or coin trap | `washer-drain-filter-access` |
| Standpipe / drain-hose look (when authored for the mode) | `washer-standpipe-hose` / `washer-drain-hose-look` |

**Dishwasher** (`lib/knowledge_factory/dishwasher_inspect_steps.dart`), drain / door modes:

| Title | Template |
|---|---|
| Look at the tub filter and sump | `dishwasher-filter-debris` |
| Check that the door latches | `dishwasher-door-click` |
| Drain hose / high-loop look | `dishwasher-drain-hose` |

Fridge inspect exists on cooling/door/coil modes; it is not a Phase 1 dryer DoD item.

Coverage note: inspect chains attach to **named mode ids**, not every mode in the package. See [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md).

---

## Related

- Authoring: [`INSPECT_STEP_AUTHORING.md`](INSPECT_STEP_AUTHORING.md)
- Status / camera: [`INSPECT_AR_STATUS.md`](INSPECT_AR_STATUS.md)
- Phone regression: [`REGRESSION_PHONE.md`](REGRESSION_PHONE.md) § A
