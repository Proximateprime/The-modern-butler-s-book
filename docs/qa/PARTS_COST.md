# Parts & cost (active path only)

Display-only stubs for the **selected close path / ranking leader**. Not a cart. Not live quotes. Not payment.

Read from code on **2026-08-22**. Tests: `test/parts_cost_card_test.dart`. Helper: `lib/helpers/parts_cost.dart` (`partsEstimatesForSelectedPath`). Disclaimer: **Estimates only. Not a quote.**

---

## Screenshot-level sanity

Same card on I’ll repair → **Parts**, Record outcome, and Done. Title **Parts & cost**. Helper line **Estimates only. Not a quote.** (`parts-cost-estimates-only`).

| Path (leader) | What you should see | Must not see |
|---|---|---|
| Dryer **thermal fuse** | One row **Thermal fuse** + DIY/Pro ranges | Lint filter, Flexible vent kit, Drain filter / pump trap, Inlet hose, Heating element |
| Dryer **vent / restricted exhaust** or **clogged lint pathway** | **No Parts & cost card** (cleaning path — no purchase row) | Lint filter or vent-kit for sale; any washer parts |
| Dryer **heating element** | **Heating element** only | Fuse, washer drain trap, inlet hose |
| Washer **drain filter** (cleaning) | **No card** (no drain-trap purchase) | Dryer fuse / lint filter / vent kit |

If the card is missing, that is correct when this path does not replace a part. **Continue** still advances.

---

## Tap path — dryer fuse vs washer parts (DoD)

1. Sample home off or a new dryer. **Start repair**.
2. Skip or answer until **Most likely**. Force leader **thermal-fuse-open** if the test harness can; on a phone, a no-heat path that lands on fuse is enough.
3. **Continue** → **I'll repair** → **Parts & cost**.
4. Screenshot: title, **Estimates only. Not a quote.**, **Thermal fuse** only.
5. Confirm there is no **Drain filter / pump trap** and no **Inlet hose**.

Vent-style: pick a restricted-exhaust / lint-pathway leader the same way. **Parts & cost** must not appear (or must not list a kit). No washer rows.

Pass: one appliance family, one path, one (or zero) purchase row. Unrelated washer parts never share the card.
