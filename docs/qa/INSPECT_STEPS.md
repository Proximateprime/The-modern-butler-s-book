# InspectStep flow (phases A–E)

Status snapshot (no AR/CV, what shipped per appliance): [`INSPECT_AR_STATUS.md`](INSPECT_AR_STATUS.md). Dryer tap path: [`INSPECT_TEXT_PATH.md`](INSPECT_TEXT_PATH.md). How to add a step: [`INSPECT_STEP_AUTHORING.md`](INSPECT_STEP_AUTHORING.md).

Inspect appears in the **live repair session**: interview easy-checks that map to an `InspectStep` use the LOOK FOR card, and the close-path phase runs **after parts (if any) and before tools** when those templates are still unrecorded. It is a look-along: the user confirms what they see with chips. **The camera never diagnoses.** There is no object detection, no “found the part” box on live preview, and no CV on AC terminals.

Chips write **existing evidence templates** (same answers ranking already uses). **Can't see** and **Already checked** still record a template answer and advance — that is the skip policy. Required inspect is otherwise blocking: the session will not skip into invasive guidance while an inspect template is unrecorded.

## Phases

| Phase | What shipped |
|---|---|
| **A** | `InspectStep` model, package lookup, chips → templates |
| **B** | Close-path inspect phase between parts and tools (before guidance) |
| **C1** | Dryer no-heat / long-dry / overheat: lint filter → outside hood → visible hose |
| **C2** | Washer won’t-drain: door latch → coin trap; washer door-not-latched: latch look only; dishwasher drain: tub filter → door → high-loop / hose / knockout; dishwasher fill / poor clean / leak inspect; dishwasher door-not-latched: latch look only |
| **C4** | Fridge cooling/door/setpoint: temps → gasket → vents; dirty-coils adds grille/coils look before pull-out |
| **C3** | Prior workmanship inspect (washer standpipe / stuffed hose) |
| **D** | Optional **Diagram \| Camera** tabs; camera is `view_only`, instruction-preserving |
| **E** | Diagram-only `frame_hint`, **Inspect N of M**, inspect incomplete blocking line, specific `look_for` copy, this doc |

Out of scope: YOLO/CoreML, live tracking as truth, new appliances, HVAC/AC packages.

## Session flow

1. Conclusion → I’ll repair → parts (if any) → inspect (if templates incomplete) → tools.
2. If the close path has inspect steps whose templates are **not** already recorded (for example after **Skip to best guess**), show **Inspect**.
3. If interview already recorded those templates, close-path inspect is skipped.
4. Each card: safety preamble, **LOOK FOR**, OK / not OK, no AI pictures, optional flashlight camera, chips.
5. Progress label on the close path uses the **real chain length** for that failure mode (dryer airflow is 3; washer drain is 2; dishwasher drain is 3; washer/dishwasher door-not-latched is 1; dishwasher poor-clean is 2; fridge dirty-coils is 4).
6. Last required chip with no remaining incomplete inspect → tools (if any) then Safe Guidance (still gated by easy checks / tools).

## Camera never diagnoses

- Caption: **Camera does not diagnose. Confirm what you see with the buttons.**
- Live preview may repeat safety + look-for copy. It must **not** draw `visual-guide-target-box` or `frame_hint`.
- `frame_hint` is a semi-transparent rectangle on **diagram assets only**, labeled **Typical area — confirm on yours.** It is not live tracking.
- Denied / simulated deny / no camera: diagram + chips still complete the repair.

## Authoring a new InspectStep (next package)

Checklist (how to add a step, camera never diagnoses, dryer lint-filter example): [`INSPECT_STEP_AUTHORING.md`](INSPECT_STEP_AUTHORING.md).

## Regression notes (order)

**Dryer (filter → hood → hose)**  
No-heat / long-dry / overheat after tools, if airflow templates are unrecorded: **Inspect 1 of 3** lint mesh → **2 of 3** outside vent flap (stand aside) → **3 of 3** flexible hose at the rear collar. Then Safe Guidance. Do not open a heater panel first. Manual: [`REGRESSION_PHONE.md`](REGRESSION_PHONE.md) §A.

**Washer (door → filter)**  
Won’t-drain: **Inspect 1 of 2** latch click → **2 of 2** coin-trap / drain-filter look from outside. Then Safe Guidance. Do not open the filter first. Door-not-latched: **Inspect 1 of 1** latch click (interview may already have recorded it). Fill / leak / start inspect: [`WASHER_PATHS.md`](WASHER_PATHS.md). Manual drain: [`REGRESSION_PHONE.md`](REGRESSION_PHONE.md) §B.

**Dishwasher (filter → door → high-loop)**  
Won’t-drain / standing-water drain: **Inspect 1 of 3** tub filter/sump under the lower rack → **2 of 3** door latch → **3 of 3** high-loop / hose / air-gap / leftover disposal knockout (look only). Then Safe Guidance. Door-not-latched: **Inspect 1 of 1** latch click. Manual: [`REGRESSION_PHONE.md`](REGRESSION_PHONE.md) §C.

**Fridge (temps → gasket → vents → coils)**  
Not-cooling / dirty-coils: **Inspect 1 of 4** setpoints → **2 of 4** gasket → **3 of 4** internal vents → **4 of 4** toe-kick/coils look from outside. Then Safe Guidance. Do not pull the cabinet first. Gasket-only and vents paths are shorter.

Tests: `test/inspect_step_test.dart`, `test/blocking_reason_test.dart`. Frozen chrome: [`GOLDEN_LABELS.md`](GOLDEN_LABELS.md).
