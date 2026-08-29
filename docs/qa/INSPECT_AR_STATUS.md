# Inspect / camera status (not AR)

**Parked 2026-08-20:** generated diagrams, Show me where, and AR-style overlays are off (`locationVisualAidsEnabled` in `lib/helpers/location_visual_aids.dart`). Inspect is text LOOK FOR + chips. Flip that flag only when a real curated (non-generated) raster exists.

Read from code on **2026-08-20**. There is **no AR**, object detection, CoreML, or YOLO. Inspect is a look-along: the user confirms what they see with chips. The camera never diagnoses.

Related flow notes: [`INSPECT_STEPS.md`](INSPECT_STEPS.md). Dryer tap path: [`INSPECT_TEXT_PATH.md`](INSPECT_TEXT_PATH.md). Tests: `test/inspect_step_test.dart`. Copy: `UserFacingCopy` in `lib/helpers/user_facing_error.dart`.

## How inspect steps work

Inspect is `ClosePathPhase.inspect` (`lib/helpers/close_path_phase.dart`): after parts (if any), before tools. Interview also mounts the same card when the active easy-check maps to an inspect step.

Session wiring (`lib/ui/session_screen.dart`):

1. After parts (or after I'll repair if there are no parts), the session goes to inspect if `_hasIncompleteInspect` is true; otherwise tools, then guidance. Tools-ready advances to guidance (or verification if there are no guidance steps) only when inspect is already complete.
2. Completeness is **template recorded**, not “camera found the part.” `firstIncompleteInspectStep` (`lib/helpers/inspect_steps.dart`) walks the chain and skips a step when `evidenceTemplateId` already has structured evidence (interview, **Skip to best guess** with prior answers, or a previous inspect chip).
3. The card shows the first incomplete step, plus `Inspect N of M` from `inspectProgress` / `inspectProgressLabel`.
4. A chip calls `_submitInspectChip`: map chip → `evidenceAnswerByChip` → record that template. If nothing in the chain is still incomplete, the session moves to tools (if any), then guidance.
5. `closePathPhaseHonoringInspect` keeps the phase on inspect if the user would skip into guidance with an unrecorded inspect template. The blocking line is `blockingReasonInspectIncompleteLine`: **Finish this look before opening a panel or pulling the appliance out.** (`lib/helpers/blocking_reason.dart`).
6. Resume: `resumeClosePathPhase` stays on inspect while incomplete; after inspect is complete it lands on guidance.

**Lookup** (`inspectStepsForClosePath`):

- If the close-path row has a non-empty `inspectSteps` list, that list wins.
- Otherwise filter `package.inspectSteps` by `failureModeIds` **in package list order**.
- Built-in close-path maps for dryer / washer / dishwasher leave `inspectSteps` empty (`FailureModeClosePath` default), so the package list is what runs. `builtInInspectStepsFor` only reads those empty close-path lists (used on factory import).

Chips (`inspectStepChipLabels`): **Matches / OK**, **Doesn't match / Not OK**, **Can't see**, and **Already checked** when the template is an easy-check observation (or the step maps that answer). **Can't see** and **Already checked** still write a template answer and advance.

UI card (`lib/ui/inspect_step_card.dart`): safety (if needed), **LOOK FOR**, short OK / Not OK, optional flashlight camera, then chips. No generated diagram. Pictures only if `locationVisualAidsEnabled` and `inspectHasCuratedImage` (none today).

## Camera never diagnoses

`InspectCameraMode` is `none` or `viewOnly` (`lib/models/inspect_step.dart`). Authored steps use `viewOnly`. Comment on the model: live CV is out of scope. `InspectFrameHint` is a **diagram-only** rectangle (0–1 fractions). Comment: never live tracking or diagnosis.

On the inspect card:

- Caption is omitted while location pictures are parked.
- Optional camera is a flashlight. LOOK FOR stays on screen. Live preview does **not** draw `inspect-frame-hint` and does **not** use `visual-guide-target-box`.
- Dryer CustomPaint / SVG schematics are **not** shown.
- Denied camera, Settings simulate deny (`cameraStartDenied`), no cameras, or web (`inspectCameraOnPhone`): stay on text; chips still complete the step.

Chips are required to advance. Preview does not write evidence.

## How to author a step

Do not add a ranking template. Do not add detection. Map chips to **existing** template answers.

1. Add a `const InspectStep` in `lib/knowledge_factory/<appliance>_inspect_steps.dart`.
2. Set `id`, `title`, `safetyPreamble`, `lookFor`, `okMeans`, `notOkMeans`, `diagramAsset`, `cameraMode`, `appliesTo`, `evidenceTemplateId`, `evidenceAnswerByChip`, `failureModeIds`. Optional: `relatedEasyCheckTemplateId`, `frameHint`. Keep `beginnerSafe: true` and `noLiveElectrical: true`.
3. `lookFor` should name one physical check (part, where, what to do with eyes/hands).
4. Chip → answer must exist on that template. Polarity follows the template: **Matches / OK** is “looks like the OK description,” which may store `No` when the template is a problem-present question (example: dishwasher filter debris).
5. Append to the package `inspectSteps` list in look order. Attach `failureModeIds` for every mode that should show the step. Do not put a duplicate chain on the close-path row if the package already covers the mode (empty close-path list prefers the package).
6. **One `evidenceTemplateId` per step in a chain.** Completeness keys off “template already recorded.” Two steps sharing a template skip each other.
7. Wire the list on the package (`inspectSteps:` on washer/dishwasher MVP packages; dryer in `KnowledgePackageRepository`). Add coverage in `test/inspect_step_test.dart`.
8. Register a painter mapping in `inspectDiagramAnchor` if the step needs a known `VisualGuideAnchor`; otherwise a generic typical-diagram-only anchor is used.

`InspectCameraMode.none` exists; the card only shows Diagram/Camera tabs when mode is `viewOnly` and `diagramAsset` is non-empty.

## What’s done

Packages: **dryer-core 1.4.1**, **washer-core 0.2.3**, **dishwasher-core 0.2.3**, **fridge-core 1.0.1**.

All authored inspect steps are `viewOnly`, `beginnerSafe`, `noLiveElectrical`, with a `frameHint`.

### Dryer (`lib/knowledge_factory/dryer_inspect_steps.dart`)

Package order: lint filter → outside vent hood → visible hose.

Same three steps on `dryerEasyAirflowInspectModeIds`: `restricted-exhaust-airflow`, `clogged-lint-pathway`, `thermal-fuse-open`, `heating-element-failed`, `high-limit-thermostat-open`, `thermistor-fault-electronic`, `cycling-thermostat-failed`, `cycling-thermostat-stuck-open`, `cycling-thermostat-stuck-closed`, `relay-or-control-no-heat-output`, `timer-advanced-no-heat-portion`, `motor-overheat-protector-open`.

| Step id | Template | Matches / OK | Doesn't match |
|---|---|---|---|
| `inspect-lint-filter` | `lint-filter-condition` | Clean | Heavily clogged |
| `inspect-vent-hood` | `exterior-airflow` | Normal | Weak |
| `inspect-vent-hose` | `vent-hose-condition` | Looks clear | Yes, restricted |

Can't see → `Not sure`. Already checked → `Already checked`.

### Washer (`lib/knowledge_factory/washer_inspect_steps.dart`)

Package order: door latch → drain filter / coin trap → standpipe seating → hose run → taps/inlet → screens → tap drip → power/lock.

| Failure mode | Chain (package order) |
|---|---|
| `clogged-washer-drain-filter` | door, filter |
| `kinked-or-clogged-washer-drain-hose` | door, filter, hose run |
| `washer-drain-hose-not-seated` | standpipe, hose run |
| `washer-door-not-latched` | door only |
| `closed-taps-or-kinked-inlet` | taps/inlet |
| `clogged-washer-inlet-screens` | taps/inlet, screens |
| `loose-inlet-hose` | tap drip |
| `washer-no-power-or-control-lock` | power/lock |
| `unbalanced-washer-load` | (none — interview) |

| Step id | Template | Matches / OK | Doesn't match |
|---|---|---|---|
| `inspect-washer-door-click` | `washer-door-click` | Yes | No |
| `inspect-washer-drain-filter` | `washer-drain-filter-access` | No | Yes |
| `inspect-washer-standpipe` | `washer-standpipe-hose` | No | Yes |
| `inspect-washer-drain-hose-config` | `washer-drain-hose-look` | No | Yes |
| `inspect-washer-taps-inlet` | `washer-taps-open` | Yes | No |
| `inspect-washer-inlet-screens` | `washer-inlet-screens-look` | No | Yes |
| `inspect-washer-leak-tap` | `washer-leak-at-tap` | Not leaking | Yes |
| `inspect-washer-power-lock` | `washer-power-or-lock` | Yes — looks powered | No — unplugged, off, or locked |

Drain-filter inspect **Matches / OK** stores **No** (trap looks clear); **Doesn't match** stores **Yes** (packed). Standpipe / hose-look **Matches / OK** stores **No** (hose is seated / not stuffed). Can't see → `Not sure`.

### Dishwasher (`lib/knowledge_factory/dishwasher_inspect_steps.dart`)

Package order: tub filter/sump → door latch → drain hose / high-loop / air-gap / leftover disposal knockout → supply/air-gap → spray-arm holes → door-seal / visible sink hose.

| Failure mode | Chain |
|---|---|
| `clogged-dishwasher-filter` | filter, door, hose |
| `kinked-or-clogged-dishwasher-drain` | filter, door, hose |
| `dishwasher-door-not-latched` | door only |
| `closed-dishwasher-supply-or-air-gap` | supply |
| `clogged-dishwasher-spray-arms` | filter, spray |
| `dishwasher-door-seal-or-loose-connection` | leak (gasket / visible hose) |

| Step id | Template | Matches / OK | Doesn't match |
|---|---|---|---|
| `inspect-dishwasher-filter` | `dishwasher-filter-debris` | No | Yes |
| `inspect-dishwasher-door-click` | `dishwasher-door-click` | Yes | No |
| `inspect-dishwasher-drain-hose` | `dishwasher-drain-hose` | No | Yes |
| `inspect-dishwasher-supply` | `dishwasher-supply-open` | Yes | No |
| `inspect-dishwasher-spray` | `dishwasher-spray-holes` | No | Yes |
| `inspect-dishwasher-leak` | `dishwasher-door-seal-leak` | Not leaking | Door seal |

Can't see → `Not sure`. High-loop is copy on the hose step, not a second inspect row (same template would collapse the chain). Manual paths: [`DW_PATHS.md`](DW_PATHS.md).

### Fridge (`lib/knowledge_factory/fridge_inspect_steps.dart`)

Package order: temperature controls → door gasket → internal vents → accessible coils/grille.

| Failure mode | Chain |
|---|---|
| `blocked-fridge-coils-or-airflow` | temps, gasket, vents, coils |
| `blocked-fridge-internal-vents` | gasket, vents |
| `fridge-door-gasket-or-ajar` | gasket |
| `fridge-temp-controls-set-wrong` | temps, gasket |

Leak / ice / noisy / no-power modes have no inspect chain.

| Step id | Template | Matches / OK | Doesn't match |
|---|---|---|---|
| `inspect-fridge-temps` | `fridge-temps-or-settings` | Yes — mid-range | No — at an extreme |
| `inspect-fridge-door-seal` | `fridge-door-seal` | Yes | No |
| `inspect-fridge-vents` | `fridge-internal-vents` | No | Yes |
| `inspect-fridge-coils` | `fridge-coils-or-space` | No | Yes |

Can't see → `Not sure`.

## Not in this code

- No AR overlay that tracks a part, no “found it” box on live inspect preview, no CV on terminals.
- No HVAC / AC package inspect.
- Close-path `inspectSteps` lists are unused for the built-in dryer/washer/DW/fridge maps (package `failureModeIds` is the source of truth).
- Show me where catalog anchors are `typicalDiagramOnly` (no `visual-guide-target-box`).
