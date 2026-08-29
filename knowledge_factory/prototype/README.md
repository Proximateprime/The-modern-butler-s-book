# Knowledge Factory prototype (authoring only)

**This tree is not part of the Flutter app.** Do not import it from `lib/`. Do not add it to `pubspec.yaml` assets. Do not fetch URLs from session, interview, inspect, or package-install code.

Production dryer/washer/DW packages stay in `lib/knowledge_factory/` and `lib/services/knowledge_package_repository.dart`. Those are compiled-in seeds. This folder is an **authoring-time experiment**.

## What this is for

A dryer **no-heat** research sandbox:

- Capture sources (citations only — humans retrieve them offline).
- Draft **candidates** that might later become authoring records.
- Record **provenance** (who claimed what, from which source).
- Run a **research extract** prompt in an authoring session (Cursor / notes), not in the household app.
- Score candidates with **metrics** that prefer discriminators over mode count.

Thermal-fuse lesson (keep in every extract): do **not** jump to a part swap without observations that split competing modes (vent/lint vs element vs fuse vs air-only vs supply).

## Human approval

`status` on a candidate stays `draft` or `needs_review` until a person signs the [package release checklist](../docs/knowledge/PACKAGE_RELEASE_CHECKLIST.md).

**Do not auto-merge** files from `candidates/` into production batches (`dryer_batch_01`, `dryer_batch_02`, golden JSON, or the in-memory repository). Merge is a manual edit after review.

## Layout

| Path | Role |
|---|---|
| [`intake/sources_template.csv`](intake/sources_template.csv) | Source log for one authoring pass |
| [`candidates/schema_candidate_case.json`](candidates/schema_candidate_case.json) | One candidate case (schema + placeholders) |
| [`provenance/schema_provenance.json`](provenance/schema_provenance.json) | Claim → source → reviewer |
| [`prompts/research_extract.md`](prompts/research_extract.md) | Authoring extract prompt (not a runtime system prompt) |
| [`metrics/metrics_template.csv`](metrics/metrics_template.csv) | Discriminator / safety / inspect scorecard |

## Hard rules

- No runtime web research.
- No LLM as diagnostic authority in the app.
- No gas DIY, no sealed-system / refrigerant DIY, no beginner live-electrical procedures.
- Camera never diagnoses.
- Popularity ≠ correctness.

First experiment target: **dryer no-heat** (`dryer-core`), aligned with [`docs/qa/scenarios/dryer_no_heat.md`](../docs/qa/scenarios/dryer_no_heat.md) and [`docs/qa/DRYER_DISCRIMINATORS.md`](../docs/qa/DRYER_DISCRIMINATORS.md).
