# Version visibility (from the UI)

Cite these strings from **Settings**, not from source files. Display only — no separate version service.

```bash
flutter run -d chrome
```

Open **Settings** (gear on home).

---

## App

**Settings → About** (row titled **App 0.1.1+2**)

| Field | UI text |
|---|---|
| App | `App 0.1.1+2` |
| Freeze | `Feature freeze 2026-08-17 — bugfixes only` |

Same app line is on the Settings About row before you open the screen.

Source in code (do not rewrite to cite this): `lib/app_info.dart` (`kAppVersionLabel`), `pubspec.yaml` `version: 0.1.1+2`.

---

## Knowledge packages

**Settings → Package manager** (subtitle **Package manager — versions on this device**) or **About → Guides installed**.

Each installed row shows `id version · Installed`, matching [`PACKAGE_INVENTORY.md`](PACKAGE_INVENTORY.md):

| Appliance | UI line |
|---|---|
| Dryer | `dryer-core 1.4.2 · Installed` |
| Washer | `washer-core 0.2.3 · Installed` |
| Fridge | `fridge-core 1.0.1 · Installed` |
| Dishwasher | `dishwasher-core 0.2.3 · Installed` |

If a guide is missing: `Not on this device`.

---

## Pass / fail

Pass: a screenshot of About or Package manager includes **App 0.1.1+2** and the four `id version` lines above.

Fail: versions only visible in code, or UI ids/versions disagree with PACKAGE_INVENTORY.
