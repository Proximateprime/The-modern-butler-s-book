# Monetization hook (honest placeholder)

P2-14. **No Store billing.** No subscriptions. No fake urgency. Safety and emergency stop copy are never behind a purchase.

Read from code on **2026-08-22**. Tests: `test/household_entitlement_test.dart`, `test/audit_polish_test.dart`. Flag: `householdProEnabled` on the local snapshot (`lib/helpers/household_entitlement.dart`). Toggle: Settings → **Household Pro (debug)** — **debug builds only** (`householdProToggleVisible = kDebugMode`), so external testers on the release APK never see it.

`kStoreBillingWired` is **false**. `purchaseHouseholdProFromStore()` throws. There is no Buy button.

---

## Intended split

| Included for everyone (Free) | Household Pro (when billing ships) |
|---|---|
| Core repair on **dryer, washer, dishwasher, fridge** | Extra appliance families if we ship any (none today) |
| Interview, inspect LOOK FOR, Safe Guidance, close-path verify | Premium **formatting** of exports you already have (people on inventory; root cause / contributing on the repair log) |
| Safety disclaimer, in-session **safety stops**, hazard hard-stop copy | Extra **homes** and extra **people** in a home |
| House Book: appliances, history, tools, reminders | — |
| Plain **Export inventory**, per-repair log share, technician **handoff**, JSON **backup/restore** | — |

**Never paywalled:** basic safety guidance, emergency / hard-stop reasons, unplug-first language, “call a technician” when the package says so, technician handoff text.

**Not Pro:** ranking, Expert Mode, camera, AR (parked). Those are safety or product-lock decisions, not SKUs.

---

## What this build actually does

- Free path is the full Phase 1+2 repair book. Turning **Household Pro** off does **not** hide chips, stops, or House Book.
- Turning it **on** (debug) adds extra lines to inventory and repair-log shares from data already on the device. JSON backup is unchanged (it is household memory, not a pretty report).
- Extra homes and extra people stay available because Store billing is not wired. The entitlement functions already encode: first home / first person always free; extras would need Pro **after** `kStoreBillingWired` is true.
- All four bundled guides stay **core**. Fridge is not a paid add-on.

---

## Dark patterns we will not ship

No countdown, “only today,” scarcity (“spots left”), fake discounts, locking a stop banner, or a purchase sheet that claims a charge when the Store is not connected.

When billing is real: one honest price, restore purchases, and the same free/Pro table as above.
