# House Book — appliance records

Household spine: each repair attaches to an **appliance record**, not a one-off chat. Add and edit from home. No maps. Photos stay on this device.

Readable inventory share: [`EXPORT_INVENTORY.md`](EXPORT_INVENTORY.md) (House Book → **Export inventory**).

Read from code on **2026-08-22**. Tests: `test/house_book_appliances_test.dart`, `test/appliance_lifecycle_test.dart`, `test/ocr_model_label_test.dart`, `test/add_appliance_copy_test.dart`.

---

## Fields

| Field | Required | Notes |
|---|---|---|
| Name | Yes (defaulted) | e.g. Laundry Room Dryer |
| Category | Yes | Chosen by **Add Dryer** / **Add Washer** / Fridge / Dishwasher |
| Brand (manufacturer) | Prompted | Typed or from rating-plate scan |
| Model | Prompted | |
| Serial | Optional, prompted | Helper: **Optional — from the rating plate if you can see it.** |
| Location | Room label | Helper: **Room label only — not an address or map.** Default Laundry Room or Kitchen |
| Install or purchase date | Optional | Already in schema; warranty hint needs model + this date |
| Approx. age (years) | Optional | Already in schema |
| Rating-plate photo | Optional | Local file path on the record. **The photo stays on this device. It is not used to diagnose.** |
| Status | Active / retired | Home lists **active** only. **Retire** hides the card; history stays |

OCR/barcode scan is phone-only, on-device (ML Kit). Failures show a calm snackbar and leave the form for typing. An unreadable scan still keeps the photo if one was taken.

---

## Tap path — dryer + washer, survive restart

Use a **new** household (not sample home), so the list is yours.

1. Home → **Create Household** (if needed) → name it → confirm.
2. **Add Dryer** (empty home: filled button; if you already have appliances: outline chip at the top).
3. **Add dryer** form. Type brand **Whirlpool**, model **WED5000DW**, serial **DRY-SERIAL-1**. Location can stay **Laundry Room**. **Save appliance**.
4. Home lists **Laundry Room Dryer** with **Model WED5000DW**.
5. **Add Washer** → brand **Whirlpool**, model **WTW5000DW**, serial **WASH-SERIAL-1** → **Save appliance**.
6. Home lists both **Laundry Room Dryer** and **Laundry Room Washer**.
7. Open the dryer card → **Model: WED5000DW** · **Serial: DRY-SERIAL-1**. **Edit appliance** (pencil) is the same form.
8. Kill the app and reopen (or use a second `AppDependencies.restore` in tests). Both appliances are still on household home with the same model and serial.

**Retire:** home card archive icon → **Retire**. The unit leaves the list. Past repairs stay under Recent Activity.

---

## Scan (optional)

On a phone with camera allowed: **Scan rating plate**. Confirm or edit brand/model/serial. If the plate cannot be read: **Couldn’t read the rating plate. You can enter the details by hand.** — photo still kept. Denied camera: banner + type by hand. Web: **Type brand and model here. Rating-plate scan is phone-only.**
