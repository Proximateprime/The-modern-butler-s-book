# Backup smoke (local)

Prove **Export household data** and **Restore from backup** round-trip household essentials. Local file only. No cloud, no account.

```bash
flutter run -d chrome
```

First-launch: **Skip** or three short screens → **Get started**. Safety disclaimer: **I understand**.

Settings labels: **Export household data**, **Restore from backup**. Success: *Household backup ready to save on this device.* Restore confirm: *This replaces households, appliances, repair memory, tools, and reminders on this device with the backup. It does not use the cloud.* Invalid file: *This file isn’t a household backup from this app. Your current data is unchanged.*

---

## Chrome limitation

Chrome **does not always download a `.json` file**.

- **Export:** the share sheet may appear, or the JSON is copied to the clipboard (`MissingPluginException` fallback). That is still local — not a server.
- **Restore:** needs a `.json` file in the file picker. If you only have clipboard text, paste it into a file named `household-backup.json` (UTF-8), then restore.

Phone/desktop with a working share target can save a file directly. The in-app restore path is the same.

---

## 1. Seed something to export

1. Home → **Load sample home** (or add a household and a dryer).
2. Open **Settings** (gear).
3. **Tools** → mark **Screwdriver** owned → back to Settings.
4. Optional: open the dryer **Maintenance** list and note a row (sample seeds **Clean lint system**).
5. Optional: dryer **Repair history** should already have sample **Fixed** rows.

Pass: home shows the sample dryer (and washer). Tools list has screwdriver marked.

---

## 2. Export

1. **Settings → Backup → Export household data**.
2. Save or copy the backup (share sheet, clipboard, or a `.json` file).

Pass: snackbar *Household backup ready to save on this device.* You have local JSON that includes `"kind": "modern-butler-household-backup"` and is **not** a URL upload.

---

## 3. Change something visible

Do **at least one**:

- **Tools:** uncheck **Screwdriver** (or another owned tool).
- **Maintenance:** check **Done** on **Clean lint system**.
- **Name:** open the dryer → edit name to `Renamed Dryer` → save.

Pass: home/settings now shows the change. Do **not** export again.

---

## 4. Restore

1. **Settings → Restore from backup**.
2. Pick the file from §2 (or paste-saved `.json`).
3. Confirm dialog → **Replace** (not **Cancel**).

Pass: snackbar *Household data restored from the backup.*

| Check | After restore |
|---|---|
| Appliances | Sample names again (**Laundry Room Dryer**, **Laundry Room Washer**). **Renamed Dryer** is gone. |
| Tools | **Screwdriver** is owned again if it was in the export. |
| Maintenance | **Clean lint system** is not the post-export Done state. |
| Repair history | Sample **Fixed** rows are back. In-progress repairs follow the backup, not later session work. |

**Cancel** on the confirm dialog leaves the renamed/unchecked state.

---

## 5. Invalid file

1. **Settings → Restore from backup**.
2. Pick a random `.txt` / garbage JSON / a file that is not this app’s backup kind.

Pass: snackbar *This file isn’t a household backup from this app. Your current data is unchanged.* No **Replace** dialog. Household name, appliances, and tools are still what they were. The app does not crash.

---

## Automated coverage

`flutter test test/local_backup_test.dart`

- Round-trip appliances, tools, reminders, repair history
- Export → visible change → restore returns the export
- Invalid JSON / empty snapshot envelope does not wipe data
- Settings invalid pick shows the calm snackbar and skips confirm
