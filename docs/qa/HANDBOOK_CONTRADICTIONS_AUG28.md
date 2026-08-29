# Handbook / package contradictions — 2026-08-28

Visual QA findings vs Safety Invariants. No new modules. Ranking math not rewritten (extra exclude counts only on fuel).

## P0

| Finding | Change |
|---|---|
| 1. Dryer add/setup did not capture energy source | `Appliance.energySource` (`electric` / `gas` / `unknown`). Add-dryer chips. JSON persist. Resume and new sessions seed `gas-dryer-type` when known. Missing JSON → unknown. |
| 2. Gas / unknown + heat started electric element / fuse-as-element | Unknown + no-heat / weak heat: first question **Is this dryer gas or electric?** Gas: extra exclude on electric heat-generation modes (including thermal fuse as default element path). No burner/ignition interview. Safe checks remain vent / door / controls; heat generation → professional mode. |
| 3. Burning smell treated as ordinary interview | Primary chip **Burning smell / smoke**. Starter answer still contains hazard keywords so `evaluateSafetyStop` fires immediately. Voice hazard records Yes and stops. Comment on `evaluateSafetyStop`: **Safety Invariants > symptom seeding**. |

## P1

| Finding | Change |
|---|---|
| 4. Fake precision % during questions | Questions still have no standing chrome. Conclusion phrases are High / Medium / Low plus short language. Internal integer scores unchanged. |
| 5. Household Memory called premium / absent | In-app history was already MVP. First-run copy + engineering-decisions premium list: local House Book history is MVP; cloud sync can be premium. |
| 6. Demo / first-run vs code golden path | One path: **No heat + drum turns** (not clothes-not-drying first). Sample open session is no-heat; sample dryer is electric. |
| 7. Dryer “lid” | Seed dryer checks say **door**. Washer may still say door or lid. Test: `door-closed-firmly` has door, not lid. |

## P2

| Finding | Change |
|---|---|
| 8. Word lockfiles `~$*` | None in this repo. |
| 9. GitHub Pages / broken index links | No GitHub Pages config or `github.io` links in-repo. `web/index.html` is Flutter bootstrap only. Do not deploy Pages until a real index exists. |

## Tests

`test/handbook_contradictions_aug28_test.dart` — unknown energy + heat asks fuel first; gas + no heat does not lead heating element; burning smell safety stop; door wording; energy persists after restore.

## Decision ledger (spec-silent, least confident first)

1. **Thermal fuse extra-exclude on gas** — User forbade fuse-as-default-element on gas. Fuse still exists on some gas dryers; we weaken it as a *primary electric-heat* story rather than deleting the mode. Confidence: medium.
2. **Hide `gas-ignition-observed` for everyone** — Looking at a flame is not DIY repair, but the pack asked only vent / door / controls. Hiding burner observation avoids gas-train curiosity. Confidence: medium-low.
3. **Interview fuel answer writes back to the appliance** — Spec required persist on add/setup; writing Electric/Gas from the in-session question prevents re-asking on resume. Confidence: medium-high.
4. **Default add-dryer chip is Not sure** — Existing save tests stay valid; electric golden-path tests answer fuel when it appears. Confidence: high.
