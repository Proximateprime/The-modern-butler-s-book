# Export inventory (House Book)

Readable household list for theft, insurance, or a move. **Share sheet + plain text.** No PDF library in this app. **On this device — not uploaded.**

Read from code on **2026-08-22**. Tests: `test/inventory_export_test.dart`.

This is **not** Settings → **Export household data** (JSON backup). Inventory is a human-readable report.

---

## What is in the file

Header: household name, date, *On this device. Not uploaded.*

For each appliance (active and retired):

| Line | Source |
|---|---|
| Name | Appliance nickname |
| Category | dryer / washer / fridge / dishwasher |
| Manufacturer | Brand |
| Model | Model number |
| Serial | Rating-plate serial, or **—** if never entered |
| Location | Room label (not a map) |
| Notes | **—** (appliance records have no free-text notes field) |
| Last repair | Optional. Newest completed repair: date · summary · Fixed/Stopped/… |

Retired units stay in the report with **Status: Retired**.

With Settings **Household Pro (debug)** on, the share also lists people in the home and, when recorded, root cause / contributing on the last repair. The free share stays the table above. See [`MONETIZATION_HOOK.md`](MONETIZATION_HOOK.md).

---

## Tap path — two appliances with model and serial (DoD)

Sample home already seeds serials **DRY-SERIAL-1** and **WASH-SERIAL-1**.

1. Home → **Load sample home** (or Settings → **Reset sample data**).
2. House Book list: **Appliances** → **Export inventory**. Helper: *Readable list for insurance or a move. Built on this device — not uploaded.*
3. System share sheet (or clipboard on web if the plugin is missing). Snackbar: *Inventory ready to share on this device.*
4. Open the shared text.

Pass: both **Laundry Room Dryer** (model **WED5000DW**, serial **DRY-SERIAL-1**) and **Laundry Room Washer** (model **WTW5000DW**, serial **WASH-SERIAL-1**) appear. Dryer has a **Last repair** line from sample history. No login, no cloud publish.

Without sample home: add two appliances with model and serial, then the same **Export inventory** button.
