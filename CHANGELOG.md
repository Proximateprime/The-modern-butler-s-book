## Typed hazard v2 (2026-09-04)

App **0.1.4+27**. Typed Other (starter + interview) and free notes that
match the shared hazard lexicon — including **burning smell** / bare
burning — write `hazard-observation` Yes and lock/stop like the chip
path. Nonsense typed Other does not invent a failure mode. Groq stays
phrasing-only. GOLDEN **Call a pro** stays. Play listing stays out.
Tests: `test/red_typed_hazard_v2_test.dart` (prior suites stay green).

## Clues honesty v1 (2026-09-04)

App **0.1.4+26**. Clues chrome count and the Clues list use the same
filter (`householdCluesInOrder` / interview observations only) so count
never disagrees with the list. Panel / invasive honesty treats
**cover / housing / rear / back** the same as panel work, and still
honors package `requiresPanelOff` tags. Groq stays phrasing-only.
GOLDEN **Call a pro** stays. Play listing stays out. Tests:
`test/red_clues_honesty_v1_test.dart` (prior suites stay green).

## DIY pro handoff gate v1 (2026-09-04)

App **0.1.4+25**. After **I'll repair**, Pro-recommended / pro handoff
chrome does not show (`showProHandoff` is gated on `!_choseRepair`).
Safe checks still run. Groq stays phrasing-only. GOLDEN **Call a pro**
stays. Play listing stays out. Tests: `test/red_diy_pro_v1_test.dart`
and the audit widget test in `test/audit_hardening_v1_test.dart`
(prior suites stay green).

## Typed hazard v1 (2026-09-04)

App **0.1.4+24**. Typed Other / free notes with hazard language (including
**I smell gas**) take the same write+lock path as voice: record
`hazard-observation` Yes and lock chips. Hazard-observation Other runs the
shared gas matcher — it does not skip. Smell-gas, gas-leak, propane, and
bare-burning keywords live in one list. Recover-after-error mirrors the
happy-resume hold / I’ll-repair gate so invent cannot reopen. Empty
report-wrong notes are rejected and not saved. Groq stays phrasing-only.
GOLDEN **Call a pro** stays. Play listing stays out. Tests:
`test/red_typed_hazard_v1_test.dart` (prior suites stay green).

## Audit hardening v1 (2026-09-04)

App **0.1.4+23**. Voice hazard always records and locks even under
invent/settle/hold. Tool-honesty empty guidance stays on stop / Call a
pro — it never advances to verification. After **I'll repair**, DIY
chrome does not say a full fix needs a pro, that you cannot finish at
home, or that a technician fits this part. Optional tools copy allows
**I don’t** continue. Report-wrong fields are household labels only.
Resume recover keeps a held open observation. Held taps survive settle.
Corrupt resume rows surface calm resume-failed copy. Tool honesty prefers
package `requiresPanelOff` / `requiresMeter` tags. Settings can warn when
hosted `version.json` lags the running build. Groq stays phrasing-only.
GOLDEN **Call a pro** stays. Play listing stays out. Tests:
`test/audit_hardening_v1_test.dart` (prior suites stay green).

## Resume open question v6 (2026-09-04)

App **0.1.4+22**. Continue repair after a **cold reload, every time**
(not only the first walk) restores the unanswered on-screen open
observation (lint-filter). It must **not invent** Heavily clogged, **not
advance** to outside-vent, and must not reset to drum-turns / ranking
next, blank to **No more questions for now**, or jump into **Following
safe steps** — including when Thermal fuse / Most likely is named.
Stored unanswered id wins over a painted ranking-next steal after
restore settles. Invent-write and close-path advance stay blocked while
that id is held. Clues stay honest. V5–V2 gates stay. Groq stays
phrasing-only. GOLDEN **Call a pro** stays. Play listing stays out.
Tests: `test/resume_open_q_v6_test.dart` (multi-reload invent coverage;
V1–V5 suites stay green).

## Resume open question v5 (2026-09-04)

App **0.1.4+21**. Continue repair after a cold reload restores the
**unanswered on-screen open observation** (lint-filter). It must **not
invent** Heavily clogged (or any auto-answer), **not advance** to
outside-vent, **not reset** to drum-turns / ranking next, **not blank**
to **No more questions for now**, and **not jump** into **Following safe
steps**. Persist must not overwrite a held open id with ranking next
while restore is settling. Inspect chrome cannot steal a named-primary
unanswered lint path. V4–V2 gates stay. Groq stays phrasing-only.
GOLDEN **Call a pro** stays. Play listing stays out. Tests:
`test/resume_open_q_v5_test.dart` (both Rex invent-A and drum-reset
paths; V1–V4 suites stay green).

## Resume open question v4 (2026-09-04)

App **0.1.4+20**. Continue repair after a cold reload must **not invent an
answer** for an unanswered on-screen open observation (no “Heavily clogged”
fill or auto-select) and must **not advance past** that question (no jump
to outside-vent). Naming a primary (Most likely / Reviewing chrome) may
stay; it must not steal, blank, invent, or skip the open id. Clues stay
honest — no fabricated interview answers in the store. V3/V2 gates stay:
restore vs ranking-next, never blank to **No more questions for now**,
never jump into **Following safe steps**, named primary must not block
hold/restore. Groq stays phrasing-only. GOLDEN **Call a pro** stays.
Play listing stays out. Tests: `test/resume_open_q_v4_test.dart`
(V1–V3 suites stay green).

## Resume open question v3 (2026-09-04)

App **0.1.4+19**. Continue repair after a cold reload restores the
**unanswered on-screen open observation** even when ranking has already
named a primary (Most likely / Reviewing the likely cause). Lint-filter
stays on screen; that chrome may still name the cause but must not steal
or blank the open question. V2 gates stay: restore vs ranking-next, never
blank to **No more questions for now**, never jump into **Following safe
steps** while unanswered. Groq stays phrasing-only. GOLDEN **Call a pro**
stays. Play listing stays out. Tests: `test/resume_open_q_v3_test.dart`
(V1/V2 suites stay green).

## Resume open question v2 (2026-09-04)

App **0.1.4+18**. Continue repair after a cold reload restores the
**unanswered on-screen open observation** even when ranking has no next
question, conclusion would paint **No more questions for now**, or stored
close-path would jump into **Following safe steps** / guidance chrome.
Lint-filter stays on screen; clues stay as they were. Groq stays
phrasing-only. GOLDEN **Call a pro** stays. Play listing stays out. Tests:
`test/resume_open_q_v2_test.dart` (V1 suites stay green).

## Resume open question (2026-09-04)

App **0.1.4+17**. Continue repair after a cold reload restores the **on-screen
open observation** (for example lint-filter), not ranking’s suggested-next
template (for example motor humming), even when close-path phase is
conclusion and resume chrome says a most likely cause. Clues stay as they
were. Groq stays phrasing-only. GOLDEN **Call a pro** stays. Play listing
stays out. Tests: `test/resume_open_q_v1_test.dart`.

## Resume clues (2026-09-04)

App **0.1.4+16**. Continue repair after a cold reload keeps the same open
question and the full verified **clues** set — including the dryer lint-filter
interview with two clues. Snapshot writes recapture if later evidence lands
while a save is in flight, and the open question is stored even when the
answer panel is showing ranking’s next template. Resume chrome (“Last time we
knew…”) stays household voice and does not print engine phase names such as
`tools` or `guidance`. Groq stays phrasing-only. GOLDEN **Call a pro** stays.
Play listing stays out. Tests: `test/resume_clue_v1_test.dart`.

## Calm fail (2026-09-04)

App **0.1.4+15**. Bad state degrades: offline / Groq unavailable keeps the
on-device templates for diagnosis, next question, stop/handoff, and hazard
flags. Missing, empty, or corrupt dryer packages do not invent failure modes
or part swaps — they show honest “can’t help yet” / install copy. Camera and
microphone refusals stay optional with calm copy. A corrupt household snapshot
still banners; a broken resume row is dropped instead of wiping the book or
minting clues. Groq stays phrasing-only and is not called while offline.
GOLDEN **Call a pro** stays. Play listing stays out. Tests:
`test/calm_fail_v1_test.dart`.

## This was wrong (2026-09-04)

App **0.1.4+14**. Testers can report a bad diagnosis or step from **Settings →
Report a problem**, and from **This was wrong** on session completion and
pro handoff. A short local note is saved on the device (appliance category,
package/version, stop reason or last question id, clue count — no photos,
floor plans, or household names). A `mailto:` stub can open a prefilled
draft; if email isn’t available, the note still stays. No analytics vendor,
no auto-upload of chats or photos. Groq stays phrasing-only and does not
decide what was wrong. GOLDEN **Call a pro** stays. Play listing stays out.
Tests: `test/report_wrong_v1_test.dart`.

## Tool honesty (2026-09-04)

App **0.1.4+13**. After the session records **no tools**, or **I don’t** on a
panel-class tool (screwdriver / nut driver / pliers) or a meter, the next
Safe Guidance step is not panel-off or other tool-backed invasive work.
Easy checks, unplug, and **do not / never** limits stay. When the only
remaining path needs that capability, the existing stop / Pro recommended
handoff is used — the app does not pretend the declined step is available.
Users who marked **I have** (and Expert Mode, when that extra is authored)
still see those steps. Safety hard-stops are unchanged. Groq stays
phrasing-only and does not decide honesty. GOLDEN **Call a pro** stays.
Play listing stays out. Tests: `test/tool_honesty_v1_test.dart`.

## Session resume (2026-09-04)

App **0.1.4+12**. After lock, background, or a cold start, an in-progress
dryer session returns to the same open question and the same verified
**clues** count. Evidence and `SessionUiResumeState` stay in the existing
local domain snapshot; lock/background flushes that snapshot after the
session writes the current prompt. Leaving with Exit/back still shows
**Continue repair** on home. Empty stores and completed sessions do not
come back as in-progress. Groq stays phrasing-only. GOLDEN **Call a pro**
stays. Play listing stays out. Tests: `test/session_resume_v1_test.dart`,
`test/session_resume_test.dart`.

## Natural UI v2 honesty (2026-09-04)

App **0.1.4+11**. Presentation and honesty only. Empty brand/model on a real
Save stay **Unknown**, never Demo Manufacturer / DEMO-*. Add-appliance
Energy + Save scroll on a short pane. Session progress uses one household
**clues** count. Energy **Not sure** is valid copy. Gas how-to does not
inspect gas lines. Drum-turns how-to does not contradict unplug-before
reach-in. **What's going on?** is observations, not a diagnosis. **Skip to
best guess** hides with zero clues. **Already checked** hides on a first
session with no history. Pages/desktop does not claim voice; inspect
Doesn't-match copy does not fight **Can't see**. First-run **Skip** on
**What Butler does** completes on the first pointer-down (no autofocus
click-to-focus). Groq stays phrasing-only.
GOLDEN **Call a pro** stays. Play listing stays out. Tests:
`test/natural_ui_v2_test.dart`.

## First-run whole-screen tap (2026-09-04)

App **0.1.4+10**. Presentation only. First-run has no bottom Continue /
Get started strip — the body is the advance tap (same action those
buttons used). Skip stays a 48px first-tap target in the app bar and
still does not acknowledge **I understand**. Layout uses SafeArea so
content sits above the system nav bar. No Transform on the first-run
tree; Pages `web/index.html` pointer mapping is unchanged. No engine,
safety-gate, unmatched-starter, or Groq behavior changes. Details:
[`docs/qa/FIRST_RUN.md`](docs/qa/FIRST_RUN.md).

## Unmatched starter honesty (2026-08-29)

App **0.1.4+9**. Presentation/honesty only. Starter Other is Evidence
(Other / free-text), not the answer to a warmth question that was never
shown. Unmatched Other does not run the ranked heat/noise interview.
After the bounded universal set (power, heat, spin, error lights — existing
templates only) the path is honest no-match → ProHandoff. Why-ask explains
the observation, not a diagnosis they never gave. No squeal / worn-rollers
swap without a noise observation. The typed note is echoed. Basement smell
does not invent an odor FM or trip a fire-stop. A dryer with no brand/model
says this book does not have this machine’s plate — not “General dryer
guide … your model may differ.” While they type Other, the keyword matcher
must not auto-check heat/noise chips; the CTA stays **Confirm with what I
typed.** Unchecking a chip does not re-fire the matcher. Groq may phrase
the echo; it may not pick the next question id, mint chips, or write
how-to. No new engine. Play listing stays out. Details:
[`docs/qa/GEORGE_UI_AUG29.md`](docs/qa/GEORGE_UI_AUG29.md).

## Safety handoff follow-up (2026-08-29)

App **0.1.4+8**. Presentation/honesty only. The fire/smoke hazard question no
longer bundles “repeated stopping” into the same Yes. Fire/smoke still hard-stops.
On a safety stop, Symptom is the mid-session burning/smoke observation — not
**not recorded** / **—**. A leftover ranking leader is labeled leftover and is
not why we stopped; `whyStopping` stays the hazard. No new engine, chips,
question ids, or failure modes. GOLDEN **Call a pro** stays. Play listing stays
out. Groq stays phrasing-only. Details:
[`docs/qa/PRO_HANDOFF_UX.md`](docs/qa/PRO_HANDOFF_UX.md).

## Pages mouse hit mapping (2026-08-29)

App **0.1.4+7**. GitHub Pages mouse clicks were landing ~164px / 4 chip rows
above the painted control (Burning smell selected Won’t start). Keyboard
Space on a focused chip was already correct — pointer mapping on Flutter web,
not chip ids. `web/index.html` now locks html/body to the viewport, keeps
events on `flutter-view` (canvas is raster-only, never focused), and sizes
the canvas CSS box to the view instead of bitmap / device-pixel size.
AppBar and `ButlerPageBody` stay on that same view box. No new chips,
question ids, failure modes, or Play listing. Groq stays phrasing-only.
Details: [`docs/qa/GEORGE_UI_AUG29.md`](docs/qa/GEORGE_UI_AUG29.md).

## Safety handoff honesty (2026-08-29)

App **0.1.4+6**. Burning-smell → stop → pro handoff no longer copies the
ranking leader’s unused lint/vent checklist or the vent close-path why.
`alreadyTried` is what the session recorded (completed inspect / guidance +
those evidence rows). Empty prints **None recorded.** On a safety stop,
`whyStopping` is the hazard / Needs a professional reason. The leader
hypothesis may still appear as an unconfirmed guide match. Spoken/read-aloud
uses the same lists; Groq may phrase and must not invent tried steps.
Household chrome on the stop screen uses the clue count for
`context-evidence-count` so it does not contradict **No clues yet**.
AppBar chrome from NATURAL_UI_V1 stays. GOLDEN **Call a pro** stays.
Play listing stays out. Details: [`docs/qa/PRO_HANDOFF_UX.md`](docs/qa/PRO_HANDOFF_UX.md).

## Natural UI — first-run, home start, pro handoff (2026-08-29)

App **0.1.4+5**. First-run drops the “1 of 3” tour chrome and reads as a short
butler greeting in the book theme type (no bare Georgia family). The three
UserFacingCopy beats stay. Skip keeps the 48px first-tap target. Home
empty/start copy is household voice (**Name this home**, not Create Household),
with one helper, one create control, and one Load sample. Appliances waits
until the house is named.
Pro handoff uses ButlerPageBody / PaperCard / PrimaryCta like Home and Session.
Privacy slide is local-first household copy (no Groq / backend vendor names;
phrasing disclosure stays in Settings). Settings local-first line no longer
claims nothing is uploaded.
Source Pages chrome (`web/index.html`, `web/manifest.json`) uses a household-book
description and paper `#F3EDE3`. Groq still phrases the spoken paragraph only.
Session scroll / Skip / quieter card from **0.1.4+4** stay. Play listing stays out.
Details: [`docs/qa/GEORGE_UI_AUG29.md`](docs/qa/GEORGE_UI_AUG29.md),
[`docs/qa/FIRST_RUN.md`](docs/qa/FIRST_RUN.md).

## Session scroll, Skip, and quieter question card (2026-08-29)

App **0.1.4+4**. Short hosted viewport (~656px) can reach Current question,
Why ask this?, and chips including Other / describe. First-run Skip completes
on the first tap; the I understand disclaimer still follows. Secondary
collapsibles sit under a muted **More about this session** heading (evidence
kept, tiles stay collapsed). Safety Stop banner stays pinned when `safetyStop != null` — unplug
AND ventilate AND don’t keep running. Groq stays talk-only. Play listing
stays out. Details: [`docs/qa/GEORGE_UI_AUG29.md`](docs/qa/GEORGE_UI_AUG29.md).

## Phrase Other / describe type-in on question cards (2026-08-29)

App **0.1.4+3**. Question-card Groq and the Other / describe type-in stay in
sync from the same overlay. Chip id `Other / describe` remains the recorded
prefix. Optional `describe_title` / `describe_hint` may ride the same JSON;
missing extras stay packaged. Extra chip ids still rejected. One phrasing
call per screen — not per keystroke. Groq does not remap typed notes or pick
the next question. Mark’s later ask that Groq research a new problem with
no chip yet is **out** of this pack. Safety gate / `visibleHouseholdHowTo`
still run before paint. Play listing stays out. Details:
[`docs/qa/GEORGE_UI_AUG29.md`](docs/qa/GEORGE_UI_AUG29.md).

## Hosted testers call phrase via public Supabase URL (2026-08-29)

App **0.1.4+2**. GitHub Pages and the GitHub-release APK compile public
`SUPABASE_URL` + anon JWT only. Groq stays on the Edge Function. Web uses
package:http with conditional imports (no dart:io HttpClient). Init failures
are swallowed before runApp. Safety gate still runs before paint. Play
listing stays out. Details:
[`docs/qa/PLAY_READY_GROQ.md`](docs/qa/PLAY_READY_GROQ.md).

## Play-ready Groq via Supabase Edge Function (2026-08-29)

App **0.1.4+1**. Groq key moves behind `supabase/functions/phrase`. The client
prefers that Edge Function when Supabase URL + anon/publishable are set.
`--dart-define=GROQ_API_KEY` stays a local-only fallback (Mark’s machine).
Play/CI/Pages/GitHub APK must not pass it. Safety gate still runs before
paint. Play Console listing stays out. Details:
[`docs/qa/PLAY_READY_GROQ.md`](docs/qa/PLAY_READY_GROQ.md).

## Groq phrasing pack (2026-08-29)

App **0.1.4+0**. Groq rephrases seven ON household surfaces (question, stop, pro handoff, Speak Human diagnosis, Confirm ≠ Fixed, resume, comfort). The engine still decides template ids, ranking, and Fixed eligibility. Missing key / timeout / validator fail stay on packaged copy. No Settings paste-a-key field. Details: [`docs/qa/GEORGE_UI_AUG29.md`](docs/qa/GEORGE_UI_AUG29.md).

## Device-test fix pack (2026-08-25)

App **0.1.1+2**, dryer-core **1.4.2**. Real-APK feedback: **Review what you checked** no longer undoes diagnosis; resettable thermal cutoff vs pro-only fuse; multi-select first symptoms; easier-first dual hypotheses; brick-risk warnings; local maintenance notify + hide empty manufacturer cards; enrichment store stub (not live diagnosis). Details: [`docs/qa/TEST_FEEDBACK_AUG25.md`](docs/qa/TEST_FEEDBACK_AUG25.md).

## MVP audit and polish (2026-08-22)

Pro-only paths (thermal fuse, heating element, door switch) no longer show a **DIY** price or **I'll repair** on Parts & cost, and the *A full fix likely needs a pro* notice now appears on the **Most likely** card instead of only at the guidance step. Parked AR code deleted (visual guide screen, inspect diagram widget, unbundled SVGs, **Show me where**). Meters removed from the addable tools catalog. **Household Pro (debug)** is compiled out of release builds. Nine pre-existing widget-test failures fixed; the full suite is green. No knowledge content or package versions changed. Details: [`docs/qa/AUDIT_POLISH_MVP.md`](docs/qa/AUDIT_POLISH_MVP.md).

## MVP definition freeze (2026-08-22)

P2-16: [`docs/MVP_DEFINITION.md`](docs/MVP_DEFINITION.md) — MVP is Phase 1+2 as implemented (not the 2026-07 Version 1 wish list). Phase 3, AR, and Knowledge Factory stay out of the app until external validation.

## Phase 2 candidate APK (2026-08-22)

P2-15: release APK `build/app/outputs/flutter-apk/app-release.apk` (99.2 MB). Docs: [`docs/qa/BUILD_NOTES_PHASE2.md`](docs/qa/BUILD_NOTES_PHASE2.md), [`docs/qa/REGRESSION_PHASE2.md`](docs/qa/REGRESSION_PHASE2.md), [`docs/qa/TESTER_BRIEF_PHASE2.md`](docs/qa/TESTER_BRIEF_PHASE2.md), [`docs/qa/PHASE2_EXIT_CHECKLIST.md`](docs/qa/PHASE2_EXIT_CHECKLIST.md) (**PARTIAL** overall). No Phase 3.

## Household Pro debug hook (2026-08-22)

P2-14: honest entitlement placeholder. Core repair, House Book, and safety stops stay free. Settings **Household Pro (debug)** adds extra export formatting. No Store billing, no fake urgency. [`docs/qa/MONETIZATION_HOOK.md`](docs/qa/MONETIZATION_HOOK.md).

## Fridge observational paths documented (2026-08-22)

P2-13: `fridge-core` **1.0.1** stays PRIMARY observational (no refrigerant / sealed-system / compressor live DIY). Trust bar: [`docs/qa/FRIDGE_PATHS.md`](docs/qa/FRIDGE_PATHS.md). No package version bump.

## Repair readiness inventory round-trip (2026-08-22)

Required tools on the pre-guidance checklist show **In your tools** vs **Not in your tools** from household inventory. Remove a required tool → missing; add it back → clears. Parts stay on the leading-path Parts step. Continue-with-caution is unchanged for non-electrical gaps.

## Pattern hints from verified history (2026-08-22)

If an appliance has two or more verified Fixed (or matching maintenance) records in the same vent / drain-filter / coils family, the appliance page shows a dismissible note based on household history. One record shows nothing. No cloud, no ranking change.

## Light household members (2026-08-22)

People in the same home share appliances, tools, and House Book. Switch who is using the app from Profiles. Homes on this device stay separate. No accounts or roles.

## Washer and dishwasher primary-path second pass 0.2.3 (2026-08-22)

Washer `washer-core` **0.2.3** and dishwasher `dishwasher-core` **0.2.3**: discriminators and inspect polarity on existing top paths (drain-filter packed vs clear; DW filter-first easy checks). No new families. Dryer and fridge versions unchanged. Details: `docs/knowledge/washer/CHANGELOG.md`, `docs/knowledge/dishwasher/CHANGELOG.md`.

## Park AR / generated diagrams (2026-08-20)

Location pictures, Show me where, and generated dryer schematics are parked (`locationVisualAidsEnabled = false`). Inspect stays text: LOOK FOR, OK / Not OK, chips. Optional inspect camera is flashlight only (no part box).

## Dryer inspect diagrams (2026-08-19)

Dryer lint-filter, outside-vent, and visible-hose inspect steps show a packaged typical-location schematic with a labeled rectangle on that part, a specific LOOK FOR line, and confirmation chips. Optional camera is a flashlight only — the diagram stays. Washer and dishwasher inspect stay text-only.

## Guided inspect in the live path (2026-08-19)

Inspect is no longer a fake cabinet drawing after Tools. Dryer heat/vent/filter easy-checks show the inspect card (LOOK FOR + OK / Not OK + chips). Close path runs the same chain after Parts / I'll repair and **before Tools**. No generated pictures or orange boxes; optional **Use camera while I look**. Chips still write the existing templates and gate invasive steps.

## Path-only Fixed wrap-up (2026-08-19)

After **Fixed**, Done shows that path's prevention (no dryer lint fallback), a next-due line when the path has a calendar interval, and cost rows only for parts that path replaces. Home and appliance history still get one row. Inspect answers no longer move End Session eligibility off the path you just confirmed.

## Fridge inspect + Show me where typical-only (2026-08-19)

Fridge `fridge-core` **1.0.1** adds look-only inspect on cooling/door/setpoint paths (temps → gasket → vents; coils look before pull-out on the dirty-coils mode). Chips write existing fridge templates. Ranking is unchanged. Show me where treats the dryer access panel as a typical diagram (no live pin / `visual-guide-target-box`). No YOLO, quotes, or ranking changes.

## Door-not-latched inspect (2026-08-19)

Washer and dishwasher **door-not-latched** now run the existing latch inspect before any seal teardown or switch bypass (skipped if the interview already recorded the door-click template). Won’t-drain inspect is unchanged: washer door → coin trap; dishwasher filter → door → high-loop/hose. No new appliances or ranking templates.

## Inspect hone (Phase E, 2026-08-19)

Inspect cards show **Inspect N of M** for the real chain, a diagram-only typical-area rectangle labeled **Typical area — confirm on yours.**, and a blocking line if required inspect is incomplete before invasive guidance. `look_for` copy names one physical check. Live camera still does not diagnose and no longer draws a tracking box. Docs: `docs/qa/INSPECT_STEPS.md`. Package versions unchanged.

## Inspect look-only camera (2026-08-19)

Inspect steps with view-only camera offer **Diagram** and **Camera**. Camera is look-only: the same safety and look-for copy stay on screen, with the caption **Camera does not diagnose. Confirm what you see with the buttons.** Chips still advance the step. Denied or missing camera falls back to the diagram. No object detection and no “found the part” boxes.

## Prior workmanship inspect hooks 0.2.2 (2026-08-19)

Washer `washer-core` **0.2.2** adds a look-only inspect chain on drain-hose **not seated** (and hose-run on the kinked-drain mode): standpipe seating, then stuffed/disconnected hose. Ranking still uses the existing leak and drain-hose templates. Dishwasher `dishwasher-core` **0.2.2** names leftover disposal knockout on the existing high-loop / air-gap inspect. No HVAC/AC package and no mains-wiring how-to. Fridge and dryer versions are unchanged.

## Washer and dishwasher inspect steps 0.2.1 (2026-08-19)

Washer `washer-core` **0.2.1** adds a won’t-drain inspect chain (door latch, then visible coin trap / drain filter) before opening the filter. Dishwasher `dishwasher-core` **0.2.1** adds filter/sump, door latch, then drain-hose / high-loop / air-gap look-only inspect on won’t-drain and standing-water drain modes. Chips write the existing easy-check templates. Ranking is unchanged. Dryer and fridge packages are unchanged.

## Dryer inspect steps 1.4.1 (2026-08-19)

Dryer `dryer-core` **1.4.1** adds an inspect chain on no-heat / long-dry / overheat modes: lint filter mesh, outside vent hood (stand clear), then visible flexible hose. Chips still write the existing airflow templates. Ranking is unchanged. Washer, fridge, and dishwasher packages are unchanged.

## Fridge package v1 (2026-08-19)

Fridge `fridge-core` **1.0.0** covers eight starter paths (not cooling, fridge warm/freezer cold, too cold, leak, ice maker, noisy, door, won’t run) with observational easy checks first. Guidance never covers refrigerant, sealed-system work, compressor live diagnostics, or piercing lines. Dryer, washer, and dishwasher packages are unchanged.

## Washer and dishwasher primary-path bar (2026-08-19)

Washer `washer-core` **0.2.0** and dishwasher `dishwasher-core` **0.2.0** now follow the dryer easy-checks-first pattern on their primary real-world paths (drain, fill, spin/start, leak, door / poor clean). Fridge stays `0.1.0`. Dryer ranking and `dryer-core` **1.4.0** are unchanged.

## Launcher icon (2026-08-19)

Home-screen and Android cold-start use the existing Butler mark (`assets/brand/app_icon.png`) instead of the default Flutter logo. Rebuild the APK to see it on a device. No iOS project is configured yet.

## Show me where copy (2026-08-19)

Show me where and camera/mic help talk about a **typical location — yours may vary.** They do not say the camera diagnoses, that a pin is exact, or that beginners should do live electrical, gas, or sealed-system work. Conclusion copy names the most likely cause; live-electrical tools are labeled **Not for beginner steps**.

## Chip-only repair without camera or mic (2026-08-19)

Scan, photo, and voice hide after a deny, when the hardware is missing, or when **Simulate camera & microphone denied** is on. Typed brand/model and answer chips still finish a repair. Show me where keeps the diagram; **Use camera** stays off. Diagnosis is never blocked.

## Continue repair landing (2026-08-19)

Leaving mid-guidance, after tools are marked, or on **Most likely** before **I'll repair** still restores the same session. Continue repair returns to the first incomplete Safe Guidance step, keeps completed observations and **I did this** steps, opens step 1 when tools are done but guidance has not started, and stays on the conclusion / I'll-repair choice until that is chosen. A missing saved question does not blank the session.

## Dishwasher repair history summaries (2026-08-19)

Fixed/verified outcomes on dryer, washer, and dishwasher still append **Repair history** (newest first; in-progress stays off the list). Dishwasher starter answers (`dishwasher-complaint`) are stored as the history symptom, and dishwasher paths use short labels (tub filter, drain hose, door latch, spray arms).

## Already checked on easy checks (2026-08-19)

Dryer filter/vent/airflow, washer door/filter, and dishwasher door/filter/hose questions offer **Already checked** next to **Not sure**. Safe Guidance easy steps offer **I already did this**. Both count for gating the same as **I did this**. **I couldn't** stays. Maintenance dates do not auto-skip.

## Blocking reason line (2026-08-19)

When a required tool is missing, an easy check is still open, or a safety stop is on, the session shows one calm sentence (what is blocked and what to do next), for example **Next: check outside vent before opening the cabinet.** or **You need a screwdriver for the next steps.** It replaces the generic next-step cue and clears when the gate opens.

## Parts & cost on the selected path (2026-08-19)

Close-path, recommended, Record outcome, and Done use the same path filter: replace/seat rows for this leader only. Lint-filter, vent-kit, and drain-trap purchase lines stay off cleaning/restriction paths. Helper copy is still **Estimates only. Not a quote.**

## Parts & cost on outcome (2026-08-19)

Record outcome and Done only list cost rows for parts the leading close path actually replaces. Vent/restriction cleaning paths hide lint-filter and vent-kit purchase lines. Helper copy is **Estimates only. Not a quote.**

## Household tools persist (2026-08-19)

Adding or removing a tool from the repair checklist or Tools screen writes household tool memory immediately, and that list is restored even if the larger local snapshot is stale. Owned tools stay after leaving the screen and after a restart, and the next repair checklist pre-marks them.

## Lint filter Show me where (2026-08-19)

Dryer lint filter is a static schematic plus **Typical dryer lint filter at the door opening — a pull-out mesh. Yours may vary.** No fixed highlight box on live or stock imagery. Washer and dishwasher never reuse dryer lint-filter anchors. Camera still never diagnoses.

## Version visibility (2026-08-18)

Settings **About** shows **App 0.1.0+1**. Package manager and About list installed guide ids and versions (`dryer-core 1.4.0`, `washer-core 0.1.0`, `fridge-core 0.1.0`, `dishwasher-core 0.1.0`) so screenshots can cite the UI. Same labels as `docs/qa/PACKAGE_INVENTORY.md`. Click path: `docs/qa/VERSIONS.md`.


## Permission denied still completes repair (2026-08-18)

Camera, microphone, scan, and OCR are optional. After a deny (or **Settings → Demo → Simulate camera & microphone denied** on Chrome), those controls hide. Diagram, typed brand/model, and answer chips still reach a dryer conclusion. Manual path: `docs/qa/PERMISSIONS_DENIED.md`.


## Backup export/restore smoke (2026-08-18)

Local household backup already round-trips appliances, tools, maintenance, and repair history. Invalid files keep current data and show a calm message. Chrome export may use the share sheet or clipboard instead of a Downloads file. Steps: `docs/qa/BACKUP_SMOKE.md`. Tests: `test/local_backup_test.dart`.

## Golden path labels freeze (2026-08-18)

Exact chrome for dryer no-heat + drum turns and washer won’t-drain is listed in `docs/qa/GOLDEN_LABELS.md`. `test/golden_labels_test.dart` asserts the easy-check prompts, tool row names, and first guidance titles against the live helpers.

## Sample home reset reliability (2026-08-18)

**Load sample home** seeds a Whirlpool WED5000DW dryer and WTW5000DW washer. **Reset sample data** restores that canned home, or does nothing if sample was never loaded (no crash, including double-reset). **Clear open session** is always tappable: no **Continue repair**, no leftover guidance, no crash when nothing is open. **Include sample open session** only adds the dryer Continue-repair sample when it is on. Click path: `docs/qa/DEMO_RESET.md`.

Files: `lib/helpers/demo_sample_home.dart`, `lib/ui/app_dependencies.dart`, `lib/ui/settings_screen.dart`, `test/demo_mode_test.dart`, `docs/qa/DEMO_RESET.md`.


## Already checked on easy checks (2026-08-18)

Dryer airflow and washer door/filter easy checks offer **Already checked**. That mark counts for the easy-check gate the same as a normal answer or **I did this**. **Not sure** and **I couldn't** stay available. Invasive steps stay locked until the easy checks are answered, already-checked, done, or skipped. Maintenance dates do not auto-skip. Ranking is unchanged.

Files: `lib/helpers/easy_check_already_checked.dart`, `lib/helpers/evidence_prompt_match.dart`, `lib/ui/session_screen.dart`, `test/easy_check_already_checked_test.dart`, `test/easy_airflow_checks_test.dart`, `test/washer_easy_checks_test.dart`.


## Appliance Repair history (completed only) (2026-08-18)

Marking a repair **Fixed** (or another completed outcome) appends a row on the appliance **Repair history**: date plus a short plain summary. In-progress sessions are not listed. Newest first. **No repairs yet** only when this appliance has no completed outcomes.

Files: `lib/ui/app_dependencies.dart`, `lib/ui/appliance_detail_screen.dart`, `test/appliance_detail_test.dart`.

## Guidance progress on the repair session (2026-08-18)

**I did this** writes `guidanceStepIndex` and `completedGuidanceStepIds` onto the local repair session (and existing UI resume). **Continue repair** restores the first incomplete Safe Guidance step. Observation evidence is unchanged on resume. SharedPreferences only — no cloud.

Files: `lib/models/repair_session.dart`, `lib/services/repair_session_repository.dart`, `lib/services/local_domain_store.dart`, `lib/ui/app_dependencies.dart`, `lib/ui/session_screen.dart`, `test/session_resume_test.dart`.

## Easy-checks-first on no-heat / long-dry / overheat (2026-08-18)

On those dryer paths only, next steps put lint filter → outside vent → visible hose before panel or replace-part work, even when conclusion still names a part. Invasive steps stay locked until those three checks are answered or skipped (**I couldn't**). Won't-start / door paths are unchanged. Ranking is unchanged.

Files: `lib/helpers/easy_airflow_checks.dart`, `lib/helpers/suggest_next_observation.dart`, `lib/ui/session_screen.dart`, `test/easy_airflow_checks_test.dart`.

## Tools inventory on repair checklist (2026-08-18)

Owned household tools pre-mark the repair checklist as **I have this** (with an **In your tools** caption). The checklist still shows so the user can change a mark. **I don't** on a required tool still blocks panel/invasive steps. Marking **I have this** does not write inventory; **Also save to my tools** is the explicit add.

Files: `lib/ui/session_screen.dart`, `lib/ui/app_dependencies.dart`, `lib/ui/tools_inventory_screen.dart`, `test/tools_inventory_test.dart`, `test/repair_readiness_test.dart`, `test/support/session_test_helpers.dart`.

## Add-appliance copy + scan affordance (2026-08-18)

Web Add appliance shows one hint: type brand and model here; rating-plate scan is phone-only when this platform has no scan control. **Scan rating plate** appears only when OCR or barcode reading actually exists. No OCR promise without that control. Manual entry still works.

Files: `lib/helpers/add_appliance_scan_copy.dart`, `lib/helpers/user_facing_error.dart`, `lib/ui/add_appliance_screen.dart`, `lib/ui/appliance_detail_screen.dart`, `test/add_appliance_copy_test.dart`, `test/ocr_model_label_test.dart`, `test/barcode_assist_test.dart`.

## Maintenance due / next-due copy (2026-08-18)

Reminder rows show last done (when it exists) and next due whenever an interval is stored, plus **About every N days**. Checking Done stamps last done as today and rolls next due by that interval. Past due uses a calm **Overdue** suffix on the next-due line. No push notifications. No new reminder engine.

Files: `lib/helpers/maintenance_reminder_copy.dart`, `lib/models/maintenance_reminder.dart`, `lib/ui/maintenance_list.dart`, `lib/ui/app_dependencies.dart`, `lib/ui/appliance_detail_screen.dart`, `lib/ui/home_screen.dart`, `lib/ui/session_completion_screen.dart`, `test/maintenance_list_test.dart`.

## Repair history on appliance (2026-08-18)

Appliance Repair history lists completed sessions newest first with a short plain-language line, the date, and optional stored cause. In-progress repairs stay off the list. Empty copy is only shown when this appliance has no completed outcomes.

Files: `lib/helpers/repair_history_display.dart`, `lib/ui/appliance_detail_screen.dart`, `lib/ui/app_dependencies.dart`, `test/repair_history_display_test.dart`, `test/appliance_detail_test.dart`.

## Guidance step completion + resume (2026-08-18)

Continue repair returns to the first incomplete Safe Guidance step. **I did this** records the step id and index; completed steps stay completed after leave, app kill, or navigate away. Guidance not started still lands on conclusion/decision. Answered observation chips are not re-asked unless the session is restarted.

Files: `lib/helpers/close_path_phase.dart`, `lib/ui/session_screen.dart`, `lib/models/session_ui_resume_state.dart`, `test/close_path_step_flow_test.dart`, `test/session_resume_test.dart`.

## Easy-checks-first for dryer (2026-08-18)

On no-heat / long-dry / overheat paths, lint filter → outside vent hood → visible vent hose come before panel or replace-part guidance. Invasive steps stay locked until those checks are answered, done, or skipped with **I couldn't**. Copy: “This can be a failed part. It can also be restricted airflow. Check [easy thing] before opening the cabinet.”

Files: `lib/helpers/easy_airflow_checks.dart`, `lib/helpers/suggest_next_observation.dart`, `lib/helpers/close_path_phase.dart` (existing invasive helper), `lib/ui/session_screen.dart`, `lib/helpers/dryer_close_path.dart`, `lib/knowledge_factory/dryer_batch_01.dart`, `lib/services/knowledge_package_repository.dart`, `lib/helpers/guidance_display.dart`, `lib/helpers/dryer_problem_starter.dart`, `lib/helpers/observation_prompt_quality.dart`.

## Repair UX density + step completion (2026-08-18)

Stepped close-path so a dryer no-heat run is usable on web without one scroll wall.

### Screens / flow
- **Conclusion** — most likely + why; other possibilities collapsed
- **Decision** — I'll repair | Call a pro
- **Parts** — estimates only (no DIY vs pro CTAs)
- **Tools** — compact required/optional checklist; missing required tool blocks panel/parts steps
- **Guidance** — one step per screen with Step X of N, **I did this**, **I couldn't**, Back
- **Verification** — after guidance steps are confirmed
- **While you're there** — optional extras
- **Done** — End Session + household memory / maintenance due copy

### Session fields added (`SessionUiResumeState`)
- `closePathPhase`
- `choseRepair`
- `guidanceStepIndex`
- `completedGuidanceStepIds`

Resume returns to the last incomplete guidance step.

### Copy
- Vent/outside-airflow questions framed early on no-heat / long-dry / overheat paths
- Web appliance identity: “Type brand and model here.”
- Diagram caption: typical layout, yours may vary
- Done screen shows typical 30-day interval / next due
