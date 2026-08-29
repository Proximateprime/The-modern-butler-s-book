# MODULE 3: Knowledge Graph Seeding (MVP Phase 1)

| Field | Value |
|-------|-------|
| **Module Number** | 03 |
| **Module Name** | Knowledge Graph Seeding (MVP Phase 1) |
| **Status** | Ready for Composer Fast |
| **Date** | July 16, 2026 |
| **Developer** | Mark (using Cursor free plan) |
| **AI Assistant** | Composer |
| **Depends On** | Module 01 — Appliance Table · Module 02 — Knowledge Graph Structure |

---

## Relevant Excerpt from Product Bible

**From `04_KNOWLEDGE_GRAPH_SEEDING_PLAN.md` — Phase 1**

> Define top-level Appliance categories and Subsystems for the four MVP appliances. Create the main Component nodes. Establish the inheritance tree (Appliance → Subsystem → Component). Every seed entry has source, date, and version.

**MVP Categories (must be solid):**
1. Dishwasher
2. Washing Machine (Washer)
3. Dryer
4. Refrigerator / Freezer

**Success scenario (Seeding Plan):**

> When a user says "My dishwasher leaves water in the bottom and I hear the pump running," the seeded graph allows the Reasoning Engine to generate a sensible shortlist of Failure Modes (drain obstruction, drain pump, float switch, etc.).

**From `02_NON_NEGOTIABLES.md` (App Promise)**

| Principle | Module 3 Alignment |
|-----------|-------------------|
| **Observation Before Conclusion** | 15 symptom nodes describe what users see/hear/smell — never "broken pump" |
| **Evidence Before Assumption** | 27 `suggests` edges with weights 0.40–0.80 — ranking hints, not certainty |
| **Explainability Before Fluency** | Every edge has a `note` in metadata explaining why the link exists |
| **Privacy Before Surveillance** | Platform engineering knowledge only — no household data |
| **Offline-First** | All nodes keyed by stable `slug`; version `KG-v0.1-mvp` for bundle sync |
| **Learn Only From Verified Outcomes** | Version tag enables rollback; Phase 2 adds evidence & questions |

---

## Build Instructions

1. **Prerequisites** — Module 01 + Module 02 migrations applied.
2. **Apply seed migration:**
   ```bash
   supabase db push
   ```
   Or run `supabase/migrations/20260716000003_seed_knowledge_graph_mvp.sql` in SQL Editor.
3. **Verify version** — `KG-v0.1-mvp` should be `is_current = true`.
4. **Verify counts** (approximate):
   - 4 categories · 16 subsystems · 32 components
   - 15 symptoms · 16 failure modes
   - ~27 symptom→failure_mode edges (+ mirrored `produces` edges)
5. **Dart queries** — see `lib/examples/kg_query_examples.dart`.
6. **Optional programmatic seed** — `lib/seed/knowledge_graph_seeder.dart` (service role only; SQL is preferred).
7. **Do NOT add** — reasoning engine, evidence nodes, safe checks, questions, AR, or predictive logic.

### Manual verification query (SQL)

```sql
select node_type, count(*) from kg_nodes where graph_version = 'KG-v0.1-mvp' group by node_type;
select relation_type, count(*) from kg_edges where graph_version = 'KG-v0.1-mvp' group by relation_type;
```

---

## Seed Summary

| Category | Subsystems | Failure Modes (Phase 1) |
|----------|------------|---------------------------|
| Dishwasher | Drain, Water Supply, Wash, Door & Latch | Drain obstruction, pump failure, clogged filter, seal leak |
| Washing Machine | Water Supply, Drain, Drive & Spin, Door & Latch | Drain clog, inlet valve, worn belt, unbalanced load |
| Dryer | Airflow, Heating, Drive, Door & Latch | Lint buildup, heating element, drum belt, drum rollers |
| Refrigerator/Freezer | Cooling, Defrost, Door Seal, Controls | Dirty coils, gasket leak, defrost failure, evaporator frost |

---

## Output — Files Created

| File | Purpose |
|------|---------|
| `supabase/migrations/20260716000003_seed_knowledge_graph_mvp.sql` | **Primary seed** — all nodes & edges |
| `lib/seed/kg_mvp_seed_data.dart` | Dart mirror of key seed definitions |
| `lib/seed/knowledge_graph_seeder.dart` | Programmatic seeder (service role) |
| `lib/examples/kg_query_examples.dart` | Query patterns for seeded graph |

### Dart usage examples

```dart
final kg = KnowledgeGraphService();
final examples = KgQueryExamples(kg: kg);

// Scenario: standing water in dishwasher
await examples.dishwasherStandingWaterScenario();
// → Drain path obstruction (75%)
// → Drain pump not moving water (60%)

// Explore anatomy
await examples.exploreDishwasherStructure();
// → Drain System → Drain Pump, Drain Hose
// → Wash System → Spray Arms, Filter

// Offline bundle
await examples.cacheGraphForOffline();
// → version KG-v0.1-mvp, ~83 nodes, ~100+ edges
```

### Key query pattern (Reasoning Engine preview)

```dart
// 1. User describes observation → match symptom by slug
final symptom = await kg.getNodeBySlug(
  nodeType: KgNodeType.symptom,
  slug: 'standing-water',
);

// 2. Get ranked hypotheses (NOT diagnoses)
final hypotheses = await kg.getFailureModesForSymptom(symptom!.id);

// 3. Filter to user's appliance category
final dishwasherHypotheses = hypotheses
    .where((h) => h.node.slug.startsWith('dishwasher-'))
    .toList();
```

---

## What Comes Next (Development Order)

- **Module 4+** — Evidence nodes, Safe Checks, Question seed (Seeding Plan Phase 2–3)
- **Reasoning Engine** — traverses `suggests` edges, filters by `applies_to` category
- **Full MVP seed metrics** — expand to 80+ failure modes, 200+ symptom links (post-Phase 1)

---

*Phase 1 bar: a user describing a real symptom gets a sensible, beginner-friendly shortlist grounded in structured relationships — not AI invention.*
