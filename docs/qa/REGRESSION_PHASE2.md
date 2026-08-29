# Phase 2 regression kit

Phase 2 features on top of the Phase 1 walk. **Do Phase 1 first:** [`REGRESSION_PHASE1.md`](REGRESSION_PHASE1.md) (dryer, washer, DW, export, tools, resume, offline). Phone chrome for those three appliances: [`REGRESSION_PHONE.md`](REGRESSION_PHONE.md).

**App 0.1.0+1** · Candidate APK: [`BUILD_NOTES_PHASE2.md`](BUILD_NOTES_PHASE2.md). Packages: dryer-core **1.4.1**, washer-core **0.2.3**, dishwasher-core **0.2.3**, fridge-core **1.0.1**.

**Do not file** [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md). No Phase 3 (no live AR, no public knowledge platform, no ranking rewrite, no Store checkout). Camera never diagnoses. No beginner live electrical, gas, or refrigerant DIY.

```bash
flutter run
```

Phone or emulator. Chrome is fine for chips, outcome fields, Why ask this, tools readiness, pattern hint, and **Household Pro (debug)**.

---

## Shared Phase 2 chrome

| Role | Exact label |
|---|---|
| Explain | `Why ask this?` (expand on the current interview / inspect card) |
| Standing (when shown) | `More of your answers match this than the other possibilities` — **no `%`** |
| Tools row | `In your tools` if owned · `Not in your tools` if required and missing |
| Missing required | `Get this tool first` · `Stop` · `Call a professional` · optional `Exterior checks only` |
| Fixed memory | `What failed` · `Root cause not sure` · `Contributing factors` · `Prevention` · `Update maintenance schedule` |
| History extras | `Prevent:` · `Also:` · `by` person name when members exist |
| Pattern hint | `From your household history` · `Dismiss` |
| Pro-only warning | `A full fix likely needs a pro` (conclusion **and** guidance) |
| Pro-only parts | `Pro ~ $…` only — no `DIY ~`, no `I'll repair` |
| Pro debug | Settings `Household Pro (debug)` — **debug builds only** |

No generated inspect pictures. Ranking algorithm unchanged.

---

## H. Why ask this? (explainability)

1. Sample dryer → **Start repair** → `What's going on?` → `No heat`.
2. On **Look at the lint filter** (or the first interview card): expand `Why ask this?`.
3. Body names a **split** (packed lint screen vs failed heater), not a percent and not a ranking dump. Lint-filter authored line starts `A packed lint screen and a failed heater`.

Pass: the tile exists on the current question; camera is not required; expanding it does not change chips or ranking.

---

## I. Outcome fields (Fixed memory)

Use a **DIY-completable** path (sample dryer no-heat with easy airflow **Matches / OK**, or washer won’t-drain with a pan). Not thermal-fuse **Needs professional**.

1. Finish **Safe Guidance** → `Confirmed` → **End Session — Ready to resolve** → `Fixed — problem resolved`.
2. **What failed** shows guide wording. Leave it, or tap `Root cause not sure` (stores **no** invented root cause).
3. Confirm or turn off **Contributing factors** / **Prevention** chips. Optional `Update maintenance schedule` (local reminder only).
4. `Save to household memory` → **Save & go home**.
5. Appliance **Repair history**: top row `YYYY-MM-DD · Fixed` plus `Prevent:` when prevention was saved.

Pass: one new history row; in-progress is not a row; **Root cause not sure** does not invent a cause. Details: [`REPAIR_HISTORY.md`](REPAIR_HISTORY.md).

Calling a professional still shares a technician handoff. Root-cause chips are **Fixed-only** (expected — not a Phase 3 “community learning” loop).

---

## J. Repair readiness (inventory is source of truth)

1. Home wrench **Tools**. **Remove** `Shallow pan and towel` if present (or skip add).
2. Washer **Start repair** → `Won't drain` → **I'll repair** on the drain-filter path.
3. **Tools**: pan row `Required` and `Not in your tools`. `I don't` must not unlock opening the filter. Line still `You need a shallow pan and towel for the next steps.`
4. Home **Tools** → add `Shallow pan and towel` (or **Also save to my tools** on the row). Return to the repair: pan shows `In your tools`.

Pass: missing ↔ owned follows the household list, not a one-time copy at session start. [`TOOLS_INVENTORY.md`](TOOLS_INVENTORY.md).

---

## K. History pattern hint

Sample home **must not** show `From your household history` (canned closes are thermal-fuse / dusty-lint, excluded from DIY hints).

1. On a **new** washer (not sample), complete **two** verified **Fixed** drain-filter (or drain-path) repairs, **or** one Fixed plus a matching maintenance note.
2. Open that washer: card `From your household history` about drain-filter / drain-path. `Dismiss` hides it. Kill/reopen: stays dismissed.
3. One Fixed only: **no** card.

Pass: N=2, on-device, dismissible, not ranking. Thermal-fuse history never becomes a vent hint.

---

## L. Pro-only honesty (thermal fuse)

1. Sample dryer → **Start repair** → `No heat`. Answer so the leader lands on a **thermal fuse** / heater path (heat cycle **Yes**, drum **Turns normally**, no warmth, airflow looks **Matches / OK**).
2. On **Most likely**: card `A full fix likely needs a pro` appears **here**, before you choose anything.
3. **Continue** → **I'll repair**. **Parts & cost** shows `Pro ~ $…` only. There is **no** `DIY ~` price and **no** `I'll repair` button on that card.
4. Guidance: `A full fix likely needs a pro` → `Do safe checks`. Safe checks are numbered; the "call a technician" line is **not** a numbered step and has no `I did this`.
5. Finish the checks → pro handoff → **End Session**. Outcome is `Calling a professional`; **Fixed** is not offered.
6. Handoff text has `Why we're stopping`, `What to tell a technician`, `What we noticed`, `Safety notes`.

Pass: you learn it is a pro job before gathering anything, and you are never quoted a DIY price for it.

---

## Optional (not required to pass the kit)

| Check | Script |
|---|---|
| Fridge observational | Add Fridge → [`FRIDGE_PATHS.md`](FRIDGE_PATHS.md). Hard stop: no refrigerant / sealed-system / compressor live DIY. |
| Extra home / person | Profiles: **Add home** / **Add person**. Same House Book for people in one home. |
| Household Pro debug | Settings toggle only. Repair and safety stops still work **off**. Extra inventory lines **on**. [`MONETIZATION_HOOK.md`](MONETIZATION_HOOK.md). No Buy button. |

---

## Kit pass / fail

**Pass if** Phase 1 kit still passes **and** §H–J pass. §K pass if you walk a second Fixed on a non-sample washer; skip §K if you only used sample home (then note “pattern hint not exercised”).

**Fail if:** `Why ask this?` missing on no-heat lint look; Fixed history has no prevention when chips were left on; `%` on standing copy; required tool `In your tools` when it is not on **Tools**; sample dryer shows a pattern hint; live AR / CV; beginner refrigerant how-to.
