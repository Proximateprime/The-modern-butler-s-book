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

## Leftover pack — 0.1.3+5

Fix only. Items 1–12 above stay done; this pack does not reopen them.

App **0.1.3+5**. Tests: `test/george_ui_aug29_test.dart` plus `test/george_ui_leftover_test.dart`.

### Fixes

1. **Safety-stop banner title.** `_SafetyStopBanner` title is **Needs a professional** (key `safety-stop-title`). Body stays `safetyStopDisplayCopy` / `UserFacingCopy.safetyStopOfficial` (unplug / ventilate / do not keep running). Chip, type, and voice still share that official string. Does not `popUntil` House Book from the stop.

2. **Blocking copy.** `blockingReasonSafetyLine` is `This step is blocked for safety — Needs a professional.` Burning-smell hard stop still uses the official banner, not this line.

3. **P0 / Safety Gate.** `sessionSafetyLevelFor` emits `professional` for gated / needs-professional FMs that are **not** a hard stop (`thermal-fuse-open` via `allowResolvedWhenConfirmed: false`; also `electric-supply-connection-fault` and `motor-failure`). `buildDecisionContext` still feeds that into `safetyLightForSession`, which maps `professional` → `SafetyLightKind.caution` (**Check carefully**). Hard stop (burning-smell evidence, `electrical-burning-smell-hazard`) stays `stop` / **Stop**. `clear` stays **Safe to continue**. `evaluateSafetyStop` no longer treats gated supply/motor Primary ids as a hard stop.

4. **Top-load washer history.** Display-time overlay from `appliance.washerLoadStyle` on stored id `washer-door-not-latched`: top-load **Lid latch path**, front-load **Door latch path**, unknown **Door or lid latch path**. Lid chips from item 4 stay accepted. Inspect door/lid goldens not reopened.

5. **Home history row at ~360px.** Trailing stays export-icon-only. Status one ellipsized line; meta one ellipsized line (`isThreeLine` fits title + two subtitle lines).

### Leftover ledger (locked picks)

- **Locked (Bible / Safety Gate):** `safetyLevel` `professional` → `SafetyLightKind.caution` (“Check carefully”). Not watch. Not calm. Hard `stop` stays Stop. `clear` stays Safe to continue.
- **Call site:** `AppDependencies.buildDecisionContext` stores `sessionSafetyLevelFor`. Gated FMs that are not a hard stop emit `professional` (thermal fuse and other `allowResolvedWhenConfirmed: false` paths; electric-supply / motor-failure). Fire/smoke FM and evidence hazards stay `stop`. The mapper then lights **Check carefully** even when `closePathActive` is false.
- Blocking line is presentation-only. Burning-smell banner body stays `safetyStopDisplayCopy` / `safetyStopOfficial`.
- History path overlay is display-time from `washerLoadStyle`. Stored failure-mode id stays `washer-door-not-latched`.
- Home history meta is one ellipsized line so the `isThreeLine` ListTile does not clip at phone width. Trailing stays export icon only. `PaperCard` is a `Material` ancestor so those tiles keep a valid ink parent.
- Appliance-detail history **title** is one ellipsized line at phone width (same clip rule as the home row).
- `GOLDEN_LABELS.md` still freezes I'll-repair **Call a pro** / missing-tool **Call a professional** as QA chrome. That freeze is not Bible. This pack does not reopen washer inspect / GOLDEN_LABELS door copy. Tests that asserted **Stop — Call a professional** now assert **Needs a professional** on the stop banner title.
- Do not restore **Calling a professional**, **End Session as Resolved**, or Stay-alert `#C4A035`. Stay-alert gold stays `#6B4E0E`.

### Phone (Given / tap / expect)

Phone or Android emulator, width about **360px**. Install **0.1.3+5**. First-run: **Skip** / **Get started** → **I understand**. Exact labels. Fail if House Book appears from the safety stop itself, if the lamp says **Safe to continue** on a professional/stop session, or if a top-load latch history row says **Door latch path**.

#### A. Burning smell → Needs a professional (not House Book)

- **Given** a dryer session on a phone (`Start repair` on a dryer).
- **Tap** **Burning smell / smoke** (or **Hazard signs**) → **Confirm and continue**.
- **Expect** banner title **Needs a professional** (not **Stop — Call a professional**). Body includes unplug if safe, ventilate, and do not keep running. Lamp is **Stop**, not **Safe to continue**. Blocking line **This step is blocked for safety — Needs a professional.** Ordinary questions are gone.
- **Tap** **End session** (or the stop CTA).
- **Expect** Record outcome locked on **Needs a professional**; note field still there. House Book / **Repair history** is not the next screen.
- **Tap** **Save**.
- **Expect** **ProHandoff** (observed evidence, why we stopped, professional recorded). Still not `popUntil` House Book from the stop.

#### B. Safety lamp (Safety Gate)

- **Given** the burning-smell stop from A.
- **Expect** the session lamp reads **Stop**. It must not read **Safe to continue**. Stored level is `stop`.
- **Given** a dryer session whose Primary is thermal fuse (`thermal-fuse-open`) without a hard stop — **Most likely** thermal fuse, or pick that failure mode. Not burning smell.
- **Expect** stored `safetyLevel` is `professional`. The lamp is **Check carefully**, never **Safe to continue**, never **Stop**.

#### C. Top-load history uses lid

- **Given** **Add Washer** → **Top-load** chip → save. Lid chips stay as in item 4 (**Lid won't close**).
- **Tap** the washer → finish a session whose leader is the latch path (`washer-door-not-latched` stays the stored id) → **Save**.
- **Expect** appliance **Repair history** uses **Lid latch path** when the path label is shown. Fail if that row says **Door latch path**. Front-load still **Door latch path**. Unknown **Door or lid latch path**. Do not file inspect “door” copy; inspect already said door or lid.

#### D. Home and detail history rows at phone width

- **Given** House Book on a ~360px phone with at least one completed repair whose status is **Needs a professional** and a long appliance name or note.
- **Expect** the home **Repair history** row: status one line, date/detail one line, trailing export icon only. No clipped text, no overflow stripe. Tap the row still opens the closed session.
- **Given** that appliance’s detail **Repair history** with a long headline.
- **Expect** the history title ellipsizes on one line. No overflow stripe.
