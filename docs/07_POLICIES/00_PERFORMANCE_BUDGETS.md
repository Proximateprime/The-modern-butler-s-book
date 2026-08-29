# PERFORMANCE BUDGETS

**Status:** Implementation Specification  
**Version:** 1.0  
**Date:** 2026-07-20  
**Authority:** Engineering Specification  

**Depends On:**  
- Engineering Principles — AI Cost & Local-First  
- MVP Scope Lock

---

## Purpose

This document establishes the need for concrete performance targets so that implementation decisions remain consistent.

Exact numbers may be refined during development, but the existence of budgets is required.

---

## Categories That Need Budgets

- Time to present the next question after user input
- Time for local Knowledge Graph queries
- Acceptable latency for cloud-assisted explanation generation
- Offline storage limits for knowledge packs and session data
- Memory usage expectations on target mobile devices
- Maximum acceptable AI cost per typical repair session

---

## Design Intent

Performance should be designed intentionally rather than discovered after features feel slow or expensive.

---

## Version History

**Version 1.0** — 2026-07-20  
Initial requirement for performance budgets.

---

*This document requires that performance targets be defined and tracked during implementation.*