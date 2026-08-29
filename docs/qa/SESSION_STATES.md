# Session states (code as of 2026-08-20)

P1-03 spine. No new engines. Architecture names in `docs/02_ARCHITECTURE/00_SESSION_LIFECYCLE.md` are **not** the Dart enum names. This file is the implementation map.

Primary UI is structured chips on `SessionScreen` — not a free-form diagnosis chatbot. Optional “Other / describe” still writes a structured template answer.

---

## Requested lifecycle vs code

| Requested step | What actually runs | Code names |
|---|---|---|
| Select appliance | Start repair from appliance detail after add/select | `RepairSessionState.selectAppliance` (setup burst) |
| Problem reported | Dryer/washer/DW starter chips | `problemReported` then live interview |
| Basic checks | Easy-check / inspect LOOK FOR | `basicConditionVerification` (setup); gating in `easy_airflow_checks.dart` / inspect |
| Evidence / questions | Observation chips | `evidenceCollection` — **this is where the live session sits for most of the interview** |
| Hypotheses | Ranking + Most likely / primary banner | `hypothesisBuilding` on close; display while still often `evidenceCollection` |
| Risk / safety | Hazard chips + `evaluateSafetyStop` | `riskCheck` on close path; live gate anytime |
| Guidance | Safe Guidance **I did this** / **I couldn't** | `ClosePathPhase.guidance`; session state `safeGuidance` on close |
| Verification | Confirmed / Not confirmed | `ClosePathPhase.verification`; `RepairSessionState.verification` on close |
| Fixed / closed | End Session outcome | Terminal `RepairSessionState` + `SessionCloseKind` |

Appliance is chosen **before** `startOrResumeSession`. The repository still walks setup states in one burst (`app_dependencies.dart` ~835–850) so the open session is usually already `evidenceCollection`.

---

## Layer 1 — `RepairSessionState`

Enum: `lib/models/repair_session.dart`. Legal edges: `lib/services/repair_session_repository.dart` (`_normalTransitions`).

| Enum value | Plain header (`_plainStateLabel`) | Engineering label (`_stateLabel`) |
|---|---|---|
| `newSession` | Getting started | New session |
| `selectAppliance` | Choosing the appliance | Select appliance |
| `problemReported` | Describing the problem | Problem reported |
| `basicConditionVerification` | First checks | Basic condition verification |
| `evidenceCollection` | Answering questions | Evidence collection |
| `hypothesisBuilding` | Narrowing it down | Hypothesis building |
| `riskCheck` | Checking for hazards | Risk check |
| `safeGuidance` | Following safe steps | Safe guidance |
| `verification` | Checking whether it worked | Verification |
| `rootCauseAnalysis` | Looking at why it failed | Root cause analysis |
| `preventiveRecommendation` | Preventing a repeat | Preventive recommendation |
| `sessionClosed` | Finished | Session closed |
| `escalated` | Handed to a professional | Escalated |
| `abandoned` | Stopped | Abandoned |
| `error` | This step couldn’t continue | Error |

**Terminal:** `sessionClosed`, `escalated`, `abandoned`, `error`.

**History:** each `transition()` appends `SessionStateHistory` (state, enteredAt, exitedAt, reasonForTransition, triggeredBy). Evidence links store `sourceState`. Outcomes store close kind, leader, symptom, packages, note, prevention.

**Close with a memory row** always goes to `sessionClosed` then `recordOutcome` (`session_coordinator.closeSession`). `escalated` / `abandoned` are used when there is **no** household memory row (safety engine can escalate; Settings **Clear open session** / stale abandon → `abandoned`).

---

## Layer 2 — `ClosePathPhase` (stepped close path)

Enum: `lib/helpers/close_path_phase.dart`. Presentation only — not ranking.

Order after Most likely / I'll repair: `conclusion` → `decision` → `parts` (if estimates) → `inspect` (if templates incomplete) → `tools` → `guidance` → `verification` → `opportunistic` → `done`.

Resume landing: `resumeClosePathPhase` + `firstIncompleteGuidanceIndex`. Cases: `docs/qa/RESUME_CASES.md`.

Persisted on `SessionUiResumeState.closePathPhase` (`lib/models/session_ui_resume_state.dart`) inside the local domain snapshot.

---

## Layer 3 — Household close kinds (`SessionCloseKind`)

`lib/models/session_outcome.dart`. End Session UI: `lib/ui/session_outcome_screen.dart`.

| Enum | Button / history label | Maps to `SessionResolutionStatus` | P1-03 equivalent |
|---|---|---|---|
| `fixed` | Fixed — problem resolved / **Fixed** | `resolved` | Fixed |
| `notFixed` | Not fixed | `unresolved` | (still closed, not quit) |
| `stopped` | Stopped for now / **Stopped** | `unresolved` | Quit |
| `calledProfessional` | Calling a professional | `partiallyResolved` | Escalated to pro |

There is no enum value named `Quit`. Use **Stopped**.

---

## Persistence and resume

| Event | What happens |
|---|---|
| Chip / phase change | `SessionScreen._persistUiResume` → in-memory snapshot schedule |
| Leave Session (Back) | `_persistUiResume` + `flushPersist` in `dispose` |
| App background / hide | `SessionScreen.didChangeAppLifecycleState` persists UI resume then `flushPersist`; `main.dart` also `flushPersist` |
| Process killed | Next launch `AppDependencies.restore()` from SharedPreferences (`LocalDomainStore`) |
| Continue repair | Appliance detail CTA; restores evidence, primary, `ClosePathPhase`, first incomplete guidance step |

Store: `lib/services/local_domain_store.dart`. Tests: `test/session_resume_test.dart` (including **resume state survives local store restore**).

---

## How to test resume after kill-app (one dryer path)

Automated analog (no real OS kill): `flutter test test/session_resume_test.dart` — builds a session, `flushPersist`, new `AppDependencies` on the same `LocalDomainStore`, expects **Continue repair** and the same evidence/primary.

**On a phone / emulator (kill the process):**

1. Start a dryer repair (No heat). Answer drum + easy-check / inspect chips until **Most likely** (or stop mid **Safe Guidance** after **I'll repair**).
2. Do **not** End Session. Leave the app (Home), then **force-stop** the app (or swipe it away from Recents so the process dies).
3. Reopen the app → the dryer → **Continue repair**.
4. Pass: same chips already recorded; landing is the first incomplete close-path step (Most likely if I'll repair was not chosen; first undone Safe Guidance step if you were mid-guidance). No second history row until you actually End Session as Fixed / Stopped / Calling a professional.

Related: `docs/qa/RESUME_CASES.md`.
