# MODULE 2: Knowledge Graph Structure

| Field | Value |
|-------|-------|
| **Module Number** | 02 |
| **Module Name** | Knowledge Graph Structure |
| **Status** | Ready for Composer Fast |
| **Date** | July 16, 2026 |
| **Developer** | Mark (using Cursor free plan) |
| **AI Assistant** | Composer |
| **Depends On** | Module 01 — Appliance Table |

---

## Relevant Excerpt from Product Bible

**From Volume VIII — Chapter 7: Knowledge Graph Architecture**

> The Knowledge Graph is the structured representation of engineering knowledge. Rather than storing information as isolated records, the Knowledge Graph represents knowledge as interconnected entities and relationships.
>
> Core node types: Appliance Category, Subsystem, Part/Component, Failure Mode, Symptom.
>
> Example relationships: Appliance **contains** Subsystem; Failure Mode **produces** Symptom; Part **belongs to** Subsystem.
>
> The graph contains engineering knowledge — never home layouts, personal schedules, or household photos.

**From `04_KNOWLEDGE_GRAPH_SEEDING_PLAN.md`**

> Phase 1 — Define top-level Appliance categories and Subsystems. Create Component nodes. Establish inheritance tree (Appliance → Subsystem → Component). Every seed entry has source, date, and version.

**From `02_NON_NEGOTIABLES.md` (App Promise / North Star)**

| Principle | Module 2 Alignment |
|-----------|-------------------|
| **Observation Before Conclusion** | `symptom` nodes store what users observe; `failure_mode` nodes are hypotheses, not user diagnoses |
| **Evidence Before Assumption** | Relationships are explicit edges with weights — reasoning traverses structure, not free-form AI |
| **Privacy Before Surveillance** | Graph tables hold platform knowledge only; no household IDs, addresses, or user media |
| **Offline-First Core Path** | `slug` + `graph_version` enable full-graph offline bundles via `fetchGraphSnapshot()` |
| **Learn Only From Verified Outcomes** | `kg_graph_versions` supports reversible, versioned content updates |
| **Explainability Before Fluency** | Edge types are named and traceable (e.g. `suggests`, `produces`) for “why this hypothesis” |

**One-Line App Promise:** Observe → Evidence → Reason → Explain → Stay Safe → Remember → Improve only from verified reality.

---

## Build Instructions

1. **Apply migration** — run `supabase/migrations/20260716000002_create_knowledge_graph.sql` after Module 01.
2. **No seed data yet** — tables start empty except version tag `KG-v0.1-structure`.
3. **Dart models** — `lib/models/knowledge_graph.dart` (node types, edge types, models).
4. **Service** — `lib/services/knowledge_graph_service.dart` (create, query, offline snapshot).
5. **RLS** — authenticated users read; writes via service role during future seeding module.
6. **Do NOT add** — reasoning engine, full seed data, AR, predictive logic, or household links.

### Example usage (after seeding module populates data)

```dart
final kg = KnowledgeGraphService();

// Seeding script (service role) — structure demo only
final dishwasher = await kg.createNode(
  nodeType: KgNodeType.applianceCategory,
  slug: 'dishwasher',
  name: 'Dishwasher',
  graphVersion: 'KG-v0.1-structure',
);

final standingWater = await kg.createNode(
  nodeType: KgNodeType.symptom,
  slug: 'standing-water',
  name: 'Standing water in the bottom',
  description: 'Water remains visible after a cycle completes.',
  graphVersion: 'KG-v0.1-structure',
);

final drainObstruction = await kg.createNode(
  nodeType: KgNodeType.failureMode,
  slug: 'drain-obstruction',
  name: 'Drain obstruction',
  graphVersion: 'KG-v0.1-structure',
);

await kg.createEdge(
  sourceNodeId: standingWater.id,
  targetNodeId: drainObstruction.id,
  relationType: KgRelationType.suggests,
  weight: 0.7,
  graphVersion: 'KG-v0.1-structure',
);

// Reasoning entry point (read-only, any authenticated user)
final hypotheses = await kg.getFailureModesForSymptom(standingWater.id);

// Offline bundle
final snapshot = await kg.fetchGraphSnapshot();
// Cache snapshot.nodes + snapshot.edges locally; check snapshot.version on sync
```

---

## Output

Implementation files (same style as Module 01):

| File | Purpose |
|------|---------|
| `supabase/migrations/20260716000002_create_knowledge_graph.sql` | Schema: versions, nodes, edges, RLS |
| `lib/models/knowledge_graph.dart` | `KgNode`, `KgEdge`, enums, `KgRelatedNode` |
| `lib/services/knowledge_graph_service.dart` | CRUD + relationship queries + offline snapshot |

### Graph topology (Module 02 — structure only)

```
appliance_category
    │
    └──[contains]──► subsystem
                          │
                          └──[contains]──► component
                                               ▲
                                               │
failure_mode ──[affects]───────────────────────┘
    │
    ├──[produces]──► symptom
    ├──[applies_to]──► appliance_category
    │
symptom ──[suggests]──► failure_mode   ← reasoning entry point
```

---

*Next module: Knowledge Graph Seeding (populate nodes/edges for MVP categories).*
