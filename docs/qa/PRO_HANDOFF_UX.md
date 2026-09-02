# Pro handoff UX (dryer no-heat / no-warmth)

## Safety handoff follow-up — 0.1.4+8

Presentation/honesty only. Do not reopen leftover PRs #1–#6 or John’s #15 / #16
nits. Play listing stays out. Groq stays phrasing-only. No new engine, chips,
question ids, or failure modes. GOLDEN **Call a pro** stays.

1. **Unbundled fire Yes.** Dryer `hazard-observation` asks **Do you observe a burning smell or smoke?** only. Repeated stopping does not share that Yes. Fire/smoke Yes remains a hard stop.
2. **Symptom on a safety stop.** Mid-session hazard Yes writes **Burning smell / smoke** as Symptom. Empty starter no longer prints **—** / **not recorded**.
3. **Leftover leader.** On a hard stop the prior ranking leader is labeled **Leftover (not why we stopped):** and is not the headline reason. `whyStopping` stays the hazard / Needs a professional reason.

Tests: `test/safety_handoff_followup_test.dart`.

## Safety handoff honesty — 0.1.4+6

`alreadyTried` is what this session recorded (completed inspect / Safe
Guidance + those evidence rows). If none, **None recorded.** Never copy the
unused close-path checklist for the ranking leader. On a fire/smoke stop,
`whyStopping` is the safety-stop reason (hazard / Needs a professional), not
the vent path’s “simple exhaust restriction” why. A leftover ranking leader
is labeled leftover in 0.1.4+8 — it is not why we stopped. Spoken/read-aloud
uses the same lists, including the safety why on a fire/smoke stop. Groq may
phrase the why; it may not invent tried steps or drop Needs a professional /
fire or smoke. GOLDEN **Call a pro** and NATURAL_UI_V1 handoff chrome stay.
Play listing stays out.

Inspect stays **LOOK FOR + chips**. Camera, AR, and “show me where” stay off unless a step has authored inspect text **and** flashlight camera is explicitly offered. The camera never writes diagnostic evidence.

When the package marks a path as pro-required (or DIY cannot finish), show **A full fix likely needs a pro** before numbered Safe Guidance. **Do safe checks** continues to easy checks first. **End session** records professional service.

Numbered steps are safe checks only. They are not a DIY repair toward a finished fix.

After the last safe check, the outcome is **Pro recommended** (not “Step N of N Safe Guidance”):

- Why we’re stopping (from the path / safety gate)
- What was already observed
- What to tell a technician
- Safe checks already done
- **I understand — end session** / **I couldn’t**

Dryer no-heat examples: `thermal-fuse-open`, `heating-element-failed`. Easy airflow checks stay first. No beginner live electrical procedures.
