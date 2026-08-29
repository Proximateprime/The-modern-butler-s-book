# Permissions and blocking UX (P1-17)

Camera and microphone are optional. Chip + text still finish a dryer repair if they are denied on **first launch**. When a close-path gate is on (missing tool, incomplete look, safety), the session shows **one calm line**: what is blocked and what to do next. That line **goes away** when the gate is cleared.

Read from code on **2026-08-22**. Tests: `test/permissions_denied_path_test.dart`, `test/repair_readiness_test.dart`, `test/blocking_reason_test.dart`, `test/inspect_step_test.dart` (denied inspect chips), `test/safety_stop_ui_test.dart`. Copy: `lib/helpers/blocking_reason.dart`. Chrome: [`GOLDEN_LABELS.md`](GOLDEN_LABELS.md). First-run slides: [`FIRST_RUN.md`](FIRST_RUN.md). Inspect text: [`INSPECT_TEXT_PATH.md`](INSPECT_TEXT_PATH.md).

---

## 1. Deny camera on first launch

First-run **never** asks for camera or microphone. Repair can start without granting either.

### Phone (OS deny)

1. Fresh install (or clear app storage). Launch.
2. **Skip** or three slides → **Get started**. Disclaimer → **I understand**. Home.
3. If an OS camera prompt appears later (add-appliance scan, Gallery/Camera on a question, **Use camera while I look**), tap **Don’t allow** / **Deny**.
4. Banner: camera denied. Scan / Gallery / Camera / inspect camera **hide**. Chips and typed brand/model stay.

### Chrome / emulator without an OS dialog

1. After Home: Settings (gear) → **Demo** → **Simulate camera & microphone denied**.
2. Same hide behavior as a real deny.

Pass: you can reach Home and start a dryer repair without ever granting camera.

---

## 2. Dryer chip + text path (no camera)

Use sample **Laundry Room Dryer** ([`DEMO_RESET.md`](DEMO_RESET.md), sample open session **off**) **or** **Add dryer** with typed brand/model.

1. **Start repair**. **What's going on?** → **No heat** → **Confirm and continue**.
2. Answer **only chips** (or inspect **Matches / OK** / **Doesn't match / Not OK** / **Can't see** / **Already checked**). Do **not** tap Camera, Gallery, mic, or **Use camera while I look**.
   - Drum: **Turns normally**
   - Lint / hood / hose inspect if shown: chips (text LOOK FOR is enough)
   - Heat cycle: **Yes, heat cycle**
   - Recent overheat: **No**
   - Clothes: **Cold and still damp**
3. **Most likely** → **Continue** → **I'll repair**.
4. Parts if shown → **Continue**. Inspect close-path skipped if those templates were already chipped.
5. **Tools** if shown — see §3. Then **Safe Guidance** **I did this**. Verification → **End session**.

Pass: conclusion + **Fixed** (or end session) with camera still denied. No spinner, crash, or “enable camera to continue.” Ranking is unchanged. Camera never diagnoses.

---

## 3. Missing-tool gate — one line

Washer **Won't drain** → **Clogged drain filter** is the easy Required-tool example (**Shallow pan and towel**).

1. Add washer or sample washer → **Start repair** → **Won't drain** → clogged drain-filter leader → **I'll repair**.
2. Chip inspect if shown.
3. **Tools**: mark **I don’t** on **Shallow pan and towel**. Mark flashlight either way (optional).
4. One line (`blocking-reason-line`): **You need a shallow pan and towel for the next steps.**
5. The generic next-step cue is **not** shown at the same time. Invasive copy (**Open only the user-accessible filter**) stays hidden.
6. Panel offers **Stop**, **Call a pro**, and **Continue with caution** (non-live-electrical tools only).

### Clears when resolved

Tap **I have** on the pan (and any other Required rows). The “You need…” line **disappears**. **Continue** appears. Guidance looks stay first; the filter still does not open on step 1.

Unmarked rows (neither I have nor I don’t) use: **Mark I have or I don’t for each tool to continue.** That line also clears once every row is marked and none required are missing.

---

## 4. Other gates (same one-line pattern)

| Gate | Line (exact) |
|---|---|
| Safety hard-stop | `This step is blocked for safety — Needs a professional.` |
| Incomplete inspect | `Finish this look before opening a panel or pulling the appliance out.` |
| Dryer easy airflow | `Next: check the lint filter before opening the cabinet.` (or outside vent / visible hose) |
| Missing required tool | `You need a … for the next steps.` |

When the gate is done (look chipped, tools marked, not a safety stop), the line is gone. **I did this** on an easy look is enough to drop the airflow/easy-check line.

---

## Fail if

- First-run or Home requires camera or microphone.
- Denied camera blocks chips, typed model, inspect LOOK FOR, or **Fixed**.
- Two competing “why you’re stuck” banners, or a stack trace.
- Missing Required tool still unlocks opening the filter / a panel.
- The blocking line stays after **I have** on every Required tool (and inspect is complete).
