# MODULE 6.3 — MULTI-SESSION CONTEXT

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-19  
**Authority:** Architecture Specification  

**Depends On:**  
- Module 4.0 — Repair Session Data Model  
- Module 4.2 — Household Memory Data Model

---

## Purpose

This document defines how the Butler can recognize and use relationships between multiple diagnostic sessions, especially when problems across appliances or over time appear connected.

---

## Core Idea

Some problems are not isolated to a single appliance or a single session.

Examples:
- Dryer issue that is actually caused by a household electrical problem
- Multiple appliances showing symptoms after a power event
- Repeated similar failures across time on the same appliance or related appliances

The system should be able to surface relevant cross-session context when it improves diagnosis or prevention.

---

## Principles

- Cross-session reasoning must remain evidence-based.
- Privacy boundaries still apply.
- The system should present cross-session insights as helpful context, not as definitive conclusions without support.
- Users should be able to see why previous sessions are being referenced.

---

## Version History

**Version 1.0** — 2026-07-19  
Initial locked specification for Multi-Session Context.

---

*This document is binding. Cross-session reasoning must follow the principles defined herein.*