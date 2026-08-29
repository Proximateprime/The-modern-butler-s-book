# Repair history per appliance

A **verified Fixed** (or other completed close) appends a row on that appliance’s **Repair history**. Newest first. In-progress sessions never appear as Fixed.

Read from code on **2026-08-22**. Tests: `test/appliance_detail_test.dart`, `test/repair_history_display_test.dart`. Phone: [`REGRESSION_PHONE.md`](REGRESSION_PHONE.md) §A steps 15–16.

---

## What a row shows

| Field | Source |
|---|---|
| Headline | Symptom / path / short what-fixed (`repairHistoryHeadline`) |
| Date · outcome | `YYYY-MM-DD · Fixed` (or Not fixed / Stopped / Calling a professional) |
| Optional cause | Immediate/root cause when it is not already the headline |
| Optional also | Confirmed contributing factors (`Also:`) |
| Optional prevent | Confirmed prevention (`Prevent:`) |
| Optional note | **Short note** from Record outcome |
| Optional parts | **DIY about $N** when What you spent was entered |
| Who | **by** the person who started the session (`createdByUserId` → household member name) |

When **two or more** verified Fixed rows (and/or maintenance notes) on the same appliance share a vent, drain-filter, or coils family, the appliance page may show a dismissible **From your household history** card. One record is not enough. Not ranking. On-device only.

On **Fixed**, Record outcome shows guide chips for contributing factors and prevention (selected until you turn them off), plus optional extra lines. Root cause is the guide wording unless you edit it or tap **Root cause not sure**. The app does not invent a root cause. **Update maintenance schedule** is optional and writes a local next-due reminder only.

Notes are entered on **Record outcome** (optional). There is no separate post-save editor.

---

## Tap path — dryer Fixed, then restart

1. Home → **Laundry Room Dryer** (or **Add Dryer**) → **Start repair**.
2. **What's going on?** → **No heat** → **Confirm and continue**. Drum **Turns normally**. Answer or skip easy-checks / inspect.
3. **Most likely** → **Continue** → **I'll repair** → parts/inspect/tools as shown → **Safe Guidance** → **I did this** until verification → **Confirmed**.
4. **End Session — Ready to resolve** → **Fixed — problem resolved**. Confirm or edit **Root cause** and **Prevention** chips. Optional **Short note**. **Save to household memory** → wrap-up → **Save & go home**.
5. Dryer detail **Repair history**: new row at the **top**, subtitle `YYYY-MM-DD · Fixed`, plus **Prevent:** when prevention was saved. Open session **Continue repair** is not a history row.
6. Kill the app and reopen. Same dryer still shows that Fixed row with root cause and prevention (not **No repairs yet**).

Pass: one completed dryer path, one history row on that appliance after restart; a second in-progress repair does not add a second Fixed row until it is closed.
