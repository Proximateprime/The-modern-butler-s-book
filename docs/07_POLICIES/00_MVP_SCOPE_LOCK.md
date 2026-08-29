# MVP SCOPE LOCK
## The Modern Butler’s Book — Version 1

**Status:** Locked for Version 1  
**Version:** 1.0  
**Date:** 2026-07-19  
**Authority:** Product & Architecture  

This document defines what is **in scope** and **out of scope** for the first shippable version of the product.

The goal of Version 1 is to prove the core diagnostic loop works safely and usefully — not to build the entire long-term vision.

---

## Version 1 Mission

A real user can:

1. Add an appliance
2. Start a troubleshooting session
3. Answer observation-based questions
4. Receive safe, structured guidance
5. Reach a verified outcome or professional recommendation
6. Have the session saved to Household Memory

All while staying within Safety Invariants and feeling guided rather than interrogated.

---

## Explicitly In Scope for Version 1

### Core Experience
- Appliance creation and basic profile
- Repair Session lifecycle
- Diagnostic State Machine (core path)
- Observation-based questioning
- Evidence collection and basic provenance
- Simple hypothesis ranking
- Confidence indication
- Risk & Safety gates (hard stops)
- Root Cause capture (basic)
- Prevention recommendations (basic)
- Session summary
- Household Memory (save past sessions + root causes)
- Session Resume
- Basic explainability (“Why this question?”)
- Offline-tolerant core path (best effort)

### Platforms
- Flutter mobile app (iOS + Android)
- Supabase backend

### Appliances (Initial Focus)
- Dishwasher
- Washing Machine
- Dryer
- Refrigerator / Freezer

---

## Explicitly Out of Scope for Version 1

- Full predictive conversation with heavy branch pre-computation
- Advanced community learning / global model updates
- Multi-session cross-appliance reasoning
- AR overlays or advanced computer vision
- Thermal cameras / external sensors
- Smart appliance deep integrations
- Domain plugins (HVAC, automotive, etc.)
- Complex economic / repair-vs-replace advisor
- Monetization, subscriptions, paywalls
- Multi-language localization
- Advanced accessibility features beyond basics
- Full Validation & Simulation Framework in production
- Sophisticated telemetry dashboards

---

## Success Criteria for Version 1

Version 1 is successful if:

- Users can complete real diagnostic sessions without the system inventing unsafe guidance
- The conversation feels more like a competent technician than a chatbot checklist
- Safety gates correctly block prohibited actions
- Sessions can be resumed
- Past repairs are remembered at a basic level
- The architecture remains clean enough to support future modules without major rewrites

---

## Change Control

Any proposal to expand Version 1 scope must be explicitly approved and documented.  
Prefer shipping a solid core over adding more features.

---

*This document is binding for Version 1. Features not listed as In Scope should be treated as future work unless this document is formally revised.*