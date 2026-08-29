# Authoring an InspectStep

How to add a look-along inspect step. Session flow and shipped coverage: [`INSPECT_STEPS.md`](INSPECT_STEPS.md), [`INSPECT_AR_STATUS.md`](INSPECT_AR_STATUS.md). Model: `lib/models/inspect_step.dart`.

Do **not** add a ranking template. Do **not** add object detection, YOLO, CoreML, or live tracking.

---

## Camera never diagnoses

Inspect is chips, not computer vision. The camera is `InspectCameraMode.viewOnly` (or `none`). Live CV is out of scope on the enum.

- Location pictures are parked (`locationVisualAidsEnabled`). Caption only if a real curated raster is shown.
- Live preview may repeat LOOK FOR. It does **not** draw `inspect-frame-hint` on the camera and does **not** use `visual-guide-target-box`.
- Denied camera, Settings simulate deny, no cameras, or Chrome: stay on text. Chips still complete the step. Preview does not write evidence.

Chips required to advance: **Matches / OK**, **Doesn't match / Not OK**, **Can't see**, and **Already checked** when the template is an easy-check observation.

---

## How to add a step

Map chips to **existing** template answers. Completeness is “that template is recorded,” not “the camera found the part.”

1. Add a `const InspectStep` in `lib/knowledge_factory/<appliance>_inspect_steps.dart`.
2. Required: `id`, `title`, `safetyPreamble`, `lookFor`, `okMeans`, `notOkMeans`, `diagramAsset`, `cameraMode`, `appliesTo`, `evidenceTemplateId`, `evidenceAnswerByChip`, `failureModeIds`.
3. Optional: `relatedEasyCheckTemplateId`, `frameHint`. Keep `beginnerSafe: true` and `noLiveElectrical: true`.
4. `lookFor` names **one** physical check (part, where, what to do with eyes/hands). Not “check the area.”
5. Chip answers must already exist on that template. **Matches / OK** means the OK description — it may store `No` when the template asks if a problem is present.
6. **Can't see** → `Not sure`. Easy-check templates also map **Already checked** (`alreadyCheckedEasyCheckAnswer`).
7. Append to the package `inspectSteps` list **in look order**. One `evidenceTemplateId` per step in a chain — two steps sharing a template skip each other.
8. Put the mode ids on `failureModeIds`. Leave close-path `inspectSteps` empty if the package list already covers those modes (empty close-path list prefers the package).
9. Wire the list: dryer `inspectSteps: dryerPackageInspectSteps` in `KnowledgePackageRepository`; washer / dishwasher / fridge on the MVP package builders.
10. If the diagram needs a known pin, map it in `inspectDiagramAnchor` (`lib/helpers/inspect_steps.dart`). Otherwise a generic typical-diagram-only anchor is used.
11. Cover the chain in `test/inspect_step_test.dart`. Do not bump package versions for inspect-only copy unless the package version constant already changed.

`diagramAsset` for dryer inspect is `assets/inspect/dryer-front.svg` or `dryer-rear.svg`. Washer/DW keep `diagram:` placeholders (text-only; no dryer lint picture).

---

## Dryer example (lint filter)

Shipped step `dryerLintFilterInspectStep` in `lib/knowledge_factory/dryer_inspect_steps.dart`. First of three on `dryerEasyAirflowInspectModeIds` (lint → hood → hose) for no-heat / long-dry / overheat modes. Template `lint-filter-condition` already exists; inspect does not add a new ranking prompt.

| Field | Value |
|---|---|
| `id` | `inspect-lint-filter` |
| `title` | Look at the lint filter |
| `appliesTo` | `dryer` |
| `diagramAsset` | `diagram:dryer-front` |
| `cameraMode` | `viewOnly` |
| `evidenceTemplateId` | `lint-filter-condition` |
| Matches / OK | `Clean` |
| Doesn't match | `Heavily clogged` |
| Can't see | `Not sure` |
| Already checked | `Already checked` |
| `frameHint` | `left: 0.36, top: 0.12, width: 0.28, height: 0.18` (diagram only) |

`lookFor` (one check): pull the rectangular mesh from the door-opening slot, hold it to a light, look through both sides for packed lint.

Safety: unplug before reaching into the slot; do not open the cabinet or probe wiring.

Package list: `dryerPackageInspectSteps` → dryer-core **1.4.1**. Hood and hose steps on the same mode list use `exterior-airflow` and `vent-hose-condition`.
