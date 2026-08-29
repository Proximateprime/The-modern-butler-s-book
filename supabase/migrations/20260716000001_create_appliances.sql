-- Module 01: Appliance Table
-- The Modern Butler's Book — Volume VIII, Chapter 3
--
-- Central entity for repair sessions, symptoms, evidence, and maintenance.
-- Privacy-first: no home address, no photos, no floor plans in this table.
-- Offline-ready: sync_version supports local-first conflict resolution later.

-- ---------------------------------------------------------------------------
-- Households (minimal stub — expanded in a future module)
-- Every appliance belongs to exactly one household.
-- ---------------------------------------------------------------------------
create table if not exists public.households (
  id            uuid primary key default gen_random_uuid(),
  name          text,                          -- optional friendly label, e.g. "Home"
  owner_user_id uuid not null references auth.users (id) on delete cascade,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

comment on table public.households is
  'Primary organizational unit. Appliances belong to one household.';

-- ---------------------------------------------------------------------------
-- Appliances
-- ---------------------------------------------------------------------------
create table if not exists public.appliances (
  id                  uuid primary key default gen_random_uuid(),
  household_id        uuid not null references public.households (id) on delete cascade,

  -- Identity (human-readable, beginner-friendly labels)
  name                text not null,           -- e.g. "Kitchen Dishwasher"
  category            text not null,           -- e.g. "Dishwasher" — extensible text, not enum
  manufacturer        text,
  model_number        text,
  serial_number       text,                    -- optional; user-controlled

  -- General location only — no maps, no addresses (Privacy Before Surveillance)
  location            text,                    -- e.g. "Kitchen", "Laundry Room"

  -- Optional physical context (all nullable — never required at onboarding)
  installation_date   date,
  estimated_age_years smallint check (estimated_age_years is null or estimated_age_years >= 0),
  energy_source       text,                    -- e.g. "electric", "gas"

  -- Lifecycle: active → retired → archived (never hard-delete repair history)
  status              text not null default 'active'
                      check (status in ('active', 'retired', 'archived')),

  -- Offline sync support (local storage will compare this on sync)
  sync_version        integer not null default 1,

  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

comment on table public.appliances is
  'Physical appliance anchor. Repair history and maintenance attach here in later modules.';
comment on column public.appliances.location is
  'General room label only — never a home address or floor plan.';
comment on column public.appliances.sync_version is
  'Incremented on each update for offline-first conflict resolution.';

-- Fast lookup: all appliances in a household (most common query)
create index if not exists appliances_household_id_idx
  on public.appliances (household_id);

create index if not exists appliances_status_idx
  on public.appliances (household_id, status);

-- ---------------------------------------------------------------------------
-- Auto-update updated_at
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger households_set_updated_at
  before update on public.households
  for each row execute function public.set_updated_at();

create trigger appliances_set_updated_at
  before update on public.appliances
  for each row execute function public.set_updated_at();

-- Bump sync_version whenever an appliance row changes (offline sync hook)
create or replace function public.bump_appliance_sync_version()
returns trigger
language plpgsql
as $$
begin
  new.sync_version = old.sync_version + 1;
  return new;
end;
$$;

create trigger appliances_bump_sync_version
  before update on public.appliances
  for each row execute function public.bump_appliance_sync_version();

-- ---------------------------------------------------------------------------
-- Row Level Security
-- Users may only access households they own (membership expands later).
-- ---------------------------------------------------------------------------
alter table public.households enable row level security;
alter table public.appliances enable row level security;

create policy "Users can view their own households"
  on public.households for select
  using (owner_user_id = auth.uid());

create policy "Users can create their own households"
  on public.households for insert
  with check (owner_user_id = auth.uid());

create policy "Users can update their own households"
  on public.households for update
  using (owner_user_id = auth.uid());

create policy "Users can delete their own households"
  on public.households for delete
  using (owner_user_id = auth.uid());

create policy "Users can view appliances in their households"
  on public.appliances for select
  using (
    exists (
      select 1 from public.households h
      where h.id = appliances.household_id
        and h.owner_user_id = auth.uid()
    )
  );

create policy "Users can insert appliances in their households"
  on public.appliances for insert
  with check (
    exists (
      select 1 from public.households h
      where h.id = appliances.household_id
        and h.owner_user_id = auth.uid()
    )
  );

create policy "Users can update appliances in their households"
  on public.appliances for update
  using (
    exists (
      select 1 from public.households h
      where h.id = appliances.household_id
        and h.owner_user_id = auth.uid()
    )
  );

create policy "Users can delete appliances in their households"
  on public.appliances for delete
  using (
    exists (
      select 1 from public.households h
      where h.id = appliances.household_id
        and h.owner_user_id = auth.uid()
    )
  );
