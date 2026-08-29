# Tester brief (one page)

**App 0.1.1+2** · Feature freeze **2026-08-17** (bugfixes only). Local-first household repair book. Ranking stays on-device. Camera never diagnoses.

Guides on device: **dryer-core 1.4.2**, **washer-core 0.2.3**, **fridge-core 1.0.1**, **dishwasher-core 0.2.3** (Settings → About / Package manager).

## Start

1. Install the release APK (`docs/qa/BUILD_NOTES.md` or Phase 2 [`BUILD_NOTES_PHASE2.md`](BUILD_NOTES_PHASE2.md)) or `flutter run` on a phone.
2. First launch: **Skip** or three short screens → **Get started**. Repair start: **I understand**. [`FIRST_RUN.md`](FIRST_RUN.md).
3. **Load sample home**. Turn **Include sample open session** **off**, then **Reset sample data**. Click path: [`DEMO_RESET.md`](DEMO_RESET.md).
4. Walk [`REGRESSION_PHASE1.md`](REGRESSION_PHASE1.md) (dryer, washer, DW, export, tools, resume, offline). Phase 2 extras: [`REGRESSION_PHASE2.md`](REGRESSION_PHASE2.md). One-pager: [`TESTER_BRIEF_PHASE2.md`](TESTER_BRIEF_PHASE2.md). Longer phone script: [`REGRESSION_PHONE.md`](REGRESSION_PHONE.md). Other washer starters: [`WASHER_PATHS.md`](WASHER_PATHS.md). Other dishwasher starters: [`DW_PATHS.md`](DW_PATHS.md).
5. Optional: camera/mic denied still finishes chips; missing-tool line ([`PERMISSIONS_DENIED.md`](PERMISSIONS_DENIED.md)). Backup round-trip ([`BACKUP_SMOKE.md`](BACKUP_SMOKE.md)). Inventory share ([`EXPORT_INVENTORY.md`](EXPORT_INVENTORY.md)). Airplane / offline guides ([`OFFLINE_SMOKE.md`](OFFLINE_SMOKE.md)).

Exact chrome: [`GOLDEN_LABELS.md`](GOLDEN_LABELS.md). Resume: [`RESUME_CASES.md`](RESUME_CASES.md).

## Pass if

- Easy checks come before panel / open-filter work.
- Inspect (when shown) is look-along: chips, **Camera does not diagnose…**, typical-area on the **diagram** only.
- **I don't** on a **Required** tool does not unlock invasive steps.
- **Exit** → **Continue repair** lands on the first incomplete **Safe Guidance** step (not the starter chips).
- **Fixed** writes one **Repair history** row (`YYYY-MM-DD · Fixed`). In-progress is not a row.
- Chip-only repair still works with camera/mic denied.

## File as bugs

Crashes, lost household data, live-electrical / gas / sealed-system how-to for beginners, labels that disagree with GOLDEN_LABELS on those two frozen paths, **Continue repair** that re-asks the starter or skips completed **I did this**.

Do **not** file items on [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md) (expected limits and authored polarity).
