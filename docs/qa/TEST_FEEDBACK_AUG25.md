# APK test feedback — 2026-08-25

Product fixes from real-device testing of The Modern Butler MVP (Phase 1+2). **App 0.1.1+2**. Dryer package **dryer-core 1.4.2** (41 modes). Ranking engine was not rewritten. No Phase 3, AR/CV, calendar OAuth, or runtime diagnosis-by-LLM.

## A. Trust / session

### A1. “Show me what to check” does not undo diagnosis

**Was:** After Most likely / conclusion, the control behaved like a restart: inspect chips could rewrite evidence and felt like starting over.

**Now:** The button is labeled **Review what you checked**. It opens a **review-only** list of inspect looks already on the path (answered or not yet recorded). It does **not** clear evidence, hypotheses, or the selected path, and it does **not** show recording chips. **Back to most likely** returns to conclusion.

Recording inspect chips still run after **I'll repair** / Parts, before Tools — that is how new looks get into evidence.

**Start over:** There is no unlabeled restart on this control. A new repair on the same appliance is a separate session start from House Book, not this button.

**Test:** `test/test_feedback_aug25_test.dart` — reach conclusion → Review what you checked → evidence, hypothesis, and path unchanged.

### A2. Dryer thermal / no-heat: reset vs pro-only fuse

Two different no-heat thermal stories:

| Path | Mode id | Home outcome |
|---|---|---|
| **User-accessible reset / resettable cutoff** | `accessible-thermal-reset` (new in 1.4.2) and `motor-overheat-protector-open` | DIY-completable: cooldown / visible reset if present, then **root cause** = lint/vent/airflow. Warnings stay. No beginner meter work. |
| **Replace behind panels / live electrical** | `thermal-fuse-open` (and other existing pro-only heater-path modes) | Early *A full fix likely needs a pro*. **Parts & cost** shows **Pro ~** only — no DIY price, no **I'll repair** on that card. Confirming the pattern does not unlock **Fixed**. |

Built-in close paths for the resettable ids win over terse imported Batch-02 copy so a last-line “call a technician” sentence does not flip the whole path to pro-only.

New interview discriminator: `thermal-reset-control` (visible reset / cooldown vs still cold). It is **not** in the auto-next no-heat discriminator list, so it cannot steal the golden-path next question; it remains available as an unused overlap pick.

High-limit thermostat (`high-limit-thermostat-open`) stays a **pro-only sibling** of the fuse. It still gains support from no-warmth + heat cycle + recent overheat. Weak exterior airflow is **not** extra high-limit credit — that answer already supports fuse/vent, and sharing it stalled the fuse recommendation (lead margin 1 instead of 2). High-limit remains listed as also possible.

**Not claimed:** Every dryer has a household reset button. If there is no visible reset, skip that step and keep the vent check; remaining no-heat after that is still fuse / heater service.

## B. First questionnaire — multi-select

The starter **What's going on?** chips are **multi-select** (check-style). **Other / type your own** can combine with chips. Continue is enabled when at least one chip (or Other with text) is selected.

Session evidence stores **all** selected labels on the starter complaint row (union). Downstream questions use the existing evidence list — ranking math is unchanged.

Unmatched Other text is **not** a black hole: the session continues with *We'll use what you typed; specific guidance may be limited.* and the typed string is stored.

**Test:** two chips → both labels in evidence (`test/test_feedback_aug25_test.dart`, `test/problem_starter_test.dart`).

## C. Two problems at once — easier first

When two or more failure modes remain plausible after evidence, close-path **pursuit** prefers the **easier / safer / lower brick-risk** mode (resettable/DIY before pro-only and brick-risk jobs). Ranking scores are **not** recomputed; this is a presentation overlay (`lib/helpers/easier_first.dart`).

Copy: *Two things still fit. We're checking the simpler, lower-risk possibility first.* The other stays listed as also possible (collapsed remaining-likely card).

If the easier path is verified **not confirmed** (problem persists), the session continues to the next remaining mode. Completing one check does **not** claim both are fixed.

## D. Brick-risk / high-stakes repairs

High-stakes DIY (belt, rollers, idler, drum bearings, blower obstruction) shows a persistent banner: mistakes can permanently damage the appliance or create danger; a professional is recommended; the user can still do safe checks and optional steps.

This is **not** a silent empty “hands off.” Pro-only fuse/element paths keep the existing pro wall instead of this banner. Gas / sealed-system / refrigerant DIY stay blocked. Beginner live-electrical measurement stays blocked.

## E. Maintenance

### E1. Remind locally

Accepting a reminder (Fixed prevention, House Book **Add reminder**) stores due date / interval on the existing maintenance record. When the item is **already due**, a **local notification** is shown (Android `POST_NOTIFICATIONS`). Future dues wait for the next app open, then notify or show the home **Maintenance is due** banner if notifications are denied.

In-app: House Book appliance list shows due / overdue copy. **Remind me in 30 days** and **Mark done** (checkbox / row tap) are available. No Google/Apple Calendar OAuth.

If nothing is due and no reminder exists, home does **not** invent nag cards.

### E2. Empty manufacturer / community sections

**Manufacturer schedule** and **What others noticed** render **only** when the package (or verified household history) has real rows. MVP packages have none → sections are omitted (no empty card, no “coming soon”). Household pattern hints stay N=2 verified history only.

### E3. Household impact

Counts are **repairs logged** (Fixed outcomes) and **appliances kept in service** (distinct appliances with a Fixed). Estimated savings appear **only** when the user entered a DIY cost that can be compared to the package pro stub. No invented environmental scores.

## F. Enrichment store (not live diagnosis)

Runtime diagnosis remains package + evidence. LLM is not the diagnostic authority.

When starter Other text has **no package match**:

1. Gap is detected (unmatched free text).
2. An `EnrichmentRequest` is queued. Runtime provider calls are **feature-flagged off** (`kRuntimeEnrichmentCallsEnabled = false`). `StubEnrichmentProvider` returns empty (safe offline).
3. A **pending household note** is stored, keyed by appliance / model / symptom hash. Accepting it is a local “for this home” note — never a silent global package overwrite.
4. Later sessions can show an **accepted** note. The same accepted fact is not re-researched.

To plug in a real provider: implement `EnrichmentProvider.research`, pass it into `AppDependencies(enrichmentProvider: …)`, and only then consider enabling `kRuntimeEnrichmentCallsEnabled` after review. Do not block the session on network.

## G. Copy / UX

- Pro-only: early pro notice; Parts card has no DIY price / **I'll repair**.
- Resettable thermal: not the same “full fix needs a pro” wall.
- Interview pause copy from the prior polish pass is unchanged.
- Conclusion control matches A1: **Review what you checked**.

## H. Upgrade resume — missing guide / blank screen

**Was:** After updating to 0.1.1+2, in-progress dryer repairs saved with an older `dryer-core` version failed `loadByRef` (exact version). The missing-guide banner could be dismissed (**Continue manually** / **OK**) while the dryer package was already installed, leaving a **blank scaffold**.

**Now:** Resume remaps a compatible bundled guide (same id after a version bump, or the family package). Household appliances and tools are not deleted. If the catalog is truly empty, SessionScreen shows a real **missing-guide** scaffold (app bar, **Install guide**, **Start fresh**, **OK**). **Continue manually** is not on that screen. **OK** pops back to House Book. **Start fresh** abandons the in-progress session and pops — it does not leave an empty route.

**Tests:** `test/missing_guide_resume_test.dart`.

## Residuals (honest)

See [`KNOWN_ISSUES.md`](KNOWN_ISSUES.md). Notifications are due-or-on-open, not exact-time scheduling. Enrichment is a stub. Thermal **fuse swap** remains professional. Decision-step **I'll repair** still advances observational checks on some pro-only leaders (Parts card CTA stays hidden).

## Artifact

| | |
|---|---|
| Path | `build/app/outputs/flutter-apk/app-release.apk` |
| Size | 99.6 MB (104,481,211 bytes) |
| Built | 2026-08-25 10:23 (local) |
| Version | **0.1.1+2** |
| Tests | `flutter test` — 708 passed |
| Command | `flutter build apk --release` |

Details: [`BUILD_NOTES_PHASE2.md`](BUILD_NOTES_PHASE2.md).
