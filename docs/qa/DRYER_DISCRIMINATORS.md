# Dryer questionnaire discriminators (P1-04)

Read from the repo on **2026-08-20**. Lists the **top starter families** and the **observation questions** that split competing modes. Ranking still uses package `supportByAnswer` / `excludeByAnswer` (and authored batch hints). This is not a new ranker.

Rules this slice follows:

1. Prompts are see / hear / smell / feel (or a look at a setting or light). They do not ask “is the thermal fuse bad?”
2. Chips argue **for** one family and **against** another where the evidence model already allows it.
3. Easy non-invasive checks run before panel / teardown on gated modes.
4. **Already checked** is offered on easy-check interview templates. Inspect LOOK FOR steps also offer **Can't see**.
5. No beginner live-electrical meter how-to (no voltage/ohm procedures). Outlet/breaker is look-only.

Interview wiring: `lib/helpers/suggest_next_observation.dart`, `lib/helpers/easy_airflow_checks.dart`, `lib/helpers/dryer_start_easy_checks.dart`, `lib/helpers/easy_check_already_checked.dart`. Templates live in `lib/services/knowledge_package_repository.dart` plus Batch 01/02 first-line questions.

---

## Starter chips → first template

| Chip | Family id | First interview template | Why this first |
|---|---|---|---|
| **No heat** | `no-heat` | Airflow chain (`lint-filter-condition`) via heat polarity, not a warmth re-ask | Filter / hood / hose before fuse vs element talk |
| **Takes too long to dry** | `long-dry-time` | Same airflow chain | Restriction vs no-heat |
| **Won't start** | `will-not-start` | `dryer-response` | What you see/hear on Start |
| **Drum doesn't turn** | `motor-runs-drum-still` | `drum-turns` | Belt vs motor vs “it does turn” |
| **Too hot or overheating** | `dryer-very-hot` | Airflow chain | Restriction vs stuck-closed heat |
| **Unusual noise** / **Burning smell / smoke** | unusual-noise vs hazard | `running-noise` / safety stop | Burning smell is not a normal chip |
| **Other** | free text | mapped family or clarify list | Keywords only |

Family `firstTemplateId` for no-heat is still `cycle-heat-setting` in `dryer_problem_starter.dart`; `starterInterviewTemplate` replaces it with the next unused discriminator (airflow first).

---

## No heat

**Competing modes (typical):** restricted exhaust / clogged lint vs heating element vs thermal fuse vs air-only cycle vs supply/plug.

**Order that matters**

1. Easy airflow (non-invasive): `lint-filter-condition` → `exterior-airflow` → `vent-hose-condition`
2. Drum: `drum-turns` (no-heat with a turning drum is not belt/motor)
3. Feel / history: `clothes-feel-after-cycle`, `recent-overheat`, `heat-before-failure`
4. Setting: `cycle-heat-setting` (look at the dial — heat vs air-only / fluff)

| Template | Observation asked | Discriminating chips (for / against) |
|---|---|---|
| `lint-filter-condition` | Look at the lint screen | **Heavily clogged** supports lint pathway / restriction / fuse-from-overheat. Clean does **not** clear a packed housing. |
| `exterior-airflow` | Feel/see air at the outside hood while it runs | **Weak / Almost none** supports restriction (and fuse-from-vent). **Normal** excludes restriction + fuse-from-overheat and supports element. |
| `vent-hose-condition` | Look at the visible hose | **Yes, restricted** vs **Looks clear** |
| `drum-turns` | Watch the drum | **Turns normally** excludes belt, motor, dead outlet. |
| `clothes-feel-after-cycle` | Feel the load | **Cold and still damp** supports element / fuse / supply; excludes restriction. **Warm or hot but still damp** supports restriction; excludes element/fuse/supply. |
| `recent-overheat` | Felt too hot or shut off from heat on a recent run | **Yes** supports fuse + restriction. **No** excludes fuse. |
| `heat-before-failure` | Did it still heat on a heat cycle before this complaint? | **Never heated / always cold** supports element; excludes fuse. **Heated, then went cold after a very hot run or vent issue** supports fuse; excludes element. |
| `cycle-heat-setting` | Look at cycle (heat vs air-only) | **No, air-only / fluff** excludes element and fuse. |

Gating: airflow-before-parts on 12 heat/vent modes (`dryerEasyAirflowBeforePartsModeIds`). Inspect LOOK FOR uses **Can't see** + **Already checked**.

---

## Long dry time

**Competing modes:** restriction / lint vs no-heat (element/fuse) vs oversized load (later templates).

Same **easy airflow** order as no heat. Key extra discriminator:

| Template | Observation asked | Discriminating chips |
|---|---|---|
| `clothes-feel-after-cycle` | Feel after a full cycle | **Warm or hot but still damp** → airflow restriction. **Cold and still damp** → no-heat family, not a blocked vent. |
| `dry-time-change` | Notice if cycles got longer | Supports restriction when time stretched with heat still present. |

Do not skip lint → hood → hose before panel steps on the gated heat/vent modes.

---

## Won't start

**Competing modes:** door switch vs control lock vs no power at outlet vs motor vs start control.

**Interview after starter `dryer-response`**, easy-check order (`dryerWontStartEasyCheckOrder`):

1. `door-closed-firmly`
2. `panel-lights`
3. `control-lock-status`
4. `outlet-power-check`
5. `door-held-closed-start`

| Template | Observation asked | Discriminating chips |
|---|---|---|
| `dryer-response` | What happens when you press Start? | **Nothing happens** supports door switch. **Hums but does not start** supports motor. **Starts normally** excludes door switch, motor, supply, dead outlet. |
| `door-closed-firmly` | Feel/hear a firm click | **Soft close / no click** or **Will not stay closed** supports door switch. A firm click does **not** prove the switch is good. |
| `panel-lights` | See lights / display | **Yes, panel responds** supports door switch; excludes dead outlet / supply. **No lights at all** supports supply; excludes door switch. |
| `control-lock-status` | Look for a lock icon or Control Lock / Child Lock light | **Lock on** vs **Lock off / not shown** (authored `control-lock-engaged`). |
| `outlet-power-check` | Look at outlet / breaker — **no meter, no outlet teardown** | **Outlet appears dead / breaker tripped** supports `no-power-at-outlet`. **Other nearby power looks normal; dryer still dead** argues against a dead house outlet. |
| `door-held-closed-start` | Hold door closed and press Start | **Starts only while I hold the door closed** supports door switch. **Starts normally without holding** excludes it. |

Gated start modes (`dryerStartEasyChecksBeforeRepairModeIds`): `door-switch-failure`, `control-lock-engaged`, `no-power-at-outlet`, plus tumble modes below.

**Already checked** is on these easy-check template ids. Guidance steps that mention door click / control lock / visual breaker also get **I already did this**.

---

## Drum doesn't turn (no tumble)

**Competing modes:** broken belt vs motor vs door not actually running.

| Template | Observation asked | Discriminating chips |
|---|---|---|
| `drum-turns` | Watch the drum | **Motor runs, drum still** supports belt; **excludes** motor failure. **Does not turn** supports belt **or** motor. **Turns normally** excludes belt and motor. |
| `motor-audible` | Listen while it tries to run | **Yes, clear motor sound** supports belt; excludes motor and door-switch silence. **Hum / struggle only** supports motor; excludes belt. **Silent — no motor sound** excludes belt; supports door switch or motor. |

Easy-check order after this family: `motor-audible` (`dryerNoTumbleEasyCheckOrder`).

---

## Already checked / Can't see

| Surface | Labels | Where |
|---|---|---|
| Easy-check **interview** (airflow + start/tumble templates in `easyCheckObservationTemplateIds`) | **Already checked** inserted before Not sure / Other | `withAlreadyCheckedEasyCheckChoice` |
| **Inspect** LOOK FOR (lint / hood / hose on gated heat modes; washer/DW inspect) | **Matches / OK** · **Doesn't match** · **Can't see** · **Already checked** | `InspectStepCard` |
| **Safe Guidance** easy-check steps | **I already did this** | `isEasyCheckGuidanceStep` |

Interview **Not sure** is not the same chip as inspect **Can't see**. Do not merge those labels.

---

## What we did not add

- Beginner multimeter / live voltage / ohm steps.
- Questions that name a failed part as the observation (“is the thermal fuse open?”).
- Ranking algorithm changes. Chips only write existing evidence answers.
- Inspect LOOK FOR authoring for door/lock/outlet (those stay interview chips unless a close path already has inspect steps).
