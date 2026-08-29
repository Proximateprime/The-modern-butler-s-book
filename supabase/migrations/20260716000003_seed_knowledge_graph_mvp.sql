-- Module 03: Knowledge Graph Seeding — MVP Phase 1
-- The Modern Butler's Book — 04_KNOWLEDGE_GRAPH_SEEDING_PLAN.md
--
-- Populates kg_nodes + kg_edges for 4 MVP categories:
--   Dishwasher, Washing Machine, Dryer, Refrigerator/Freezer
--
-- Phase 1 depth: categories → subsystems → components + core failure modes & symptoms
-- graph_version: KG-v0.1-mvp
-- Idempotent: safe to re-run (ON CONFLICT DO NOTHING)

-- ---------------------------------------------------------------------------
-- Promote MVP graph version
-- ---------------------------------------------------------------------------
update public.kg_graph_versions set is_current = false where is_current = true;

insert into public.kg_graph_versions (version, description, is_current)
values (
  'KG-v0.1-mvp',
  'Module 03 — MVP Phase 1 seed (4 categories, core symptoms & failure modes)',
  true
)
on conflict (version) do update set is_current = true;

-- ---------------------------------------------------------------------------
-- Helper: standard metadata for seeded nodes
-- ---------------------------------------------------------------------------
-- {"source":"MVP Phase 1 seed","reviewed":"2026-07-16","phase":1}

-- ===========================================================================
-- APPLIANCE CATEGORIES (4)
-- ===========================================================================
insert into public.kg_nodes (node_type, slug, name, description, metadata, graph_version) values
  ('appliance_category', 'dishwasher', 'Dishwasher',
   'Built-in or portable machine that washes dishes with water, detergent, and heat.',
   '{"source":"MVP Phase 1 seed","reviewed":"2026-07-16"}', 'KG-v0.1-mvp'),
  ('appliance_category', 'washing-machine', 'Washing Machine',
   'Clothes washer that fills, agitates or tumbles, drains, and spins.',
   '{"source":"MVP Phase 1 seed","reviewed":"2026-07-16"}', 'KG-v0.1-mvp'),
  ('appliance_category', 'dryer', 'Dryer',
   'Clothes dryer that tumbles laundry while heated air removes moisture.',
   '{"source":"MVP Phase 1 seed","reviewed":"2026-07-16"}', 'KG-v0.1-mvp'),
  ('appliance_category', 'refrigerator-freezer', 'Refrigerator / Freezer',
   'Keeps food cold; may include a separate freezer compartment or section.',
   '{"source":"MVP Phase 1 seed","reviewed":"2026-07-16"}', 'KG-v0.1-mvp')
on conflict (node_type, slug) do nothing;

-- ===========================================================================
-- SUBSYSTEMS (16 — 4 per category)
-- ===========================================================================
insert into public.kg_nodes (node_type, slug, name, description, metadata, graph_version) values
  -- Dishwasher
  ('subsystem', 'dishwasher-drain-system', 'Drain System',
   'Moves wastewater out of the tub after each cycle.',
   '{"source":"MVP Phase 1 seed","category":"dishwasher"}', 'KG-v0.1-mvp'),
  ('subsystem', 'dishwasher-water-supply', 'Water Supply',
   'Brings fresh water into the dishwasher during fill.',
   '{"source":"MVP Phase 1 seed","category":"dishwasher"}', 'KG-v0.1-mvp'),
  ('subsystem', 'dishwasher-wash-system', 'Wash System',
   'Sprays water and detergent to clean dishes.',
   '{"source":"MVP Phase 1 seed","category":"dishwasher"}', 'KG-v0.1-mvp'),
  ('subsystem', 'dishwasher-door-latch', 'Door & Latch',
   'Keeps the door sealed during operation.',
   '{"source":"MVP Phase 1 seed","category":"dishwasher"}', 'KG-v0.1-mvp'),
  -- Washing Machine
  ('subsystem', 'washer-water-supply', 'Water Supply',
   'Controls incoming water for wash and rinse fills.',
   '{"source":"MVP Phase 1 seed","category":"washing-machine"}', 'KG-v0.1-mvp'),
  ('subsystem', 'washer-drain-system', 'Drain System',
   'Pumps water out during drain and spin.',
   '{"source":"MVP Phase 1 seed","category":"washing-machine"}', 'KG-v0.1-mvp'),
  ('subsystem', 'washer-drive-spin', 'Drive & Spin',
   'Agitates or tumbles the drum and spins out water.',
   '{"source":"MVP Phase 1 seed","category":"washing-machine"}', 'KG-v0.1-mvp'),
  ('subsystem', 'washer-door-latch', 'Door & Latch',
   'Locks the door during high-speed spin.',
   '{"source":"MVP Phase 1 seed","category":"washing-machine"}', 'KG-v0.1-mvp'),
  -- Dryer
  ('subsystem', 'dryer-airflow', 'Airflow System',
   'Moves heated air through the drum and out the exhaust.',
   '{"source":"MVP Phase 1 seed","category":"dryer"}', 'KG-v0.1-mvp'),
  ('subsystem', 'dryer-heating', 'Heating System',
   'Produces heat for drying (electric element or gas burner).',
   '{"source":"MVP Phase 1 seed","category":"dryer"}', 'KG-v0.1-mvp'),
  ('subsystem', 'dryer-drive-system', 'Drive System',
   'Turns the drum via belt and motor.',
   '{"source":"MVP Phase 1 seed","category":"dryer"}', 'KG-v0.1-mvp'),
  ('subsystem', 'dryer-door-latch', 'Door & Latch',
   'Ensures the door is closed before heat and tumble start.',
   '{"source":"MVP Phase 1 seed","category":"dryer"}', 'KG-v0.1-mvp'),
  -- Refrigerator / Freezer
  ('subsystem', 'refrigerator-cooling', 'Cooling System',
   'Moves heat out of the cabinet to keep food cold.',
   '{"source":"MVP Phase 1 seed","category":"refrigerator-freezer"}', 'KG-v0.1-mvp'),
  ('subsystem', 'refrigerator-defrost', 'Defrost System',
   'Prevents excessive frost on evaporator coils.',
   '{"source":"MVP Phase 1 seed","category":"refrigerator-freezer"}', 'KG-v0.1-mvp'),
  ('subsystem', 'refrigerator-door-seal', 'Door Seal',
   'Gasket that seals the door to keep cold air in.',
   '{"source":"MVP Phase 1 seed","category":"refrigerator-freezer"}', 'KG-v0.1-mvp'),
  ('subsystem', 'refrigerator-controls', 'Controls',
   'Thermostat and board that regulate temperature.',
   '{"source":"MVP Phase 1 seed","category":"refrigerator-freezer"}', 'KG-v0.1-mvp')
on conflict (node_type, slug) do nothing;

-- ===========================================================================
-- COMPONENTS (32 — 2 per subsystem)
-- ===========================================================================
insert into public.kg_nodes (node_type, slug, name, description, metadata, graph_version) values
  -- Dishwasher components
  ('component', 'dishwasher-drain-pump', 'Drain Pump', 'Pumps water out of the tub.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'dishwasher-drain-hose', 'Drain Hose', 'Carries wastewater to the sink drain or disposal.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'dishwasher-inlet-valve', 'Inlet Valve', 'Opens to let water enter during fill.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'dishwasher-float-switch', 'Float Switch', 'Detects water level in the tub.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'dishwasher-spray-arms', 'Spray Arms', 'Rotate and spray water onto dishes.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'dishwasher-filter', 'Filter', 'Traps food debris in the wash water.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'dishwasher-door-seal', 'Door Seal', 'Rubber gasket around the door opening.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'dishwasher-door-latch', 'Door Latch', 'Mechanism that locks the door closed.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  -- Washer components
  ('component', 'washer-inlet-valve', 'Inlet Valve', 'Controls hot and cold water entry.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'washer-water-level-switch', 'Water Level Switch', 'Senses fill level in the drum.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'washer-drain-pump', 'Drain Pump', 'Removes water during drain cycle.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'washer-drain-hose', 'Drain Hose', 'Routes water to the standpipe or sink.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'washer-drive-belt', 'Drive Belt', 'Transfers motor power to the drum.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'washer-motor', 'Drive Motor', 'Powers agitation and spin.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'washer-door-lock', 'Door Lock', 'Prevents opening during spin.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'washer-lid-switch', 'Lid/Door Switch', 'Confirms the door is closed before spin.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  -- Dryer components
  ('component', 'dryer-lint-trap', 'Lint Trap', 'Catches lint before it enters the exhaust.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'dryer-exhaust-duct', 'Exhaust Duct', 'Carries moist air outside.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'dryer-heating-element', 'Heating Element', 'Electric coil that produces dry heat.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'dryer-thermal-fuse', 'Thermal Fuse', 'Safety cutoff if overheating occurs.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'dryer-drum-belt', 'Drum Belt', 'Rotates the drum.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'dryer-drum-rollers', 'Drum Rollers', 'Support the drum as it turns.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'dryer-door-switch', 'Door Switch', 'Detects whether the door is closed.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'dryer-door-latch', 'Door Latch', 'Keeps the door shut during operation.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  -- Refrigerator components
  ('component', 'refrigerator-condenser-coils', 'Condenser Coils', 'Release heat to the room air.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'refrigerator-compressor', 'Compressor', 'Pumps refrigerant through the cooling loop.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'refrigerator-evaporator-coils', 'Evaporator Coils', 'Absorb heat inside the cabinet.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'refrigerator-defrost-heater', 'Defrost Heater', 'Melts frost on the evaporator.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'refrigerator-door-gasket', 'Door Gasket', 'Flexible seal around door edges.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'refrigerator-door-hinge', 'Door Hinge', 'Allows the door to swing and close evenly.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'refrigerator-thermostat', 'Thermostat', 'Senses temperature and cycles cooling.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp'),
  ('component', 'refrigerator-control-board', 'Control Board', 'Electronic brain for temperature and defrost.', '{"source":"MVP Phase 1 seed"}', 'KG-v0.1-mvp')
on conflict (node_type, slug) do nothing;

-- ===========================================================================
-- SYMPTOMS (14 — observations only, never diagnoses)
-- ===========================================================================
insert into public.kg_nodes (node_type, slug, name, description, metadata, graph_version) values
  ('symptom', 'standing-water', 'Standing water after cycle',
   'You can see water sitting in the bottom after the cycle finishes.',
   '{"source":"MVP Phase 1 seed","observation_type":"visual"}', 'KG-v0.1-mvp'),
  ('symptom', 'dishes-not-clean', 'Dishes not getting clean',
   'Food residue or film remains on dishes after a normal cycle.',
   '{"source":"MVP Phase 1 seed","observation_type":"visual"}', 'KG-v0.1-mvp'),
  ('symptom', 'water-leak-on-floor', 'Water on the floor',
   'You notice water pooling on the floor near the appliance.',
   '{"source":"MVP Phase 1 seed","observation_type":"visual"}', 'KG-v0.1-mvp'),
  ('symptom', 'grinding-noise', 'Grinding or humming noise',
   'You hear an unusual grinding, humming, or buzzing sound during operation.',
   '{"source":"MVP Phase 1 seed","observation_type":"auditory"}', 'KG-v0.1-mvp'),
  ('symptom', 'wont-drain', 'Water will not drain',
   'Water stays in the tub; drain cycle seems ineffective.',
   '{"source":"MVP Phase 1 seed","observation_type":"visual"}', 'KG-v0.1-mvp'),
  ('symptom', 'wont-fill', 'Will not fill with water',
   'The appliance starts but little or no water enters.',
   '{"source":"MVP Phase 1 seed","observation_type":"visual"}', 'KG-v0.1-mvp'),
  ('symptom', 'wont-spin', 'Will not spin or agitate',
   'The drum does not turn during wash or spin cycles.',
   '{"source":"MVP Phase 1 seed","observation_type":"visual"}', 'KG-v0.1-mvp'),
  ('symptom', 'excessive-vibration', 'Excessive shaking or vibration',
   'The machine shakes, walks, or bangs more than usual.',
   '{"source":"MVP Phase 1 seed","observation_type":"tactile"}', 'KG-v0.1-mvp'),
  ('symptom', 'clothes-not-drying', 'Clothes still damp after cycle',
   'Laundry feels wet or very damp when the dryer cycle ends.',
   '{"source":"MVP Phase 1 seed","observation_type":"tactile"}', 'KG-v0.1-mvp'),
  ('symptom', 'burning-smell', 'Burning or hot electrical smell',
   'You smell something burning or unusually hot during use.',
   '{"source":"MVP Phase 1 seed","observation_type":"olfactory"}', 'KG-v0.1-mvp'),
  ('symptom', 'loud-thumping', 'Loud thumping while tumbling',
   'A rhythmic thump or bang occurs as the drum turns.',
   '{"source":"MVP Phase 1 seed","observation_type":"auditory"}', 'KG-v0.1-mvp'),
  ('symptom', 'wont-start', 'Will not start',
   'Nothing happens when you try to start a cycle.',
   '{"source":"MVP Phase 1 seed","observation_type":"behavioral"}', 'KG-v0.1-mvp'),
  ('symptom', 'not-cooling', 'Not keeping food cold enough',
   'Food feels warmer than expected; fridge section not cold.',
   '{"source":"MVP Phase 1 seed","observation_type":"tactile"}', 'KG-v0.1-mvp'),
  ('symptom', 'frost-buildup', 'Heavy frost or ice buildup',
   'You see thick frost or ice inside the freezer section.',
   '{"source":"MVP Phase 1 seed","observation_type":"visual"}', 'KG-v0.1-mvp'),
  ('symptom', 'running-constantly', 'Seems to run all the time',
   'The compressor or fan runs almost continuously.',
   '{"source":"MVP Phase 1 seed","observation_type":"auditory"}', 'KG-v0.1-mvp')
on conflict (node_type, slug) do nothing;

-- ===========================================================================
-- FAILURE MODES (16 — hypotheses, not user diagnoses; 4 per category)
-- ===========================================================================
insert into public.kg_nodes (node_type, slug, name, description, metadata, graph_version) values
  -- Dishwasher
  ('failure_mode', 'dishwasher-drain-obstruction', 'Drain path obstruction',
   'Food debris or objects block the drain filter, hose, or pump inlet.',
   '{"source":"MVP Phase 1 seed","difficulty":"beginner","category":"dishwasher"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'dishwasher-drain-pump-failure', 'Drain pump not moving water',
   'The drain pump runs but does not effectively move water out.',
   '{"source":"MVP Phase 1 seed","difficulty":"intermediate","category":"dishwasher"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'dishwasher-clogged-filter', 'Clogged wash filter',
   'The filter is blocked, reducing spray pressure and cleaning.',
   '{"source":"MVP Phase 1 seed","difficulty":"beginner","category":"dishwasher"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'dishwasher-door-seal-leak', 'Door seal leaking',
   'The door gasket or seal allows water to escape during wash.',
   '{"source":"MVP Phase 1 seed","difficulty":"beginner","category":"dishwasher"}', 'KG-v0.1-mvp'),
  -- Washer
  ('failure_mode', 'washer-drain-clog', 'Drain clog or blockage',
   'Lint, debris, or a kinked hose prevents water from draining.',
   '{"source":"MVP Phase 1 seed","difficulty":"beginner","category":"washing-machine"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'washer-inlet-valve-fault', 'Inlet valve not opening',
   'The water inlet valve fails to open or opens only partially.',
   '{"source":"MVP Phase 1 seed","difficulty":"intermediate","category":"washing-machine"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'washer-worn-drive-belt', 'Worn or broken drive belt',
   'The belt that drives the drum is loose, worn, or broken.',
   '{"source":"MVP Phase 1 seed","difficulty":"intermediate","category":"washing-machine"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'washer-unbalanced-load', 'Unbalanced load',
   'Laundry is unevenly distributed, preventing normal spin.',
   '{"source":"MVP Phase 1 seed","difficulty":"beginner","category":"washing-machine"}', 'KG-v0.1-mvp'),
  -- Dryer
  ('failure_mode', 'dryer-lint-buildup', 'Lint buildup in trap or duct',
   'Restricted airflow from a full lint trap or blocked exhaust.',
   '{"source":"MVP Phase 1 seed","difficulty":"beginner","category":"dryer"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'dryer-heating-element-failure', 'Heating element failure',
   'The electric heating element does not produce heat.',
   '{"source":"MVP Phase 1 seed","difficulty":"intermediate","category":"dryer"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'dryer-worn-drum-belt', 'Worn or broken drum belt',
   'The belt that turns the drum is worn, stretched, or broken.',
   '{"source":"MVP Phase 1 seed","difficulty":"intermediate","category":"dryer"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'dryer-drum-roller-wear', 'Worn drum rollers',
   'Support rollers are worn, causing thumping and drag.',
   '{"source":"MVP Phase 1 seed","difficulty":"intermediate","category":"dryer"}', 'KG-v0.1-mvp'),
  -- Refrigerator
  ('failure_mode', 'refrigerator-dirty-condenser-coils', 'Dirty condenser coils',
   'Dust on condenser coils reduces cooling efficiency.',
   '{"source":"MVP Phase 1 seed","difficulty":"beginner","category":"refrigerator-freezer"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'refrigerator-door-gasket-leak', 'Door gasket leak',
   'A worn or dirty gasket lets warm air in, raising temperature.',
   '{"source":"MVP Phase 1 seed","difficulty":"beginner","category":"refrigerator-freezer"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'refrigerator-defrost-failure', 'Defrost system not working',
   'Frost accumulates because defrost heater or timer/control failed.',
   '{"source":"MVP Phase 1 seed","difficulty":"intermediate","category":"refrigerator-freezer"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'refrigerator-evaporator-frost', 'Evaporator frost blockage',
   'Heavy frost on evaporator coils blocks airflow inside.',
   '{"source":"MVP Phase 1 seed","difficulty":"intermediate","category":"refrigerator-freezer"}', 'KG-v0.1-mvp')
on conflict (node_type, slug) do nothing;

-- George Aug 28 nodes (also in 20260828000001 for already-applied DBs)
insert into public.kg_nodes (node_type, slug, name, description, metadata, graph_version) values
  ('component', 'washer-suspension', 'Tub suspension',
   'Springs, rods, or dampers that hold the tub.',
   '{"source":"George Aug 28 graph fix"}', 'KG-v0.1-mvp'),
  ('component', 'refrigerator-drip-pan', 'Drip pan',
   'Catches defrost water under the cabinet.',
   '{"source":"George Aug 28 graph fix"}', 'KG-v0.1-mvp'),
  ('symptom', 'drum-does-not-turn', 'Motor runs, drum does not turn',
   'You can hear the motor but the dryer drum stays still. Not a no-start.',
   '{"source":"George Aug 28 graph fix","observation_type":"behavioral"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'dryer-thermal-fuse-open', 'Open thermal fuse',
   'The thermal fuse opened after overheating, often from restricted airflow.',
   '{"source":"George Aug 28 graph fix","difficulty":"intermediate","category":"dryer"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'dryer-door-switch-failure', 'Door switch not closing the start circuit',
   'Nothing happens when you press start because the door switch does not see the door closed.',
   '{"source":"George Aug 28 graph fix","difficulty":"beginner","category":"dryer"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'washer-lid-switch-failure', 'Lid or door switch not closed',
   'Washer will not start if the lid/door switch does not see the opening closed.',
   '{"source":"George Aug 28 graph fix","difficulty":"beginner","category":"washing-machine"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'washer-drain-pump-failure', 'Drain pump debris or failure',
   'Debris in the washer pump can grind. Not a dryer failure.',
   '{"source":"George Aug 28 graph fix","difficulty":"intermediate","category":"washing-machine"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'washer-drain-hose-leak', 'Drain hose leak',
   'Water leaves at the washer drain hose or coupling.',
   '{"source":"George Aug 28 graph fix","difficulty":"beginner","category":"washing-machine"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'washer-supply-line-leak', 'Supply hose leak',
   'Water leaves at an accessible fill hose or coupling. No gas-train work.',
   '{"source":"George Aug 28 graph fix","difficulty":"beginner","category":"washing-machine"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'dishwasher-float-switch-stuck', 'Float switch stuck or failed',
   'The float is jammed up (will not fill) or stuck down (standing water). Do not bypass the switch.',
   '{"source":"George Aug 28 graph fix","difficulty":"beginner","category":"dishwasher"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'dishwasher-drain-hose-leak', 'Drain hose leak or loose connection',
   'Water on the floor from the dishwasher drain hose or sink connection.',
   '{"source":"George Aug 28 graph fix","difficulty":"beginner","category":"dishwasher"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'refrigerator-drip-pan-overflow', 'Drip pan overflow or blocked defrost drain',
   'A full drip pan or blocked visible drain can put water on the floor.',
   '{"source":"George Aug 28 graph fix","difficulty":"beginner","category":"refrigerator-freezer"}', 'KG-v0.1-mvp'),
  ('failure_mode', 'refrigerator-compressor-sealed-fault', 'Sealed-system compressor fault',
   'A compressor that will not pump is sealed-system work. Not beginner DIY.',
   '{"source":"George Aug 28 graph fix","difficulty":"professional","safety":"sealed_system","safety_gate":"professional_sealed","beginner_diy":false,"category":"refrigerator-freezer"}', 'KG-v0.1-mvp')
on conflict (node_type, slug) do nothing;

-- ===========================================================================
-- EDGES: category → subsystem (contains)
-- ===========================================================================
insert into public.kg_edges (source_node_id, target_node_id, relation_type, weight, graph_version, metadata)
select s.id, t.id, 'contains', 1.000, 'KG-v0.1-mvp', '{"note":"Category contains main subsystem"}'::jsonb
from public.kg_nodes s, public.kg_nodes t
where s.node_type = 'appliance_category' and t.node_type = 'subsystem'
  and (
    (s.slug = 'dishwasher' and t.slug in ('dishwasher-drain-system','dishwasher-water-supply','dishwasher-wash-system','dishwasher-door-latch'))
    or (s.slug = 'washing-machine' and t.slug in ('washer-water-supply','washer-drain-system','washer-drive-spin','washer-door-latch'))
    or (s.slug = 'dryer' and t.slug in ('dryer-airflow','dryer-heating','dryer-drive-system','dryer-door-latch'))
    or (s.slug = 'refrigerator-freezer' and t.slug in ('refrigerator-cooling','refrigerator-defrost','refrigerator-door-seal','refrigerator-controls'))
  )
on conflict (source_node_id, target_node_id, relation_type) do nothing;

-- ===========================================================================
-- EDGES: subsystem → component (contains)
-- ===========================================================================
insert into public.kg_edges (source_node_id, target_node_id, relation_type, weight, graph_version, metadata)
select s.id, t.id, 'contains', 1.000, 'KG-v0.1-mvp', '{"note":"Subsystem contains serviceable component"}'::jsonb
from public.kg_nodes s, public.kg_nodes t
where s.node_type = 'subsystem' and t.node_type = 'component'
  and (
    (s.slug = 'dishwasher-drain-system' and t.slug in ('dishwasher-drain-pump','dishwasher-drain-hose'))
    or (s.slug = 'dishwasher-water-supply' and t.slug in ('dishwasher-inlet-valve','dishwasher-float-switch'))
    or (s.slug = 'dishwasher-wash-system' and t.slug in ('dishwasher-spray-arms','dishwasher-filter'))
    or (s.slug = 'dishwasher-door-latch' and t.slug in ('dishwasher-door-seal','dishwasher-door-latch'))
    or (s.slug = 'washer-water-supply' and t.slug in ('washer-inlet-valve','washer-water-level-switch'))
    or (s.slug = 'washer-drain-system' and t.slug in ('washer-drain-pump','washer-drain-hose'))
    or (s.slug = 'washer-drive-spin' and t.slug in ('washer-drive-belt','washer-motor','washer-suspension'))
    or (s.slug = 'washer-door-latch' and t.slug in ('washer-door-lock','washer-lid-switch'))
    or (s.slug = 'dryer-airflow' and t.slug in ('dryer-lint-trap','dryer-exhaust-duct'))
    or (s.slug = 'dryer-heating' and t.slug in ('dryer-heating-element','dryer-thermal-fuse'))
    or (s.slug = 'dryer-drive-system' and t.slug in ('dryer-drum-belt','dryer-drum-rollers'))
    or (s.slug = 'dryer-door-latch' and t.slug in ('dryer-door-switch','dryer-door-latch'))
    or (s.slug = 'refrigerator-cooling' and t.slug in ('refrigerator-condenser-coils','refrigerator-compressor','refrigerator-evaporator-coils','refrigerator-drip-pan'))
    or (s.slug = 'refrigerator-defrost' and t.slug in ('refrigerator-evaporator-coils','refrigerator-defrost-heater'))
    or (s.slug = 'refrigerator-door-seal' and t.slug in ('refrigerator-door-gasket','refrigerator-door-hinge'))
    or (s.slug = 'refrigerator-controls' and t.slug in ('refrigerator-thermostat','refrigerator-control-board'))
  )
on conflict (source_node_id, target_node_id, relation_type) do nothing;

-- ===========================================================================
-- EDGES: failure_mode → appliance_category (applies_to)
-- ===========================================================================
insert into public.kg_edges (source_node_id, target_node_id, relation_type, weight, graph_version, metadata)
select f.id, c.id, 'applies_to', 1.000, 'KG-v0.1-mvp', '{"note":"Failure mode relevant to this appliance type"}'::jsonb
from public.kg_nodes f, public.kg_nodes c
where f.node_type = 'failure_mode' and c.node_type = 'appliance_category'
  and (
    (f.slug like 'dishwasher-%' and c.slug = 'dishwasher')
    or (f.slug like 'washer-%' and c.slug = 'washing-machine')
    or (f.slug like 'dryer-%' and c.slug = 'dryer')
    or (f.slug like 'refrigerator-%' and c.slug = 'refrigerator-freezer')
  )
on conflict (source_node_id, target_node_id, relation_type) do nothing;

-- ===========================================================================
-- EDGES: failure_mode → component (affects)
-- ===========================================================================
insert into public.kg_edges (source_node_id, target_node_id, relation_type, weight, graph_version, metadata)
select f.id, t.id, 'affects', 0.800, 'KG-v0.1-mvp', '{"note":"Failure mode typically involves this component"}'::jsonb
from public.kg_nodes f, public.kg_nodes t
where f.node_type = 'failure_mode' and t.node_type = 'component'
  and (
    (f.slug = 'dishwasher-drain-obstruction' and t.slug in ('dishwasher-drain-pump','dishwasher-drain-hose','dishwasher-filter'))
    or (f.slug = 'dishwasher-drain-pump-failure' and t.slug = 'dishwasher-drain-pump')
    or (f.slug = 'dishwasher-clogged-filter' and t.slug = 'dishwasher-filter')
    or (f.slug = 'dishwasher-door-seal-leak' and t.slug = 'dishwasher-door-seal')
    or (f.slug = 'washer-drain-clog' and t.slug in ('washer-drain-pump','washer-drain-hose'))
    or (f.slug = 'washer-inlet-valve-fault' and t.slug = 'washer-inlet-valve')
    or (f.slug = 'washer-worn-drive-belt' and t.slug = 'washer-drive-belt')
    or (f.slug = 'washer-unbalanced-load' and t.slug = 'washer-suspension')
    or (f.slug = 'dryer-lint-buildup' and t.slug in ('dryer-lint-trap','dryer-exhaust-duct'))
    or (f.slug = 'dryer-heating-element-failure' and t.slug = 'dryer-heating-element')
    or (f.slug = 'dryer-worn-drum-belt' and t.slug = 'dryer-drum-belt')
    or (f.slug = 'dryer-drum-roller-wear' and t.slug = 'dryer-drum-rollers')
    or (f.slug = 'refrigerator-dirty-condenser-coils' and t.slug = 'refrigerator-condenser-coils')
    or (f.slug = 'refrigerator-door-gasket-leak' and t.slug = 'refrigerator-door-gasket')
    or (f.slug = 'refrigerator-defrost-failure' and t.slug in ('refrigerator-defrost-heater','refrigerator-control-board'))
    or (f.slug = 'refrigerator-evaporator-frost' and t.slug = 'refrigerator-evaporator-coils')
    or (f.slug = 'dryer-thermal-fuse-open' and t.slug = 'dryer-thermal-fuse')
    or (f.slug = 'dryer-door-switch-failure' and t.slug = 'dryer-door-switch')
    or (f.slug = 'washer-lid-switch-failure' and t.slug = 'washer-lid-switch')
    or (f.slug = 'washer-drain-pump-failure' and t.slug = 'washer-drain-pump')
    or (f.slug = 'dishwasher-float-switch-stuck' and t.slug = 'dishwasher-float-switch')
    or (f.slug = 'dishwasher-drain-hose-leak' and t.slug = 'dishwasher-drain-hose')
    or (f.slug = 'washer-drain-hose-leak' and t.slug = 'washer-drain-hose')
    or (f.slug = 'refrigerator-drip-pan-overflow' and t.slug = 'refrigerator-drip-pan')
    or (f.slug = 'refrigerator-compressor-sealed-fault' and t.slug = 'refrigerator-compressor')
  )
on conflict (source_node_id, target_node_id, relation_type) do nothing;

-- ===========================================================================
-- EDGES: symptom → failure_mode (suggests) — primary reasoning entry point
-- Weights are association hints, NOT certainty (honest about uncertainty).
-- ===========================================================================
insert into public.kg_edges (source_node_id, target_node_id, relation_type, weight, graph_version, metadata)
select s.id, f.id, 'suggests', w.weight, 'KG-v0.1-mvp', w.meta::jsonb
from (values
  -- Dishwasher scenarios
  ('standing-water', 'dishwasher-drain-obstruction', 0.750, '{"note":"Very common when water remains after cycle"}'),
  ('standing-water', 'dishwasher-drain-pump-failure', 0.600, '{"note":"Pump runs but water stays — possible pump issue"}'),
  ('wont-drain', 'dishwasher-drain-obstruction', 0.800, '{"note":"Blocked filter or hose is a frequent cause"}'),
  ('wont-drain', 'dishwasher-drain-pump-failure', 0.650, '{"note":"Pump may run without moving water"}'),
  ('dishes-not-clean', 'dishwasher-clogged-filter', 0.700, '{"note":"Low spray pressure from blocked filter"}'),
  ('grinding-noise', 'dishwasher-drain-pump-failure', 0.550, '{"note":"Debris in pump can cause grinding — dishwasher/washer only"}'),
  ('water-leak-on-floor', 'dishwasher-door-seal-leak', 0.650, '{"note":"Seal leak during wash can pool on floor"}'),
  ('water-leak-on-floor', 'dishwasher-drain-hose-leak', 0.600, '{"note":"Drain hose or sink coupling can drip"}'),
  ('standing-water', 'dishwasher-float-switch-stuck', 0.550, '{"note":"Float stuck down can leave standing water"}'),
  ('wont-fill', 'dishwasher-float-switch-stuck', 0.650, '{"note":"Float stuck up can block fill"}'),
  -- Washer scenarios
  ('wont-drain', 'washer-drain-clog', 0.800, '{"note":"Clogged pump or hose is common"}'),
  ('standing-water', 'washer-drain-clog', 0.700, '{"note":"Water left in drum after cycle"}'),
  ('wont-fill', 'washer-inlet-valve-fault', 0.750, '{"note":"Valve not opening is a leading cause"}'),
  ('wont-start', 'washer-lid-switch-failure', 0.700, '{"note":"Washer lid/door switch — not dryer belt"}'),
  ('grinding-noise', 'washer-drain-pump-failure', 0.550, '{"note":"Debris in washer pump can grind"}'),
  ('water-leak-on-floor', 'washer-drain-hose-leak', 0.550, '{"note":"Washer drain hose or coupling"}'),
  ('water-leak-on-floor', 'washer-supply-line-leak', 0.500, '{"note":"Accessible fill hose coupling"}'),
  ('wont-spin', 'washer-worn-drive-belt', 0.700, '{"note":"Belt slip or break stops drum motion"}'),
  ('wont-spin', 'washer-unbalanced-load', 0.650, '{"note":"Safety stop when load is uneven"}'),
  ('excessive-vibration', 'washer-unbalanced-load', 0.800, '{"note":"Heavy items on one side cause shaking"}'),
  -- Dryer scenarios
  ('clothes-not-drying', 'dryer-lint-buildup', 0.800, '{"note":"Restricted airflow is the #1 drying issue"}'),
  ('clothes-not-drying', 'dryer-heating-element-failure', 0.600, '{"note":"Air moves but no heat produced"}'),
  ('burning-smell', 'dryer-lint-buildup', 0.700, '{"note":"Lint near heat source can smell hot"}'),
  ('loud-thumping', 'dryer-drum-roller-wear', 0.750, '{"note":"Worn rollers cause rhythmic thumping"}'),
  ('wont-start', 'dryer-door-switch-failure', 0.700, '{"note":"Nothing happens — door switch, not belt"}'),
  ('drum-does-not-turn', 'dryer-worn-drum-belt', 0.750, '{"note":"Motor runs, drum does not"}'),
  ('clothes-not-drying', 'dryer-thermal-fuse-open', 0.550, '{"note":"Open thermal fuse after overheat"}'),
  -- Refrigerator scenarios
  ('not-cooling', 'refrigerator-dirty-condenser-coils', 0.700, '{"note":"Dusty coils reduce cooling efficiency"}'),
  ('not-cooling', 'refrigerator-door-gasket-leak', 0.650, '{"note":"Warm air infiltration raises temperature"}'),
  ('not-cooling', 'refrigerator-compressor-sealed-fault', 0.250, '{"note":"Professional/sealed only — not beginner DIY"}'),
  ('water-leak-on-floor', 'refrigerator-drip-pan-overflow', 0.500, '{"note":"Full drip pan or blocked defrost drain"}'),
  ('frost-buildup', 'refrigerator-defrost-failure', 0.750, '{"note":"Defrost not running leads to ice"}'),
  ('frost-buildup', 'refrigerator-evaporator-frost', 0.700, '{"note":"Blocked evaporator airflow from frost"}'),
  ('running-constantly', 'refrigerator-dirty-condenser-coils', 0.600, '{"note":"Unit works harder when coils are dirty"}'),
  ('running-constantly', 'refrigerator-door-gasket-leak', 0.550, '{"note":"Warm air leak causes longer run times"}')
) as w(symptom_slug, failure_slug, weight, meta)
join public.kg_nodes s on s.node_type = 'symptom' and s.slug = w.symptom_slug
join public.kg_nodes f on f.node_type = 'failure_mode' and f.slug = w.failure_slug
on conflict (source_node_id, target_node_id, relation_type) do nothing;

-- ===========================================================================
-- EDGES: failure_mode → symptom (produces) — inverse for explainability
-- ===========================================================================
insert into public.kg_edges (source_node_id, target_node_id, relation_type, weight, graph_version, metadata)
select f.id, s.id, 'produces', e.weight, 'KG-v0.1-mvp', '{"note":"Failure mode may produce this observed symptom"}'::jsonb
from public.kg_edges e
join public.kg_nodes s on s.id = e.source_node_id and s.node_type = 'symptom'
join public.kg_nodes f on f.id = e.target_node_id and f.node_type = 'failure_mode'
where e.relation_type = 'suggests' and e.graph_version = 'KG-v0.1-mvp'
on conflict (source_node_id, target_node_id, relation_type) do nothing;
