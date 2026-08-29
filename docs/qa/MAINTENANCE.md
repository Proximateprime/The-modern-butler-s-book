# Maintenance display

In-app reminders tied to an appliance. **Local notification when already due** (or a home banner if notifications are off). **No calendar OAuth.**

Read from code on **2026-08-22**. Tests: `test/maintenance_list_test.dart`. Sample dryer seeds **Clean lint system**.

---

## What a row shows (when an interval exists)

| Line | When |
|---|---|
| **Last done YYYY-MM-DD** | After the household has marked Done at least once |
| **Next due YYYY-MM-DD** | Always for repeating items; **· Overdue** if not done and due day is before today |
| **About every N days** | Stored or inferred interval (dryer lint system / vent / washer filter: 30) |

Every-load lint **filter** copy does not invent a calendar interval. **Clean lint system** is the housing/vent-path upkeep (30 days).

Marking **Done** stamps last completed as today and rolls next due by the interval. Unchecking clears last done. The row stays on that appliance.

Home **Upcoming** shows up to 3 **undone** reminders for the household (soonest due first). Appliance **Maintenance** lists all rows for that unit.

---

## Tap path — Clean lint system (DoD)

1. Home → **Laundry Room Dryer** (sample home already has **Clean lint system**, or **Add reminder** with that title).
2. **Maintenance** list: title **Clean lint system**. If past due: **Next due … · Overdue** and **About every 30 days**.
3. Check **Done**. Copy updates to **Last done** today and **Next due** ~30 days later. **Remind me in 30 days** snoozes an undone item. A due item can ping locally; if notifications are denied, Home shows **Maintenance is due**.
4. Kill the app and reopen. Same dryer still shows **Last done** and the rolled **Next due**.

Pass: next due moved; last completed set; still there after restart. No push / no calendar prompt.
