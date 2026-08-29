-- Module 02: Knowledge Graph Structure
-- The Modern Butler's Book — Volume VIII, Chapter 7
--
-- Platform engineering knowledge — NOT household data.
-- Stores nodes (categories, subsystems, parts, symptoms, failure modes)
-- and directed edges (contains, produces, suggests, etc.).
-- Seeding data arrives in a later module; this migration defines structure only.

-- ---------------------------------------------------------------------------
-- Graph versions — every node and edge is tagged for offline bundles & rollback
-- ---------------------------------------------------------------------------
create table if not exists public.kg_graph_versions (
  version       text primary key,              -- e.g. 'KG-v0.1-structure'
  description   text,
  published_at  timestamptz not null default now(),
  is_current    boolean not null default false
);

comment on table public.kg_graph_versions is
  'Version tags for Knowledge Graph content. Updates are reversible per Non-Negotiable #8.';

-- Seed the initial structural version (no nodes yet — structure only)
insert into public.kg_graph_versions (version, description, is_current)
values ('KG-v0.1-structure', 'Module 02 — empty graph skeleton', true)
on conflict (version) do nothing;

-- ---------------------------------------------------------------------------
-- Nodes — unified table with type discriminator (extensible without redesign)
-- ---------------------------------------------------------------------------
create table if not exists public.kg_nodes (
  id            uuid primary key default gen_random_uuid(),
  node_type     text not null
                check (node_type in (
                  'appliance_category',
                  'subsystem',
                  'component',
                  'symptom',
                  'failure_mode'
                )),
  slug          text not null,               -- stable key for offline sync, e.g. 'standing-water'
  name          text not null,               -- beginner-friendly label shown in the UI
  description   text,                        -- optional plain-language explanation

  -- Flexible metadata for later modules (difficulty, source, accessibility…)
  metadata      jsonb not null default '{}',

  graph_version text not null references public.kg_graph_versions (version),
  is_active     boolean not null default true,

  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),

  constraint kg_nodes_slug_per_type unique (node_type, slug)
);

comment on table public.kg_nodes is
  'Knowledge Graph nodes. Engineering facts only — no household or personal data.';
comment on column public.kg_nodes.node_type is
  'appliance_category | subsystem | component | symptom | failure_mode';
comment on column public.kg_nodes.slug is
  'Stable identifier for offline bundles and seed scripts.';
comment on column public.kg_nodes.metadata is
  'Extensible key-value store. Seeding module adds source, difficulty, etc.';

create index if not exists kg_nodes_type_idx on public.kg_nodes (node_type);
create index if not exists kg_nodes_active_idx on public.kg_nodes (node_type, is_active);

-- ---------------------------------------------------------------------------
-- Edges — first-class relationships with optional weight (confidence / frequency)
-- ---------------------------------------------------------------------------
create table if not exists public.kg_edges (
  id              uuid primary key default gen_random_uuid(),
  source_node_id  uuid not null references public.kg_nodes (id) on delete cascade,
  target_node_id  uuid not null references public.kg_nodes (id) on delete cascade,
  relation_type   text not null
                  check (relation_type in (
                    'contains',    -- category → subsystem, subsystem → component
                    'belongs_to',  -- component → subsystem
                    'produces',    -- failure_mode → symptom
                    'suggests',    -- symptom → failure_mode (reasoning entry point)
                    'affects',     -- failure_mode → component
                    'applies_to'   -- failure_mode → appliance_category
                  )),
  weight          numeric(4, 3) not null default 0.500
                  check (weight >= 0 and weight <= 1),

  metadata        jsonb not null default '{}',
  graph_version   text not null references public.kg_graph_versions (version),
  is_active       boolean not null default true,

  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),

  constraint kg_edges_no_self_loop check (source_node_id <> target_node_id),
  constraint kg_edges_unique_rel unique (source_node_id, target_node_id, relation_type)
);

comment on table public.kg_edges is
  'Directed relationships between nodes. Traversed by the Reasoning Engine in later modules.';
comment on column public.kg_edges.relation_type is
  'Edge semantics per Volume VIII Ch.7 — e.g. symptom -[suggests]-> failure_mode';
comment on column public.kg_edges.weight is
  'Association strength (0–1). Used for ranking hypotheses, not as certainty.';

create index if not exists kg_edges_source_idx on public.kg_edges (source_node_id);
create index if not exists kg_edges_target_idx on public.kg_edges (target_node_id);
create index if not exists kg_edges_relation_idx on public.kg_edges (relation_type);
create index if not exists kg_edges_source_relation_idx
  on public.kg_edges (source_node_id, relation_type);

-- ---------------------------------------------------------------------------
-- Timestamps (reuse set_updated_at from Module 01 if it already exists)
-- ---------------------------------------------------------------------------
create trigger kg_nodes_set_updated_at
  before update on public.kg_nodes
  for each row execute function public.set_updated_at();

create trigger kg_edges_set_updated_at
  before update on public.kg_edges
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- Graph is platform knowledge: authenticated users read; writes via service role.
-- Household data never enters these tables (Privacy Before Surveillance).
-- ---------------------------------------------------------------------------
alter table public.kg_graph_versions enable row level security;
alter table public.kg_nodes enable row level security;
alter table public.kg_edges enable row level security;

create policy "Authenticated users can read graph versions"
  on public.kg_graph_versions for select
  to authenticated
  using (true);

create policy "Authenticated users can read active nodes"
  on public.kg_nodes for select
  to authenticated
  using (is_active = true);

create policy "Authenticated users can read active edges"
  on public.kg_edges for select
  to authenticated
  using (is_active = true);
