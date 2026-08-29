# MODULE 5.12 — FAILURE RECOVERY

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-19  
**Authority:** Architecture Specification  

**Depends On:**  
- Module 5.2 — Engine Orchestration Layer  
- Module 4.0 — Repair Session Data Model  
- Module 4.1 — Evidence Data Model

---

## Purpose

This document defines how the system behaves when components fail, data is corrupted, or expected services are unavailable.

The goal is to keep the user safe and preserve collected evidence even when parts of the system are not functioning correctly.

---

## Failure Categories

### 1. Transient Failures
- Temporary network loss
- Temporary unavailability of cloud reasoning
- Photo upload failure
- Voice recognition failure

**Required Behavior:**  
Preserve all existing session data. Allow the user to continue with reduced capability or retry the failed action. Never lose evidence that has already been accepted.

### 2. Component Unavailability
- Knowledge Graph temporarily unavailable
- Reasoning Engine unavailable
- Specific acquisition method unavailable

**Required Behavior:**  
Fall back to offline or reduced-capability modes where possible. Clearly communicate limitations. Do not invent evidence or skip required safety checks.

### 3. Data Integrity Issues
- Corrupted evidence record
- Contradictory critical observations that cannot be automatically resolved
- Invalid session state

**Required Behavior:**  
Protect the integrity of the session. Prefer safe states (pause, ask for clarification, or recommend professional help) over continuing with potentially invalid data.

### 4. Hard Failures
- Application crash
- Device restart mid-session

**Required Behavior:**  
On restart, recover the last consistent session state and offer to resume (see Session Resume & Continuity).

---

## Non-Negotiable Rules

- Collected Evidence must not be silently discarded.
- The system must never continue a diagnostic path that depends on missing safety-critical information.
- When in doubt, prefer pausing or escalating over continuing with incomplete or corrupted state.

---

## Version History

**Version 1.0** — 2026-07-19  
Initial locked specification for Failure Recovery.

---

*This document is binding. All failure handling must prioritize safety and evidence preservation.*