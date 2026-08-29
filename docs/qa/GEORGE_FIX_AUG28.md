# George fix pack — 28 Aug 2026

Each George line → what changed. Spec-silent choices are in the ledger at the end.

## A. Graph seeder and edges

1. **Dart seeder must write each edge’s real relation type.**  
   `lib/seed/knowledge_graph_seeder.dart` — writes `KgRelationType.fromString(seed.relation)`. No force-`suggests`, no automatic `produces` mirror.  
   `lib/seed/kg_mvp_seed_data.dart` — `kgMvpEdges` includes `contains`, `applies_to`, `affects`, `suggests`, and authored `produces` only where listed.

2. **`createEdge` rejects illegal combinations.**  
   `lib/helpers/kg_relation_rules.dart` — `assertLegalKgRelation`.  
   `lib/services/knowledge_graph_service.dart` — `createEdge` loads both nodes and throws `IllegalKgRelationException`.

3. **Writes stay create-only.**  
   No update/archive API added.

## B. Seed holes

4. **Washer `unbalanced-load` `affects`.**  
   Component `washer-suspension` under `washer-drive-spin`. Edges in Dart seed + `supabase/migrations/20260716000003_seed_knowledge_graph_mvp.sql` + `supabase/migrations/20260828000001_george_graph_seed_fixes.sql`.

5. **`wont-start` vs belt / thermal fuse.**  
   Removed `wont-start` → `dryer-worn-drum-belt` and `wont-start` → `dryer-lint-buildup` (migration deactivates existing rows).  
   Added `dryer-thermal-fuse-open` with `affects` thermal fuse and `suggests` from `clothes-not-drying`.  
   Added `dryer-door-switch-failure` for nothing-happens / DRYER-003.  
   Belt hangs on new symptom `drum-does-not-turn`.  
   Washer `wont-start` → `washer-lid-switch-failure` (family-scoped).

6. **Fridge evaporator under cooling.**  
   `refrigerator-cooling` `contains` `refrigerator-evaporator-coils` (defrost parent kept).

7. **`grinding-noise` → drain pump only dishwasher/washer.**  
   `applies_to` on FMs + `kgSuggestedFailureModeSlugsForFamily`. Added `washer-drain-pump-failure`. Dryer family returns none.

8. **Fridge compressor FM with sealed/pro gate.**  
   `refrigerator-compressor-sealed-fault` metadata: `beginner_diy: false`, `safety: sealed_system`, `difficulty: professional`. Omitted from beginner KG query. Not added to fridge package DIY list.

9. **Floor leak not only door seal.**  
   Also `dishwasher-drain-hose-leak`, `washer-drain-hose-leak`, `washer-supply-line-leak`, `refrigerator-drip-pan-overflow`. No gas-train DIY.

## C. APK blockers

10. **Energy source electric | gas | unknown.**  
   Already on add/edit dryer (`lib/ui/add_appliance_screen.dart`), persist (`lib/services/local_domain_store.dart`). Unknown + heat asks fuel first (`lib/helpers/dryer_energy_source.dart`). Gas steering now also uses appliance `energySource` when the interview row is missing (`lib/helpers/failure_mode_standing.dart`, `lib/services/ranking_service.dart`, `lib/services/diagnostic_reasoning.dart`).

11. **Burning smell → safety stop.**  
   Already `lib/helpers/safety_stop.dart` + session UI. Covered again in `test/george_fix_aug28_test.dart`.

12. **Missing package / Continue repair.**  
   Already `missing-guide-scaffold` in `lib/ui/session_screen.dart` (Install guide / Start fresh / back). Not a blank body.

13. **Symptom → FMs filter by family.**  
   `lib/helpers/kg_family_filter.dart`, `lib/helpers/kg_category_slugs.dart`, `KnowledgeGraphService.getFailureModesForSymptom(applianceCategorySlug: ...)`.

14. **Category picker slugs vs graph.**  
   App still stores `washer` / `fridge` for packages. Graph queries map via `kgGraphCategorySlug` (`washer` and `Washing Machine` → `washing-machine`). Packages were not renamed (would break every session ref).

15. **Unknown appliance status must not map to `active`.**  
   `applianceStatusFromName` in `lib/models/appliance.dart`; restore in `lib/services/local_domain_store.dart`. Garbage → `retired`.

16. **Dryer copy: door not lid; no spin cycle.**  
   Dryer `door-closed-firmly` already says door. Guard test in `test/george_fix_aug28_test.dart`.

17. **No beginner live-voltage evidence.**  
   Package prompts that instruct measuring live voltage without a prohibition fail the new test. Existing copy is “do not measure…”.

18. **Dishwasher float switch FMs.**  
   `dishwasher-float-switch-stuck` + `suggests` from `standing-water` and `wont-fill` + `affects` the component. Package inspect list unchanged (KG hole, not a new dishwasher interview module).

## Tests

`test/george_fix_aug28_test.dart` — seeder relations, illegal `createEdge`, family filter, gas/unknown heat path, burning stop, missing scaffold, status garbage, thermal-fuse FM, gated compressor, dryer copy, live-voltage prompts.

## Ranked decision ledger (spec-silent only)

Least confident first:

1. **Washer `wont-start` uses `washer-lid-switch-failure`.** Spec said dryer door-switch must exist; washer needed some family-scoped FM so the query is not empty after dropping dryer belt. Lid/door switch is the honest parallel, not a new architecture.

2. **Belt symptom slug `drum-does-not-turn`.** Graph had no dryer “drum still / motor runs” observation. Invented one slug rather than overload washer `wont-spin` (spin-cycle wording).

3. **Compressor stays out of the fridge package FM list.** Ranking only walks package modes. Gating in KG metadata + beginner query filter. A package FM would show as DIY unless ranking grew a new gate (out of scope).

4. **SQL `produces` mirror remains in migrations.** George forbade the Dart seeder from forcing a mirror of every edge. SQL still inserts inverse `produces` for active `suggests` so already-deployed DBs keep explainability. Dart writes only authored `produces` rows.

5. **Garbage status → `retired` not `archived`.** Either hides the unit; `retired` matches the household retire action and cannot un-retire to `active`.

6. **App category ids stay `washer`/`fridge`.** Mapping at the graph boundary instead of renaming packages and every session/home button.
