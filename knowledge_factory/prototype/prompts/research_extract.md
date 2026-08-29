# Research extract prompt (authoring session only)

Use this in a **Knowledge Factory authoring** chat or notes file. Do **not** paste this into the household app. Do **not** call the public web from Flutter (`lib/`). There is no runtime research step.

## Experiment

Dryer **no-heat** (`symptomId: no-heat`, package hint `dryer-core`). Goal: better **discriminators**, not more failure modes.

## Thermal-fuse lesson

An open thermal fuse is often the *immediate* break in the heater circuit. Restricted lint/vent is often the *reason* it opened. Do not extract “replace the fuse” or “replace the element” as the first move when airflow has not been observed.

## Extract into

1. Fill a row in `intake/sources_template.csv` (citation; human retrieved the page/book **offline**).
2. Copy `candidates/schema_candidate_case.json` and replace placeholders.
3. Fill `provenance/schema_provenance.json` for each non-obvious claim.
4. Score with `metrics/metrics_template.csv`.

## What to pull (structured)

- Observations the user can **see / hear / feel** (not “is the fuse bad?”).
- Answers that **support** one competing mode and **exclude** another.
- Common misdiagnoses (especially part-swap-first).
- Text inspect LOOK FOR alignment with lint → hood → hose.
- Prevention **when vent-related** (filter every load, hood, visible hose). Never invent prevention for a non-vent path.
- Safety stops: no gas DIY, no sealed-system/refrigerant DIY, no beginner live-electrical procedures.

## What to refuse

- Live voltage / jumper / bypass-fuse how-to.
- Runtime URLs, “search the web when the user is stuck,” or auto-merge into `lib/knowledge_factory`.
- Treating search popularity as correctness.

## After extract

A human still approves. Mechanical gates: `docs/knowledge/PACKAGE_RELEASE_CHECKLIST.md`. Scenarios: `docs/qa/scenarios/dryer_no_heat.md`.
