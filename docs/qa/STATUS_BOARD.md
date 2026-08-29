# Repair UX status board

Read-only snapshot of code on **2026-08-18**. Marks are for the listed slice only, not a full appliance encyclopedia.

| Mark | Meaning |
|---|---|
| **YES** | Behavior is wired, covered by tests or a manual script, and matches the slice. |
| **PARTIAL** | Present but scoped, thin, or inventory docs lag the code. |
| **NO** | Missing. |

| Item | Status | Cite |
|---|---|---|
| Dryer easy-checks-first + gate invasive steps | **YES** | Interview order + close-path reorder/gate on no-heat / long-dry / overheat: `lib/helpers/easy_airflow_checks.dart` (`orderEasyAirflowGuidanceFirst`, `guidanceStepsForEasyAirflowGate`, `isInvasiveGuidanceStep` via `lib/helpers/close_path_phase.dart`). Session: `lib/ui/session_screen.dart` (`_needsEasyAirflowFirst`, `_orderedGuidanceSteps`, `_gatedGuidanceSteps`). Tests: `test/easy_airflow_checks_test.dart`. Manual: `docs/qa/REGRESSION_PHONE.md` §A. Ranking unchanged. |
| Washer easy-checks-first (door/filter) + gate | **YES** | Drain and door-not-latched only (not fill/spin/leak). Door click then look-for-filter before opening the filter: `lib/helpers/washer_easy_checks.dart`, wired in `lib/ui/session_screen.dart` and interview via `lib/helpers/suggest_next_observation.dart`. Modes/symptoms: `lib/knowledge_factory/washer_mvp_v01.dart`. Close paths: `lib/helpers/dryer_close_path.dart` (`_washerClosePaths`). Tests: `test/washer_easy_checks_test.dart`, `test/washer_mvp_test.dart`. |
| Guidance **I did this** / **I couldn't** | **YES** | Buttons on `_SafeGuidanceCard` in `lib/ui/session_screen.dart` (`guidance-did-this`, `guidance-could-not`). **I did this** records `completedGuidanceStepIds` and unlocks gated steps. **I couldn't** on an easy-airflow or washer easy-check step advances the same way; other steps open the could-not panel. Tests: `test/close_path_step_flow_test.dart`, `test/session_resume_test.dart`, dryer/washer widget paths. |
| Session resume to correct guidance step | **YES** | Restore from session + UI resume in `lib/ui/session_screen.dart` (`_restoreUiResume`, `_snapGuidanceResume`). Persist: `lib/models/repair_session.dart`, `lib/models/session_ui_resume_state.dart`, `lib/services/repair_session_repository.dart`, `lib/services/local_domain_store.dart`. Test: `test/session_resume_test.dart` (`app kill after two guidance steps resumes on step 3`). |
| Repair history write-back after Fixed | **YES** | `AppDependencies.endSession` → `repairHistoryForAppliance` in `lib/ui/app_dependencies.dart`. Detail list: `lib/ui/appliance_detail_screen.dart`, copy in `lib/helpers/repair_history_display.dart`. Tests: `test/appliance_detail_test.dart`, `test/repair_history_display_test.dart`, `test/regression_binder_v1_test.dart`. In-progress sessions are not listed. |
| Maintenance next-due / Overdue copy | **YES** | `lib/helpers/maintenance_reminder_copy.dart` (last done, next due, **About every N days**, **Overdue** suffix). UI: `lib/ui/maintenance_list.dart`. Local notify when already due; home banner if permissions denied. Tests: `test/maintenance_list_test.dart`. No calendar OAuth. |
| Tools owned pre-fills repair checklist | **YES** | Household `ownedToolIds` pre-mark **I have this** + **In your tools** on session restore and `_haveByToolId` (`decisionOwnsTool`) in `lib/ui/session_screen.dart`. **I have this** does not write inventory; **Also save to my tools** does. Tests: `test/tools_inventory_test.dart`. |
| Add-appliance scan copy (no duplicates; web vs phone) | **YES** | `lib/helpers/add_appliance_scan_copy.dart`; strings in `lib/helpers/user_facing_error.dart` (`addApplianceWebHint`, `addApplianceScanHint`, `addApplianceManualHint`). Web: one hint, no **Scan rating plate**. Phone: scan button only if OCR or barcode exists. UI: `lib/ui/add_appliance_screen.dart`. Tests: `test/add_appliance_copy_test.dart`. |
| Package versions: dryer / washer / fridge / dishwasher | **YES** | **dryer-core 1.4.2**, **washer-core 0.2.3**, **fridge-core 1.0.1**, **dishwasher-core 0.2.3**. Catalog: `lib/helpers/knowledge_package_catalog.dart`. UI: Settings About + package manager (`knowledgePackageStatusLine`). Docs: `docs/qa/PACKAGE_INVENTORY.md`, `docs/qa/VERSIONS.md`. Tests: `test/knowledge_package_manager_test.dart`, `test/about_v1_test.dart`. |
| Phone regression doc exists | **YES** | `docs/qa/REGRESSION_PHONE.md` (dryer no-heat, washer won’t-drain, dishwasher standing-water). Kit: `docs/qa/REGRESSION_PHASE1.md`. Phase 2: `docs/qa/REGRESSION_PHASE2.md`. Sample reset: `docs/qa/DEMO_RESET.md`. Candidate: `docs/qa/BUILD_NOTES_PHASE2.md`, `docs/qa/PHASE2_EXIT_CHECKLIST.md`. |
| Camera/mic deny still completes chip-only repair | **YES** | Hide photo/scan/voice after deny or **Simulate camera & microphone denied**. Session chips, typed model, diagram. Tests: `test/permissions_denied_path_test.dart`. Manual: `docs/qa/PERMISSIONS_DENIED.md`. |
| Blocking reason line (tool / easy-check / safety) | **YES** | One sentence from existing gates: `lib/helpers/blocking_reason.dart`. Session replaces the generic next-step cue (`blocking-reason-line`). Tests: `test/blocking_reason_test.dart`, `test/repair_readiness_test.dart`. |
| Inspect (C1–E + fridge): look-along, not CV | **YES** | Interview easy-checks + close path **before Tools**. Text-first LOOK FOR; no generated pictures/orange box. Camera optional. Docs: `docs/qa/INSPECT_STEPS.md`. Tests: `test/inspect_step_test.dart`. |

## Not on this board

No YOLO/CoreML, live quotes, or ranking changes. No crash found.
