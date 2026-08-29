# Feature freeze

**Date:** 2026-08-17  
**App version:** 0.1.1+2 (bugfix pack; freeze still 2026-08-17)  
**Policy:** After this freeze, **bugfixes only**. No new features, appliances, ranking work, or cloud sync.

This file is the ship lock for The Modern Butler’s Book as of **2026-08-17**. Phase 1+2 work after that date is inventoried in [`MVP_DEFINITION.md`](MVP_DEFINITION.md) (frozen **2026-08-22**). Agents and humans should read both before changing code.

---

## What ships

A **local-first** Flutter household repair book. Ranking and diagnosis stay **deterministic** on-device. Optional camera and microphone never diagnose.

### Appliances and guides

| Category | Package | Version |
|---|---|---|
| Dryer | `dryer-core` | 1.4.2 (41 modes, v0.2 discriminators, easy-airflow inspect, resettable cutoff) |
| Washer | washer primary | 0.2.3 (drain-filter polarity + discriminators) |
| Fridge | fridge v1 | 1.0.1 |
| Dishwasher | dishwasher primary | 0.2.3 (filter-first drain looks) |

### Product loop

- Households (homes) and people in a home (switch who is using the app; shared House Book; no roles)
- Households and appliance identity (manual entry; optional rating-plate OCR / barcode)
- Start / continue a repair session, problem starter, observation interview
- Package-weighted ranking (algorithm frozen)
- Safe Guidance, close-path verification, safety stops
- Session outcome (Fixed / not fixed / stopped / professional) and household memory
- Resume, stale-session prompt, local backup, repair-log export
- First-run, safety disclaimer, Settings (appearance, privacy, camera/mic help, guides)
- Optional photos, voice-to-chip. **Show me where / AR location pictures parked** (`locationVisualAidsEnabled`)
- A11Y v1 primary CTAs (Start, Continue, Fixed, Back)

### Platforms

- Flutter app as built in this repo (mobile-first; desktop/web are not a separate product track)

---

## Explicit non-goals (do not start)

- **No new appliances** beyond dryer, washer, fridge, and dishwasher
- **No ranking redesign** (no new scoring engine, no LLM diagnosis, no weight-algorithm refactors)
- **No cloud sync** of household data, sessions, photos, or memory (no account backend, no remote package fetch)
- No new knowledge-package depth campaigns
- No new engines, state-machine states, or schema expansions except as required to **fix a bug**
- No monetization, subscriptions, or public knowledge marketplace

---

## After freeze

Allowed:

- Bugfixes
- Test fixes that lock existing behavior
- Copy/typo corrections that do not change diagnosis
- Dependency patches for security/build breakage

Not allowed without an explicit founder un-freeze:

- Features
- UX redesigns
- New Settings surfaces
- Knowledge content expansion

If a change is not a bugfix, **stop**.

---

## Run this before release

Regression binder v1 (critical paths only):

```
flutter test test/regression_binder_v1_test.dart
```

Covers: dryer no-heat Fixed + memory, session resume, washer drain, dishwasher standing water, hazard hard-stop.

Then run the full suite:

```
flutter test
```

Both must be green before a release.
