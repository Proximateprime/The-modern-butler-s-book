# George UI pack — 29 Aug 2026

App **0.1.3+4**. Release APK: `build/app/outputs/flutter-apk/app-release.apk`.

Each numbered item → done. Spec-silent choices are in the ledger at the end.

## Items

1. **Safety stop must not dump home.**  
   `_endSession` always opens Record outcome. Safety stop locks **Needs a professional**, keeps the note field, then **Save** `pushReplacement`s **ProHandoff** (observed evidence, why we stopped, professional recorded). It does not `popUntil` House Book from the stop itself.

2. **One safety-stop wording.**  
   `UserFacingCopy.safetyStopOfficial` is the only body: unplug if safe, ventilate, do not keep running, call a professional. Chip, typed observation, and voice (`voiceHazardConfirm`) all use it. Banner body is `safetyStopDisplayCopy` (why + official).

3. **Persist real `safetyLevel`.**  
   `AppDependencies.buildDecisionContext` applies `sessionSafetyLevelFor` (`stop` / `professional` / `clear`). Session details no longer stay on `not evaluated`, so a hard stop does not show “no hazard recorded”.

4. **Top-load washer = lid.**  
   Add-washer **Lid or door** chips persist `WasherLoadStyle`. Session interview overlays `washer_mvp_v01` chips/prompts: top-load lid, front-load door, unknown door-or-lid. Inspect already said door or lid.

5. **Session state chrome.**  
   `Now:` follows stop / close-path phase (inspect, tools, Safe Guidance, verification, …), not a stuck “Answering questions” after the user has moved on. New sessions may still start in evidence collection.

6. **Camera/mic denied banner.**  
   **OK** dismisses the banner only. **Continue manually** dismisses and stays in session without that sensor. **Start fresh** abandons/archives the open session and `pushReplacement`s a new session.

7. **Naming.**  
   Outcome **Fixed**. Pro **Needs a professional**. Exit control and finished cue both **Exit**.

8. **Session AppBar overflow.**  
   “Using as …” is in the session body, not the tight bar. Chrome bottom allows two lines for state; clue/state ellipsize.

9. **Contrast.**  
   Stay-alert gold is `#6B4E0E` on cream (usable ~4.5:1 for 13px).

10. **Home history row overflow.**  
    Trailing is export icon only. Status is its own first subtitle line (`Needs a professional`); date/detail wrap on the second line.

11. **Reminder copy vs behavior.**  
    After save, copy uses `reminderPingScheduled` when the notifier is allowed, `reminderPingDenied` when not. Completion waits on `requestPermission` before showing that line.

12. **Expert Mode switch.**  
    Flip without the adult checkbox shows a snackbar (`expertModeNeedAdult`). Switch stays off until checked.

## Tests (this pack)

- Safety stop → outcome locked professional → ProHandoff; `safetyLevel` is `stop`.
- Official stop copy includes unplug/ventilate on chip and typed/shared string.
- Camera-denied **Start fresh** abandons the session.
- Top-load washer chips say lid.
- Expert switch without checkbox shows the message.
- Reminder success copy does not claim no ping when the notifier is armed.

`test/george_ui_aug29_test.dart`, plus existing `test/safety_stop_ui_test.dart`.

## Decision ledger (spec was silent)

- Washer latch wording is a **runtime overlay** on package templates (front-load package still authors “Door”; top-load households see lid).
- Safety stop lands on **Outcome (note + locked professional) → ProHandoff**, not a skip of the note screen.
- Stored level is computed at `buildDecisionContext` time from evidence/primary (no extra DB column). Values: `stop` if hard-stopped, else `professional` for gated FMs, else `clear`.
- **Start fresh** replaces the session route; it does not only pop home.
- History row: export icon only; kind on its own wrapping line so it is not jammed against share.
- Reminder success is keyed off `notificationsAllowed` after `requestPermission` (Plugin may ping only when already due; Home uses the same allowed/denied split).

## George next (find only)

New APK version **0.1.3+4**. Find only. Re-walk burning smell through handoff, top-load washer lid chips, camera-denied Start fresh, Expert switch without checkbox, reminder wording, history row on a phone width.
