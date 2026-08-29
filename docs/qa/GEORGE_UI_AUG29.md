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
- History path overlay is display-time from `washerLoadStyle`. Stored failure-mode id stays `washer-door-not-latched`. Detail history uses the repository appliance (not the stale route argument) so an in-place load-style edit updates **Lid latch path**.
- Home history meta is one ellipsized line so the `isThreeLine` ListTile does not clip at phone width. Trailing stays export icon only. `PaperCard` is a `Material` ancestor so those tiles keep a valid ink parent. `clipBehavior: Clip.antiAlias` keeps ExpansionTile ink inside the rounded card.
- Appliance-detail history **title**, **cause**, and each **extra** line are one ellipsized line at phone width (same clip rule as the home row). Cause/extra sit under the `ListTile` so they cannot blow the three-line subtitle slot.
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
- **Given** that appliance’s detail **Repair history** with a long headline, cause, or note.
- **Expect** the history title, cause, and extra lines each ellipsize on one line. No overflow stripe.

## Leftover-next pack — 0.1.3+6

Fix only. Items 1–12 and the leftover pack above stay done; this pack does not reopen them. `GOLDEN_LABELS.md` **Call a pro** stays frozen.

App **0.1.3+6**. Tests: `test/george_ui_aug29_test.dart`, `test/george_ui_leftover_test.dart`, plus `test/george_ui_leftover_next_test.dart`.

### Fixes

1. **Heater-circuit Safety Gate.** Remaining `closePathDiyCannotComplete` heater-circuit leaders (`heating-element-failed`, high-limit, cycling thermostat, relay/control, thermistor, timer heat segment) emit `safetyLevel` `professional` → lamp **Check carefully**. Confirmed does not unlock **Fixed**. Not a hard stop (no **Stop** banner). Door-switch **Fixed** when a firm click starts the machine is unchanged. Resettable thermal cutoff stays DIY.

2. **Authoring import default.** Omitted `allowResolvedWhenConfirmed` parses as `false`. Explicit `true` only on DIY-completable paths. Resettable thermal cutoff stays DIY.

3. **Safety Validator before paint.** Existing `forbidden_guidance` / `visibleHouseholdHowTo` runs on inspect LOOK FOR, interview HOW, and similar household how-to strings before display. Prohibition lines (`do not` / `never`) stay visible. No new engine.

4. **House Book wipe.** Settings **Delete household data** with confirm. Cancel keeps data. Confirm wipes homes, appliances, sessions, photos, tools, and reminders on this device, then first-run / empty home. No cloud account. Silent wipe is illegal.

### Leftover-next ledger

- Heater-circuit professional leaders are an explicit id set in `dryer_close_path.dart`, plus `allowResolvedWhenConfirmed: false` on heating-element (built-in and Batch 01). Door-switch is not in the set.
- Import constructor / JSON default is false; `parseAllowResolvedWhenConfirmed` treats omitted and non-`true` as false.
- Display filter is `shouldHideGuidanceStep` / `visibleHouseholdHowTo` — same engine as close-path `visibleSafeGuidanceSteps`.
- Wipe is `AppDependencies.wipeLocalHouseBook` after an AlertDialog confirm only. First-run flag is cleared; disclaimer and theme stay.

### Phone (Given / tap / expect) — leftover-next

Phone or Android emulator, width about **360px**. Install **0.1.3+6**. First-run: **Skip** / **Get started** → **I understand**. Exact labels. Do not file GOLDEN_LABELS **Call a pro**.

#### E. Heating-element Check carefully (not calm, not a hard stop)

- **Given** a dryer session on a phone (`Start repair` on a dryer). Not burning smell.
- **Tap** to make **Heating element** the Primary (Most likely / pick **heating-element-failed**).
- **Expect** lamp **Check carefully**, never **Safe to continue**, never **Stop**. No **Needs a professional** hard-stop banner (that banner is for burning smell / smoke). Stored `safetyLevel` is `professional`.
- **Tap** through safe checks to the end of this path.
- **Expect** **Pro recommended** / **Needs a professional**. **Fixed** is not offered. Confirming the still-cold pattern is not a completed repair.

#### F. Door-switch Fixed unchanged

- **Given** a dryer session whose Primary is door switch (`door-switch-failure`). Not burning smell.
- **Expect** stored `safetyLevel` is not `professional` from the heater-circuit gate. No **Needs a professional** hard-stop banner.
- **Tap** through the door-click check. If a firm click actually starts the machine and verification is **Confirmed**,
- **Expect** **Fixed** is still available. This path is not a heater-circuit hard professional close.

#### I. Authoring import default is not DIY-complete

- **Given** a dryer session whose Primary is **Heating element** (Batch 01 `allowResolvedWhenConfirmed` is false — same result as omitting the flag on import).
- **Tap** I'll repair / Do safe checks if shown, then **I did this** through the safe checks.
- **Expect** **Pro recommended**, not **Fixed**. Settings still shows **0.1.3+6**. Explicit DIY (vent / resettable thermal cutoff) is not this path.

#### G. Forbidden how-to is not shown

- **Given** inspect LOOK FOR or interview **How to check** on a dryer session.
- **Expect** no live-meter / jumper / bypass how-to is painted. Lines that start with **Do not** or **Never** stay visible (for example do not probe live terminals).

#### H. Settings wipe + confirm → empty home

- **Given** a House Book with at least one household and appliance. Open **Settings**.
- **Tap** **Delete household data**.
- **Expect** confirm dialog **Delete all household data?**
- **Tap** **Cancel**.
- **Expect** the household and appliance are still there. Settings stays open.
- **Tap** **Delete household data** → **Delete everything**.
- **Expect** first-run (Skip / Get started). After Skip, empty home: **Create Household**, no appliances. No silent wipe.

## Leftover-after pack — 0.1.3+7

Fix only. Items 1–12, leftover, and leftover-next stay done; this pack does not reopen them. `GOLDEN_LABELS.md` **Call a pro** stays frozen. Leftover-next lamp / Confirmed ≠ Fixed styling is unchanged. Import parse default stays false.

App **0.1.3+7**. Tests: prior George UI files plus `test/george_ui_leftover_after_test.dart`.

### Fixes

1. **Heater-circuit I'll repair / DIY price.** `closePathDiyCannotComplete` returns true for the heater-circuit id set (`isHeaterCircuitDiyCannotCompleteLeader`), not only `!allowResolvedWhenConfirmed` or a “call a technician” substring. `cycling-thermostat-stuck-closed` and `relay-or-control-no-heat-output` (and remaining heater-circuit siblings) have `allowResolvedWhenConfirmed: false`. Most likely shows the pro-scope notice; Parts & cost is Pro ~ only (no DIY price). Confirmed → **Needs a professional**. Not a hard stop. Leftover-next heating-element lamp / Continue close is unchanged.

2. **start-switch-failure Confirmed ≠ Fixed.** `allowResolvedWhenConfirmed: false`. Gated professional (`isGatedProfessionalFailureMode`): lamp **Check carefully**, not a hard **Stop**. **I'll repair** hidden; **Pro recommended**. Not door-switch; door-switch **Fixed** when a firm click starts the machine stays. `start-capacitor-or-start-assist-weak` stays false.

3. **House Book wipe deletes rating-plate photos.** After confirm only, `wipeLocalHouseBook` deletes every appliance `ratingLabelPhotoPath` as well as evidence `localPhotoPath`. Cancel leaves the file. Silent wipe stays illegal. Confirm/cancel copy unchanged.

4. **Release validator fail-closed.** Heater-circuit id set + `start-switch-failure` + the existing risky list require `allowResolvedWhenConfirmed == false`. Prefer-professional is not an escape hatch. No new engine.

### Leftover-after ledger

- Safety Gate is the id set / `allowResolvedWhenConfirmed: false`, not `isProHandoffGuidanceStep` substring copy.
- Worn rollers stay parked. Expert unplugged heater-panel stays parked.
- Electric-supply is already gated professional and is on the existing risky list, so Confirmed also cannot unlock **Fixed**.

### Phone (Given / tap / expect) — leftover-after

Phone or Android emulator, width about **360px**. Install **0.1.3+7**. First-run: **Skip** / **Get started** → **I understand**. Exact labels. Do not file GOLDEN_LABELS **Call a pro**.

#### J. Stuck-closed thermostat is not DIY

- **Given** a dryer session on a phone (`Start repair` on a dryer). Not burning smell.
- **Tap** to make **Cycling thermostat stuck closed** the Primary (`cycling-thermostat-stuck-closed`).
- **Expect** lamp **Check carefully**, never **Safe to continue**, never **Stop**. No **Needs a professional** hard-stop banner. Most likely shows the pro-scope notice (**A full fix likely needs a pro**).
- **Tap** **Continue**. **I'll repair** / **Do safe checks** if shown (same leftover-next close as heating-element).
- **Expect** no **DIY ~** / DIY Parts & cost. **Call a pro** stays GOLDEN_LABELS. After safe checks, **Pro recommended**.
- **Expect** **Fixed** is not offered. Confirming the stuck-closed pattern is not a completed repair. Settings still shows **0.1.3+7**.

#### K. Start-switch Confirmed is not Fixed

- **Given** a dryer session whose Primary is start switch (`start-switch-failure`). Not burning smell. Not door-switch.
- **Expect** lamp **Check carefully**, never **Stop**. Stored `safetyLevel` is `professional`. No **Needs a professional** hard-stop banner.
- **Tap** through lock/latch safe checks if shown. Do not treat this as the door-click **Fixed** path.
- **Expect** **Pro recommended**. **Fixed** is not offered. A firm door click that starts the machine is the **door-switch** path, not this one.

#### L. Wipe deletes the rating-plate photo

- **Given** a House Book appliance with a rating-plate photo attached (`ratingLabelPhotoPath` on disk). Open **Settings**.
- **Tap** **Delete household data**.
- **Expect** confirm dialog **Delete all household data?**
- **Tap** **Cancel**.
- **Expect** the household, appliance, and rating-plate photo file are still there. Settings stays open.
- **Tap** **Delete household data** → **Delete everything**.
- **Expect** first-run (Skip / Get started). The rating-plate photo file is gone from the device. After Skip, empty home: **Create Household**, no appliances. No silent wipe. Disclaimer and theme stay.

## Leftover-after-after pack — 0.1.3+8

Fix only. Items 1–12, leftover, leftover-next, and leftover-after stay done; this pack does not reopen them. `GOLDEN_LABELS.md` **Call a pro** stays frozen. Worn rollers stay parked. Expert unplugged heater-panel stays parked. `motor-overheat-protector-open` stays DIY (KNOWN_ISSUES split). Door-switch **Fixed** when a firm click starts the machine stays.

App **0.1.3+8**. Tests: prior George UI files plus `test/george_ui_leftover_after_after_test.dart`.

### Fixes

1. **P1 electricHeatGenerationModeIds.** The gas-dryer extra-exclude set in `dryer_energy_source.dart` is the heater-circuit DIY-cannot-complete leaders plus `missing-leg-240v-supply` and `loose-power-cord-connection-electric`. Extra exclude counts only (`applyFuelTypeSteering` as today). Ranking math is not rewritten. Adds high-limit, cycling thermostat (failed / stuck-open / stuck-closed), thermistor, and timer heat segment. Electric dryer unchanged. Resettable thermal cutoff is not in this set.

2. **P0 start-capacitor-or-start-assist-weak.** Id is on `_gatedProfessionalFailureModeIds` and `failClosedResolvedOnConfirmModeIds`. Lamp **Check carefully**. **I'll repair** off. Confirmed ≠ **Fixed**. Not a hard stop. Not door-switch. Not `motor-overheat-protector-open`. Leftover-after “stays false” was pack-scope (`allowResolvedWhenConfirmed` already false); this pack makes the lamp / fail-closed id-based. `start-switch-failure` stays as leftover-after left it.

3. **P1 gas-dryer-no-ignition-professional-only.** Id is on `_gatedProfessionalFailureModeIds`. Already on `riskyVerificationModeIds`. Not a hard stop. Gas smell / propane evidence stays **Stop**. External valve + cycle only; no igniter / gas valve / burner / flame-sensor how-to. **I'll repair** stays off.

4. **P1 partsCostDiyOutOfScope.** Treats `isGatedProfessionalFailureMode` as DIY-out-of-scope even if `closePathForFailureMode` is null. Treats `isHeaterCircuitDiyCannotCompleteLeader` the same way. Resettable thermal cutoff stays DIY (`isResettableThermalPath` + `allowResolvedWhenConfirmed` true). GOLDEN_LABELS **Call a pro** string stays frozen.

### Leftover-after-after ledger

- Fuel steering still adds exclude counts only. No ranking-formula change.
- Start-capacitor and gas-no-ignition lamps are id-based gated professional, not Primary-as-hard-stop.
- `partsCostDiyOutOfScope` does not wait on an imported close path for those gated ids.

### Phone (Given / tap / expect) — leftover-after-after

Phone or Android emulator, width about **360px**. Install **0.1.3+8**. First-run: **Skip** / **Get started** → **I understand**. Exact labels. Do not file GOLDEN_LABELS **Call a pro**.

#### M. Gas dryer, no heat

- **Given** a dryer whose energy source is **Gas**. **Start repair**. Not burning smell.
- **Expect** **Most likely** is not cycling thermostat stuck closed / heating element / high-limit.
- **Expect** lamp is not **Safe to continue** on a gas no-ignition / professional path.

#### N. Start-capacitor

- **Given** a dryer session whose Primary is `start-capacitor-or-start-assist-weak`.
- **Expect** lamp **Check carefully**, never **Stop**, never **Safe to continue**. **Pro recommended**. **Fixed** not offered.
- **Expect** door-switch firm-click **Fixed** still exists on the other path. motor-overheat-protector cooldown path still DIY.

#### O. Gas no-ignition

- **Given** a dryer session whose Primary is `gas-dryer-no-ignition-professional-only`.
- **Expect** lamp **Check carefully**, not a hard-stop banner. No igniter/valve how-to. **I'll repair** hidden.
- **Expect** gas smell still **Stop**.

#### P. I'll repair fail-closed

- **Given** a gated professional Primary (start-capacitor or gas-no-ignition), including when `closePathForFailureMode` is null (`isGatedProfessionalFailureMode` still true).
- **Expect** **I'll repair** / **DIY ~** are not shown even if Parts & cost would otherwise quote a part. **Call a pro** stays GOLDEN_LABELS. Pro ~ only. Resettable thermal cutoff stays DIY.

