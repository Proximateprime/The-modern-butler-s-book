# Phase 1 MVP — codebase inventory

Read from the repo on **2026-08-20**. Status is user-visible / wired behavior, not wish-list. No features were implemented in this pass.

| Mark | Meaning |
|---|---|
| **DONE** | Present in the main repair path (or the named household surface) with accurate code paths. |
| **PARTIAL** | Present, but coverage, polish, or leftover code is incomplete. |
| **MISSING** | Not found as a working product surface. |

Fridge is bundled (`fridge-core`) but is not a Phase 1 table row; it is noted under knowledge packages.

---

## Inventory

| Area | Status | Key files | Notes |
|---|---|---|---|
| Repair session + state flow | DONE | `lib/models/repair_session.dart`; `lib/services/repair_session_repository.dart`; `lib/services/session_coordinator.dart`; `lib/helpers/close_path_phase.dart`; `lib/ui/session_screen.dart`; `lib/ui/app_dependencies.dart` | Session records + close-path phases: conclusion → decision → parts (if any) → inspect (if incomplete) → tools → guidance → verification. `RepairSessionState` still lists a larger skeleton enum; the live UI is the close-path + interview on `SessionScreen`. |
| Questionnaire / chips / evidence | DONE | `lib/models/evidence.dart`; `lib/helpers/evidence_prompt_match.dart`; `lib/helpers/suggest_next_observation.dart`; `lib/helpers/dryer_problem_starter.dart`; `lib/ui/session_screen.dart`; `lib/services/repair_session_repository.dart` | Chip answers write structured evidence (template + answer). Optional photos/voice exist; they do not rank. Easy-check templates can swap in `InspectStepCard` when an inspect step maps to that template. |
| Knowledge packages (dryer, washer, DW) | PARTIAL | `lib/services/knowledge_package_repository.dart`; `lib/helpers/knowledge_package_catalog.dart`; `lib/helpers/dryer_close_path.dart`; `lib/knowledge_factory/dryer_batch_01.dart`; `lib/knowledge_factory/dryer_batch_02.dart`; `lib/knowledge_factory/washer_mvp_v01.dart`; `lib/knowledge_factory/dishwasher_mvp_v01.dart`; `docs/qa/PACKAGE_INVENTORY.md` | In-memory seed only (no network). **Dryer** `dryer-core` **1.4.1**: COMPLETE (8 symptoms, 40 modes). **Washer** `washer-core` **0.2.3** and **dishwasher** `dishwasher-core` **0.2.3**: PRIMARY (full primary paths, not a 40-mode family). Extra: **fridge** `fridge-core` **1.0.1** PRIMARY. |
| Ranking / hypotheses display | DONE | `lib/services/ranking_service.dart`; `lib/helpers/failure_mode_standing.dart`; `lib/models/hypothesis.dart`; `lib/models/decision_context.dart`; `lib/ui/session_screen.dart` (`hypotheses-tile`, `primary-hypothesis-banner`) | Deterministic package answer-effects / standing. Most likely / primary selection in session. Frozen algorithm (`docs/FEATURE_FREEZE.md`). LLM is not the ranker. |
| Easy-checks gating | DONE | `lib/helpers/easy_airflow_checks.dart`; `lib/helpers/washer_easy_checks.dart`; `lib/helpers/dishwasher_easy_checks.dart`; `lib/helpers/easy_check_already_checked.dart`; `lib/helpers/blocking_reason.dart`; `lib/ui/session_screen.dart` | Non-invasive checks before panel/parts on gated mode ids. Dryer airflow gate is **12 / 40** heat/vent modes, not every dryer mode. **Already checked** counts for the gate. |
| Text inspect / LOOK FOR | DONE | `lib/models/inspect_step.dart`; `lib/helpers/inspect_steps.dart`; `lib/ui/inspect_step_card.dart`; `lib/knowledge_factory/dryer_inspect_steps.dart`; `lib/knowledge_factory/washer_inspect_steps.dart`; `lib/knowledge_factory/dishwasher_inspect_steps.dart`; `lib/ui/session_screen.dart` | LOOK FOR + OK / Not OK + chips (`Matches / OK`, `Doesn't match / Not OK`, `Can't see`, `Already checked`). Interview + close path before tools when templates are unrecorded. Dryer lint→hood→hose on those 12 modes; washer/DW (and fridge) have authored chains on trust-bar modes. Optional inspect camera is flashlight + same LOOK FOR text. |
| AR / AI images | DONE (off) | `lib/helpers/location_visual_aids.dart`; `lib/helpers/inspect_steps.dart` (`inspectHasCuratedImage`); `lib/ui/session_screen.dart` (Show me where); `lib/ui/visual_guide_screen.dart`; `lib/ui/inspect_step_card.dart` | `locationVisualAidsEnabled = false`. User path does not show generated diagrams, part boxes, or Show me where. See **P1-02 dormant code** below — **not reachable with AI images in the live UI**. |
| Tools inventory + persistence | DONE | `lib/helpers/household_tools.dart`; `lib/helpers/repair_readiness.dart`; `lib/ui/tools_inventory_screen.dart`; `lib/ui/home_screen.dart` (`tools-inventory-button`); `lib/ui/session_screen.dart`; `lib/ui/app_dependencies.dart`; `lib/services/local_domain_store.dart`; `docs/qa/TOOLS_INVENTORY.md` | Household tool list persists locally (overlay generation + snapshot). Repair checklist pre-marks owned tools only; **I don't** on a required tool still blocks invasive steps. **Also save to my tools** is explicit add. Empty list is safe. |
| Appliance model/serial/label | DONE | `lib/models/appliance.dart`; `lib/ui/add_appliance_screen.dart`; `lib/ui/home_screen.dart`; `lib/ui/appliance_detail_screen.dart`; `lib/helpers/rating_plate_parse.dart`; `lib/helpers/appliance_barcode_parse.dart`; `lib/services/appliance_repository.dart`; `lib/services/local_domain_store.dart`; `lib/helpers/warranty_hint.dart`; `docs/qa/HOUSE_BOOK_APPLIANCES.md` | Name, category, manufacturer, model, serial (optional, prompted), room-label location, optional install date / age years, optional on-device rating-plate photo. Status active / retired (home lists active). OCR/barcode on-device with manual fallback. Persists across restart. |
| Repair history | DONE | `lib/helpers/repair_history_display.dart`; `lib/ui/appliance_detail_screen.dart`; `lib/ui/home_screen.dart`; `lib/ui/session_outcome_screen.dart`; `lib/ui/session_completion_screen.dart`; `lib/models/session_outcome.dart`; `lib/ui/app_dependencies.dart` (`endSession`, `repairHistoryForAppliance`); `docs/qa/REPAIR_HISTORY.md` | Fixed / not-fixed / stopped / pro outcomes write a household/appliance history row (date, symptom/path, outcome, optional note / DIY spend). Newest first. In-progress omitted. Local persist across restart. |
| Maintenance due display | DONE | `lib/models/maintenance_reminder.dart`; `lib/helpers/maintenance_reminder_copy.dart`; `lib/ui/maintenance_list.dart`; `lib/ui/home_screen.dart` (`UpcomingMaintenanceSection`); `lib/ui/appliance_detail_screen.dart`; `lib/ui/session_completion_screen.dart`; `lib/ui/app_dependencies.dart`; `docs/qa/MAINTENANCE.md` | Home shows up to 3 undone reminders. Appliance list shows last done, next due / overdue, interval. Done stamps last completed and rolls next due. Sample dryer: **Clean lint system** (30 days). **No push / no calendar sync.** Persists. |
| Resume session | DONE | `lib/models/session_ui_resume_state.dart`; `lib/helpers/close_path_phase.dart` (`resumeClosePathPhase`); `lib/ui/session_screen.dart`; `lib/ui/appliance_detail_screen.dart` (`Continue repair`); `lib/ui/stale_session_prompt.dart`; `docs/qa/RESUME_CASES.md` | Local SharedPreferences. Mid-guidance, tools-done, conclusion-before-I'll-repair documented. Settings can clear open session. |
| Offline packages | DONE | `lib/services/knowledge_package_repository.dart`; `lib/helpers/knowledge_package_catalog.dart`; `lib/helpers/device_online.dart`; `lib/ui/package_manager_screen.dart`; `lib/ui/package_install_screen.dart`; `lib/ui/guide_loading.dart`; `lib/ui/home_screen.dart`; `lib/ui/session_screen.dart`; `docs/qa/OFFLINE_SMOKE.md` | Guides are compiled-in seeds. Airplane / no-network shows **Offline — guides on this device still work**; questionnaire + guidance still run. Install is local (no internet). No cloud LLM. No `http` / runtime web research under `lib/`. |
| Cost estimates | DONE | `lib/helpers/parts_cost.dart`; `lib/ui/parts_cost_card.dart`; `lib/ui/session_screen.dart` (close-path parts); `lib/ui/session_outcome_screen.dart`; `lib/ui/session_completion_screen.dart`; `docs/qa/PARTS_COST.md` | Display-only DIY/pro stubs. Not payment, not live quotes. Rows only for the selected close-path / leader. Cleaning paths hide lint-filter / vent-kit / drain-trap purchase. Dryer fuse/vent never lists washer parts. Helper: **Estimates only. Not a quote.** |
| Export/share | DONE | `lib/helpers/local_backup.dart`; `lib/helpers/local_backup_io.dart`; `lib/ui/settings_screen.dart`; `lib/helpers/repair_log_export.dart`; `lib/helpers/repair_log_share.dart`; `lib/ui/repair_log_export_button.dart`; `lib/helpers/pro_handoff.dart`; `lib/ui/pro_handoff_screen.dart`; `lib/helpers/inventory_export.dart`; `lib/ui/home_screen.dart` (`export-inventory-button`); `docs/qa/EXPORT_INVENTORY.md` | Household JSON backup/restore (Settings). House Book **Export inventory** plain-text share (model/serial, optional last repair). Per-repair text log share. Pro handoff sheet. Chrome may use share sheet / clipboard (`docs/qa/BACKUP_SMOKE.md`). No automatic cloud publish. |
| Safety gates | DONE | `lib/helpers/safety_stop.dart`; `lib/services/safety_decision_service.dart`; `lib/helpers/investigation_stop.dart`; `lib/helpers/blocking_reason.dart`; `lib/ui/safety_disclaimer_screen.dart`; `lib/ui/session_screen.dart`; `lib/ui/first_run_screen.dart` | Hard-stop checklist (gas smell, live-electrical language, fire/smoke; professional-only mode ids). Easy-check / tools / inspect gates. First-run + disclaimer before Home. No beginner gas / sealed-system / live-electrical how-to in guidance. |
| Onboarding | DONE | `lib/main.dart`; `lib/ui/splash_screen.dart`; `lib/ui/first_run_screen.dart`; `lib/ui/safety_disclaimer_screen.dart`; `lib/ui/home_screen.dart`; `docs/qa/FIRST_RUN.md` | Splash → 3 short first-run slides (does / doesn’t / privacy), skippable, once per install → safety disclaimer → Home. Returning users skip first-run. |

---

## AR / AI images — live UI vs P1-02 leftovers

**Live path:** AR and generated location pictures are **not user-reachable**. Flag is off; inspect has no picture; Show me where is not built.

`locationVisualAidsEnabled` is `false` in `lib/helpers/location_visual_aids.dart`.

`inspectHasCuratedImage` returns false while that flag is false (`lib/helpers/inspect_steps.dart`), so `InspectStepCard` never mounts `Image.asset` / diagrams.

Show me where is wrapped in `if (locationVisualAidsEnabled && guide != null)` in `lib/ui/session_screen.dart` (Safe Guidance card, ~5417).

`VisualGuideScreen` camera overlay also requires the same flag (`lib/ui/visual_guide_screen.dart`). With the flag off it is text-only **if constructed**; the session does not push it.

`DryerInspectDiagram` (`lib/ui/dryer_inspect_diagram.dart`) is **not imported** by inspect or session. Dead widget.

SVG files `assets/inspect/dryer-front.svg` and `assets/inspect/dryer-rear.svg` may still sit on disk; they are **not** listed in `pubspec.yaml` assets, so they are not bundled pictures in the app.

Optional inspect **Use camera while I look** is a live preview flashlight with LOOK FOR overlay text only — not AR, not a generated part image, not a tracking box.

### Dormant entry points (P1-02 cleanup / do not flip casually)

These would become user-visible **only if** `locationVisualAidsEnabled` is set `true`, or if someone re-wires navigation:

1. `lib/helpers/location_visual_aids.dart` — single product flag.
2. `lib/ui/session_screen.dart` — **Show me where** `Navigator.push` → `VisualGuideScreen`.
3. `lib/ui/visual_guide_screen.dart` — location overlay shell (diagram/camera when flag on).
4. `lib/helpers/visual_guide.dart` — catalog anchors still carry `imageAsset: 'diagram:…'` metadata (not shown in inspect UI today).
5. `lib/ui/inspect_step_card.dart` — curated `Image.asset` branch if flag on **and** `inspectHasCuratedImage` (still rejects `diagram:` ids, dryer SVG paths, and `.svg`).
6. `lib/ui/dryer_inspect_diagram.dart` — unused CustomPaint schematic (would need a new import to appear).
7. `assets/inspect/dryer-front.svg`, `assets/inspect/dryer-rear.svg` — unbundled files; would need `pubspec.yaml` + a widget to show.

**P1-02 does not need to hunt a live AI-image AR flow.** Remaining work is deleting or keeping this dormant code, not disabling a shipping overlay.

---

## Related QA docs (not re-audited as product)

`docs/qa/PACKAGE_INVENTORY.md`, `docs/qa/INSPECT_TEXT_PATH.md`, `docs/qa/HOUSE_BOOK_APPLIANCES.md`, `docs/qa/TOOLS_INVENTORY.md`, `docs/qa/REPAIR_HISTORY.md`, `docs/qa/MAINTENANCE.md`, `docs/qa/EXPORT_INVENTORY.md`, `docs/qa/PARTS_COST.md`, `docs/qa/OFFLINE_SMOKE.md`, `docs/qa/FIRST_RUN.md`, `docs/qa/WASHER_PATHS.md`, `docs/qa/INSPECT_AR_STATUS.md`, `docs/qa/RESUME_CASES.md`, `docs/qa/DRYER_DISCRIMINATORS.md`, `docs/qa/SAFETY_PATH_CHECK.md`, `docs/qa/GOLDEN_LABELS.md`, `docs/qa/REGRESSION_PHASE1.md`, `docs/qa/REGRESSION_PHONE.md`, `docs/FEATURE_FREEZE.md`.
