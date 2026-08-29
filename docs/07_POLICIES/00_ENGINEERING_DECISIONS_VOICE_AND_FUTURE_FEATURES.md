# ENGINEERING DECISIONS — VOICE ARCHITECTURE & FUTURE FEATURES

**Status:** Recorded Engineering Decisions  
**Version:** 1.0  
**Date:** 2026-07-20  
**Authority:** Engineering Specification  

**Depends On:**  
- Design Principles  
- Engineering Principles — AI Cost & Local-First  
- MVP Scope Lock  
- Module 3.5 — Diagnostic Workflow & State Machine

---

## 1. Voice Mode Architecture

Voice is a **presentation layer**, not a separate reasoning path.

```
Reasoning Engine
      ↓
Final structured response
      ↓
Presentation Layer
      ├── Display as text
      └── Speak via TTS (local preferred)
```

### Rules
- The reasoning engine produces the response **once**.
- Voice output reuses that same response.
- Prefer local or downloadable TTS when quality is acceptable.
- Speech recognition should evaluate local-first options when practical.
- Voice must not create a second, divergent diagnostic path.

This preserves determinism of core reasoning while allowing natural hands-free use later.

---

## 2. "While You're Here" Recommendations

This is **not** a new system.

It is the same concept already defined as **Opportunistic Maintenance** in the diagnostic architecture:

- When an appliance is already partially disassembled, the Butler may suggest optional related maintenance.
- These suggestions are never required.
- They must be clearly labeled as optional.
- They must remain within safety bounds.

No new module is required.

---

## 3. Project Inventory (Future Roadmap Only)

**Status:** Future feature — explicitly outside MVP

Concept:
- Before a repair, user lays out tools/parts and scans inventory
- During repair, system associates steps with last seen objects
- After repair, a second scan identifies missing items
- Butler can suggest where something was last relevant

### Why it is Future
- Requires camera workflow, object tracking, and significant UX
- Not required for the core diagnostic loop
- Must not expand Version 1 scope

Recorded here only so the idea is not lost.

---

## 4. Premium Philosophy (Reminder)

Premium features should represent **additional convenience and capability**, not the removal of essential repair knowledge.

Examples of legitimate premium direction (post-MVP):
- Continuous hands-free voice companion
- Cloud sync of Household Memory across devices
- Multi-device sync
- Advanced AR convenience features
- Project Inventory (when built)

In-app local Household Memory (repair history on this device) is **MVP**, not premium.

The free experience must remain genuinely useful.

---

## Version History

**Version 1.0** — 2026-07-20  
Recorded voice presentation-layer decision, confirmed Opportunistic Maintenance coverage, and parked Project Inventory as future-only.

---

*These decisions are binding for implementation prioritization and scope control.*