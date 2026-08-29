# Tools inventory — persist

Household-owned tools are the repair checklist memory. Add/remove from Home **Tools** (wrench) or Settings. **I have this** on a repair does **not** save; **Also save to my tools** does.

Read from code on **2026-08-22**. Tests: `test/tools_inventory_test.dart`.

---

## What must stick

1. Add or remove a catalog chip (or custom name) on **Tools**.
2. Kill the app and reopen: the owned list is the same.
3. Start a dryer repair that shows a tools checklist (e.g. no-heat fuse path): **In your tools** / pre-checked **I have this** for owned ids only. Required tools that are not on the list show **Not in your tools**. Empty owned list does not crash and does not invent tools.
4. Remove that required tool on **Tools**. Continue the same repair: the row is **Not in your tools**. Add it back: **In your tools** returns.

Stale-save class of bugs: a fast tools overlay used to overwrite a newer snapshot with an old empty list. Overlay now carries a **generation** bumped on every add/remove. Restore keeps whichever side is newer. Overlay writes do not wait on the full household snapshot.

---

## Tap path (DoD)

1. Home → create household if needed → **Add Dryer** (defaults are fine) → **Save appliance**.
2. Home wrench **Tools** → **Add a tool** → **Screwdriver**. Owned shows Screwdriver.
3. Kill the app. Reopen. Home wrench **Tools** → Screwdriver still listed.
4. Home → dryer → **Start repair** → **No heat** → drum turns → skip/answer until **I'll repair** → past parts/inspect if shown → **Tools**. Screwdriver row: **In your tools**. Flashlight is not owned unless you added it.

Empty inventory: Tools screen shows **No tools listed yet…** — no crash.
