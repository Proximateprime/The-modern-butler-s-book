# Knowledge package release checklist

**Authoring-time only.** Passing the validator does **not** publish a package. A human still signs this page (or the print copy) before a version bump is treated as production.

Print / sign-off form: [`docs/05_VERIFICATION_AND_QA/00_KNOWLEDGE_PACKAGE_RELEASE_CHECKLIST (1).md`](../05_VERIFICATION_AND_QA/00_KNOWLEDGE_PACKAGE_RELEASE_CHECKLIST%20(1).md). Standing rule: knowledge graph + evidence own truth; candidates are not production until human approval.

Phase 2 families in this folder:

| Family | Folder | Bundled package |
|---|---|---|
| Dryer | [`dryer/`](dryer/README.md) | `dryer-core` |
| Washer | [`washer/`](washer/README.md) | `washer-core` |
| Dishwasher | [`dishwasher/`](dishwasher/README.md) | `dishwasher-core` |

Fridge is **not** gated here (see [`docs/qa/PHASE2_PLAN.md`](../qa/PHASE2_PLAN.md) §7). Inventory: [`docs/qa/PACKAGE_INVENTORY.md`](../qa/PACKAGE_INVENTORY.md).

---

## How to run (CI-less)

From the repo root:

```bash
dart run tool/validate_knowledge_packages.dart
```

Or via tests:

```bash
flutter test test/package_release_checklist_test.dart
```

Success prints **VALIDATOR OK**. That only means the mechanical gates below passed. Sign the human boxes anyway.

---

## Mechanical gates (validator)

Claimed paths live in each family folder as `claimed_paths.json`. The validator loads bundled packages from `KnowledgePackageRepository` (no network).

1. **Version present** — non-empty `KnowledgePackage.version`, matching `expectedVersion` in the JSON when that field is set.
2. **Symptom → mode links for claimed paths** — each claimed `symptomId` exists; each `modeId` exists; each mode is linked from an evidence template (`relatedFailureModeIds` or `supportByAnswer`). If a `*complaint*` template has an answer equal to the symptom **label**, that answer must list the claimed modes.
3. **Safety flags on risky verifications**
   - Dryer: listed risky modes that exist in the package must have a close path (`closePathForFailureMode`) with `allowResolvedWhenConfirmed == false` **or** `preferProfessionalWhenNotConfirmed == true`.
   - Washer / dishwasher: at least one `SafeCheck` with `safetyLevel: stop` covering sealed/tub-or-pump, live electrical, and gas (by id/label/description).
4. **Unsafe user-facing strings (basic grep)** — instructional patterns (bypass/jumper, live voltage, refrigerant recovery, piercing lines, lighting gas, opening sealed assemblies) on lines that are **not** already a prohibition or a technician handoff.
5. **Regression list referenced** — each `regressionDocs` path exists and the file text contains the package id.

---

## Human boxes (not automated)

Package: _______________  Version: _______________  Reviewer: _______________  Date: _______________

- [ ] Discriminators on claimed paths still split competing modes (not a mode-count trophy).
- [ ] Easy checks first; inspect LOOK FOR polarity is correct where inspect exists.
- [ ] No gas DIY, no sealed-system / refrigerant DIY, no beginner live-electrical procedures.
- [ ] Prevention lines are authored (empty is allowed; do not invent).
- [ ] `flutter test` with **zero** runtime LLM.
- [ ] Factory import did not overwrite close-path handoff vs DIY language.
- [ ] Print checklist signed.

**Approved for production:** _______________________________

---

## Wiring

- Claimed-path JSON: `docs/knowledge/<family>/claimed_paths.json`
- Validator: `lib/helpers/package_release_validator.dart`
- CLI: `tool/validate_knowledge_packages.dart`
- Tests: `test/package_release_checklist_test.dart`
