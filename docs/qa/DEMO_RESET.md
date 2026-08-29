# Demo reset (manual)

Exact click path so phone regression starts from a known-good **Sample home**. Local only. No cloud.

```bash
flutter run -d chrome
```

First-launch onboarding: **Skip**, or **Next** through three short screens → **Get started**. Safety disclaimer: **I understand**. Click path: [`FIRST_RUN.md`](FIRST_RUN.md).

---

## Known-good sample

| Appliance | Name | Brand | Model | Serial |
|---|---|---|---|---|
| Dryer | Laundry Room Dryer | Whirlpool | WED5000DW | DRY-SERIAL-1 |
| Washer | Laundry Room Washer | Whirlpool | WTW5000DW | WASH-SERIAL-1 |

Dryer also has two **Fixed** history rows, a **Clean lint system** reminder (about every 30 days), and (unless the toggle is off) an open **no heat** session. Sample dryer energy is **electric**.

---

## 1. Load sample home (empty home)

1. Home, no household yet.
2. Tap **Load sample home**.
3. You are in **Sample home**. Open **Laundry Room Dryer** or **Laundry Room Washer**.

Pass: both appliances show those brand/model labels. Washer **Start repair** is a new session (no sample open washer repair).

---

## 2. Include sample open session (as labeled)

**On** (default)

1. **Settings** (gear on home).
2. **Demo** → **Include sample open session** is on.
3. Tap **Load sample home** (same Demo section), or go home and tap **Load sample home** if the household is empty.
4. Home: **Laundry Room Dryer** shows **Continue repair**.

**Off**

1. **Settings → Demo**.
2. Turn **Include sample open session** off.
3. Tap **Reset sample data** (or **Load sample home** if you are replacing the sample).
4. Back to home. Dryer shows **Start repair**, not **Continue repair**.

The toggle only affects the next load/reset. It does not clear a session that is already open until you reset or **Clear open session**.

---

## 3. Reset sample data

1. **Settings → Demo → Reset sample data**.
2. Extra appliances you added under Sample home are gone. Canned dryer + washer return.

Safe if sample was never loaded (no crash). Safe to tap twice.

Pass: still **Sample home**, WED5000DW dryer, WTW5000DW washer. Other household profiles are unchanged.

---

## 4. Clear open session

1. **Settings → Clear open session**.
2. If a repair is in progress: confirm **Clear session**.
3. If none is in progress: tap anyway — snackbar **No repair is in progress**. No crash.

Pass: dryer **Start repair**. No **Continue repair**. Starting repair does not restore old chips or guidance. The abandoned session is not a Repair history row.

---

## 5. Phone regression from here

1. **Settings → Demo**: turn **Include sample open session** off.
2. Tap **Reset sample data**.
3. If you never loaded sample: tap **Load sample home** instead (or after reset).
4. Home → **Laundry Room Dryer** → **Start repair** → follow [`REGRESSION_PHASE1.md`](REGRESSION_PHASE1.md) §A (or [`REGRESSION_PHONE.md`](REGRESSION_PHONE.md) §A).
5. Home → **Laundry Room Washer** → **Start repair** → follow [`REGRESSION_PHASE1.md`](REGRESSION_PHASE1.md) §B (or [`REGRESSION_PHONE.md`](REGRESSION_PHONE.md) §B) from **What is the washer doing?**
6. Optional: **Add Dishwasher** → [`REGRESSION_PHASE1.md`](REGRESSION_PHASE1.md) §C (**Standing water**). Then export / tools / resume / offline in that kit.

Do not use **Continue repair** for those scripts.
