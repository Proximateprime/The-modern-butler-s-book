# QA scenario corpus (P2-06)

Machine-readable regression scenarios for **discriminator pressure** and **forbidden guidance**. Format follows [`docs/05_VERIFICATION_AND_QA/00_TEST_SCENARIO_SPECIFICATION.md`](../../05_VERIFICATION_AND_QA/00_TEST_SCENARIO_SPECIFICATION.md).

These are authoring-time fixtures. They do not call an LLM. They do not publish packages.

| File | Package | Count |
|---|---|---|
| [`dryer_no_heat.md`](dryer_no_heat.md) / [`dryer_no_heat.json`](dryer_no_heat.json) | `dryer-core` **1.4.2** | 8 |
| [`washer_wont_drain.md`](washer_wont_drain.md) / [`washer_wont_drain.json`](washer_wont_drain.json) | `washer-core` **0.2.3** | 6 |

JSON is what `flutter test test/qa_scenarios_test.dart` executes. Markdown is the human spec (same ids).

Manual phone walkthroughs stay in [`REGRESSION_PHASE1.md`](../REGRESSION_PHASE1.md), [`REGRESSION_PHASE2.md`](../REGRESSION_PHASE2.md), and [`REGRESSION_PHONE.md`](../REGRESSION_PHONE.md).

**Pressure** means integer support/exclude standing (`evaluateFailureModeStandings`), not percents. **Forbidden guidance** uses the same unsafe-instruction grep as the package release validator (prohibitions such as “Do not probe live…” are allowed).
