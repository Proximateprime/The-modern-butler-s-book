# Continue repair resume cases

Local only (SharedPreferences). No cloud. Observation chips live on the session; UI landing lives on `SessionUiResumeState` plus `completedGuidanceStepIds`.

| Case | After **Continue repair** |
|---|---|
| **1. Mid-guidance** | Same Safe Guidance step (first incomplete). Completed **I did this** ids stay completed. Answered chips are not re-asked. |
| **2. Tools done, guidance not started** | First Safe Guidance step (not the tools list). Checklist marks stay. Chips stay. |
| **3. Conclusion, I'll repair not chosen** | **Most likely** (or **I'll repair / Call a pro** if Continue was already tapped). Not tools or guidance. Chips stay. |
| **4. Settings → Clear open session** | No **Continue repair**. **Start repair** is a new session: no old chips, no old guidance. Abandoned session is not a memory row. |

Code: `lib/helpers/close_path_phase.dart` (`resumeClosePathPhase`), `lib/ui/session_screen.dart` (`_restoreUiResume`), `lib/ui/app_dependencies.dart` (`clearOpenSessions`). Tests: `test/session_resume_test.dart`, `test/close_path_step_flow_test.dart`. State names: [`SESSION_STATES.md`](SESSION_STATES.md).
