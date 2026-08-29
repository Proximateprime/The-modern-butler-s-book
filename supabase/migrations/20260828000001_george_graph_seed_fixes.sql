-- George Aug 28 graph holes for databases that already applied 20260716000003.
-- Idempotent. Create-only for new rows; deactivates misleading wont-start edges.

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

-- Prefix applies_to covers new FM slugs.
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

insert into public.kg_edges (source_node_id, target_node_id, relation_type, weight, graph_version, metadata)
select s.id, t.id, 'contains', 1.000, 'KG-v0.1-mvp', '{"note":"Subsystem contains serviceable component"}'::jsonb
from public.kg_nodes s, public.kg_nodes t
where s.node_type = 'subsystem' and t.node_type = 'component'
  and (
    (s.slug = 'washer-drive-spin' and t.slug = 'washer-suspension')
    or (s.slug = 'refrigerator-cooling' and t.slug in ('refrigerator-evaporator-coils','refrigerator-drip-pan'))
  )
on conflict (source_node_id, target_node_id, relation_type) do nothing;

insert into public.kg_edges (source_node_id, target_node_id, relation_type, weight, graph_version, metadata)
select f.id, t.id, 'affects', 0.800, 'KG-v0.1-mvp', '{"note":"Failure mode typically involves this component"}'::jsonb
from public.kg_nodes f, public.kg_nodes t
where f.node_type = 'failure_mode' and t.node_type = 'component'
  and (
    (f.slug = 'washer-unbalanced-load' and t.slug = 'washer-suspension')
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

insert into public.kg_edges (source_node_id, target_node_id, relation_type, weight, graph_version, metadata)
select s.id, f.id, 'suggests', w.weight, 'KG-v0.1-mvp', w.meta::jsonb
from (values
  ('wont-start', 'dryer-door-switch-failure', 0.700, '{"note":"Nothing happens — door switch, not belt"}'),
  ('wont-start', 'washer-lid-switch-failure', 0.700, '{"note":"Washer lid/door switch — not dryer belt"}'),
  ('drum-does-not-turn', 'dryer-worn-drum-belt', 0.750, '{"note":"Motor runs, drum does not"}'),
  ('clothes-not-drying', 'dryer-thermal-fuse-open', 0.550, '{"note":"Open thermal fuse after overheat"}'),
  ('grinding-noise', 'washer-drain-pump-failure', 0.550, '{"note":"Debris in washer pump can grind"}'),
  ('standing-water', 'dishwasher-float-switch-stuck', 0.550, '{"note":"Float stuck down can leave standing water"}'),
  ('wont-fill', 'dishwasher-float-switch-stuck', 0.650, '{"note":"Float stuck up can block fill"}'),
  ('water-leak-on-floor', 'dishwasher-drain-hose-leak', 0.600, '{"note":"Drain hose or sink coupling can drip"}'),
  ('water-leak-on-floor', 'washer-drain-hose-leak', 0.550, '{"note":"Washer drain hose or coupling"}'),
  ('water-leak-on-floor', 'washer-supply-line-leak', 0.500, '{"note":"Accessible fill hose coupling"}'),
  ('water-leak-on-floor', 'refrigerator-drip-pan-overflow', 0.500, '{"note":"Full drip pan or blocked defrost drain"}'),
  ('not-cooling', 'refrigerator-compressor-sealed-fault', 0.250, '{"note":"Professional/sealed only — not beginner DIY"}')
) as w(symptom_slug, failure_slug, weight, meta)
join public.kg_nodes s on s.node_type = 'symptom' and s.slug = w.symptom_slug
join public.kg_nodes f on f.node_type = 'failure_mode' and f.slug = w.failure_slug
on conflict (source_node_id, target_node_id, relation_type) do nothing;

insert into public.kg_edges (source_node_id, target_node_id, relation_type, weight, graph_version, metadata)
select f.id, s.id, 'produces', e.weight, 'KG-v0.1-mvp', '{"note":"Failure mode may produce this observed symptom"}'::jsonb
from public.kg_edges e
join public.kg_nodes s on s.id = e.source_node_id and s.node_type = 'symptom'
join public.kg_nodes f on f.id = e.target_node_id and f.node_type = 'failure_mode'
where e.relation_type = 'suggests' and e.is_active = true
on conflict (source_node_id, target_node_id, relation_type) do nothing;

-- Retire misleading wont-start → dryer belt / lint (thermal-fuse note without an FM)
update public.kg_edges e
set is_active = false
from public.kg_nodes src, public.kg_nodes tgt
where e.source_node_id = src.id
  and e.target_node_id = tgt.id
  and e.is_active = true
  and (
    (e.relation_type = 'suggests'
      and src.slug = 'wont-start'
      and tgt.slug in ('dryer-worn-drum-belt', 'dryer-lint-buildup'))
    or (e.relation_type = 'produces'
      and tgt.slug = 'wont-start'
      and src.slug in ('dryer-worn-drum-belt', 'dryer-lint-buildup'))
  );
