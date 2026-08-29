# KNOWLEDGE GRAPH SEEDING PLAN
## The Modern Butler's Book  
**Version:** 1.0  
**Date:** 2026-07-16  
**Status:** Required for MVP Intelligence Quality

---

## Why This Matters

The Reasoning Engine, Question Selection, Evidence weighting, and all explainability depend on a high-quality Knowledge Graph.  
Without a careful seed, the app will either:
- Give generic or low-value questions, or
- Hallucinate relationships that are not grounded.

This document defines how we bootstrap trustworthy knowledge for the first appliance categories.

---

## Scope for MVP Seed

**Primary Categories (must be solid for MVP):**
1. Dishwasher
2. Washing Machine (Washer)
3. Dryer
4. Refrigerator / Freezer

**Target depth for each category:**
- Main subsystems (Drain, Water Supply, Drive/Spin, Heating, Cooling, Controls, Door/Latch, etc.)
- 15–40 common Failure Modes per major category
- Typical symptoms linked to each Failure Mode
- Positive and negative Evidence relationships
- Safe observational checks (beginner-appropriate)
- Accessibility ratings
- Rough difficulty / time estimates
- Model-family inheritance structure (general → brand family → specific model overrides later)

---

## Seeding Principles

1. **Quality over quantity** — Better to have 20 excellent Failure Modes than 100 mediocre ones.
2. **Evidence-driven** — Every relationship should be supportable by manuals, service literature, or verified common knowledge.
3. **Safe by default** — All seeded Safe Checks must stay within Safety Invariants.
4. **Versioned** — Every seed entry has source, date, and version.
5. **Inheritance first** — Build general appliance → subsystem → component knowledge, then add model-specific overrides later.
6. **Human review gate** — No automatic import of scraped forum data without review.
7. **Explainable** — Every node and relationship should be understandable by a human engineer.

---

## Data Sources (Allowed for Initial Seed)

**High-trust sources (preferred):**
- Official service manuals and technical bulletins (where legally usable)
- Manufacturer installation & owner manuals (publicly available)
- Established service literature and training materials
- Structured knowledge from experienced appliance technicians (with attribution)
- Public right-to-repair and parts diagrams that show component relationships

**Medium-trust (use carefully, always review):**
- Aggregated common failure patterns from reputable repair sites
- Common symptom → cause patterns that appear consistently across multiple independent sources

**Low-trust / Do not use for core seed:**
- Random forum posts without verification
- Unreviewed YouTube “fix everything” videos
- AI-generated content that has not been checked against real sources

---

## Seeding Process

### Phase 1 — Core Structure (Week 1–2 of knowledge work)
1. Define top-level Appliance categories and Subsystems for the four MVP appliances.
2. Create the main Component nodes for each subsystem.
3. Establish the inheritance tree (Appliance → Subsystem → Component).

### Phase 2 — Failure Mode Seed (Critical)
For each major subsystem:
- List the 5–12 most common Failure Modes
- Link typical Symptoms
- Define supporting and contradicting Evidence
- Attach 2–5 Safe Observational Checks
- Add accessibility and difficulty metadata
- Record source and confidence

### Phase 3 — Question Seed
- For each high-value discrimination point, create reusable Question objects
- Attach expected answer types and which Failure Modes they separate
- Include skill-level text variants (Simple / Balanced / Detailed)

### Phase 4 — Validation
- Walk through 10–20 realistic symptom scenarios manually
- Confirm that the Reasoning Engine can generate sensible candidate sets and high-information-gain questions
- Fix gaps and incorrect relationships
- Mark seed version (e.g., KG-Seed-v0.9-MVP)

### Phase 5 — Ongoing (Post-MVP)
- Model-specific overrides added only when high-quality data exists
- Community statistics start as low-confidence metadata and rise only after verified volume
- Human review required for any material change to core Failure Mode definitions or safety-related relationships

---

## Minimum Viable Seed Metrics (MVP Ready)

- ≥ 80 high-quality Failure Mode nodes across the four categories
- ≥ 200 Symptom ↔ Failure Mode relationships
- ≥ 150 Evidence relationships (support + contradict)
- ≥ 60 Safe Check / Question objects with clear information-gain value
- Full subsystem coverage for the four target appliances
- All entries have source and version metadata
- Manual walkthrough of at least 15 end-to-end diagnostic scenarios succeeds without major missing knowledge

---

## Ownership & Tools

- Knowledge curation owner (can start as founder + one domain expert / contractor)
- Storage: Knowledge Graph tables / nodes as defined in Volume VIII
- Version control: Every seed batch is tagged and reversible
- Review: Simple checklist before promotion to “production seed”

---

## What Success Looks Like

When a user says “My dishwasher leaves water in the bottom and I hear the pump running,” the seeded graph allows the Reasoning Engine to:
- Generate a sensible shortlist of Failure Modes (drain obstruction, drain pump, float switch, etc.)
- Ask high-value questions that quickly separate them
- Provide clear, skill-appropriate explanations grounded in real relationships
- Stay completely within Safety Invariants

That is the bar for “MVP seed ready.”

---

## Immediate Next Actions

1. Choose the first appliance category to seed deeply (recommend Dishwasher or Dryer).
2. Create the subsystem and component skeleton.
3. Populate the top 10 Failure Modes with full Evidence and Safe Check links.
4. Run manual diagnostic walkthroughs.
5. Expand to the remaining three categories using the same pattern.

---

*This plan protects the intelligence quality of the product. Do not skip or rush the seed quality in order to “launch faster.” Bad knowledge is worse than limited knowledge.*