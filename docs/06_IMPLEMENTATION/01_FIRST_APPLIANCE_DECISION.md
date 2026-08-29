# FIRST APPLIANCE DECISION

**Status:** Implementation Decision  
**Date:** 2026-07-20  
**Authority:** Pre-Cursor Preparation  

---

## Decision

**First appliance for the 2-week build: Dryer**

### Why Dryer
- Common, high-frustration problems (no heat, not tumbling, long dry times)
- Strong mix of safe observational checks vs unsafe paths
- Clear root-cause patterns (airflow, heating, mechanical)
- Excellent real-world test material
- Lower immediate electrical/gas danger surface than some alternatives if safety gates are respected
- Good fit for demonstrating observation-first diagnosis

### Backup choice
**Dishwasher** — if dryer knowledge gathering is slower than expected.

---

## Version 1 Appliance Focus (Reminder)
From MVP Scope Lock:
- Dryer
- Washer
- Dishwasher
- Refrigerator / Freezer

Only **Dryer** is required for the 2-week acceptance target.

---

## Non-Goals for First Appliance
- Full model coverage
- Every rare failure mode
- Gas dryer internal work guidance
- Sealed-system / high-risk electrical internals

Safety gates still apply.

---

*This decision removes ambiguity when coding starts.*