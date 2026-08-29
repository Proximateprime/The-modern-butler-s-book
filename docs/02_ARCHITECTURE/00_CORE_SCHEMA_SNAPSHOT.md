# CORE SCHEMA SNAPSHOT

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-21  
**Authority:** Implementation Reference  

This document is the single source of truth for the major domain objects in Version 1.  
It defines required fields, mutability, ownership, and versioning.  
It does **not** attempt to be a complete database schema. It locks the conceptual shape so Cursor and future developers do not invent incompatible versions.

---

## 1. DecisionContext

**Purpose:** Shared, authoritative view of the current diagnostic situation.  
**Owner:** Reasoning / Orchestration layer  
**Mutability:** Replaced or updated only through defined transitions (prefer immutable snapshots)

**Required fields:**
- `session_id`
- `appliance_id`
- `package_id` + `package_version`
- `hypotheses` (list of Hypothesis references + current scores)
- `leading_hypothesis_id` (nullable)
- `evidence_ids` (ordered)
- `safety_status`
- `current_evidence_request` (nullable)
- `investigation_status` (active / stopping / stopped / escalated)
- `schema_version`

**Optional / derived:**
- User skill / comfort signals
- Tool availability summary
- Stop reason
- Last confidence band shown to user

**Rule:** Any runtime value needed by more than one engine belongs here or is derived from here.

---

## 2. Evidence

**Purpose:** A single observation or claim recorded during a session.  
**Owner:** Session  
**Mutability:** Immutable after creation (corrections create new evidence or explicit overrides)

**Required fields:**
- `evidence_id`
- `session_id`
- `type` (structured_answer, free_text, photo, precondition_claim, system_observed, etc.)
- `timestamp`
- `source` (user, camera, system, prior_session, etc.)
- `reliability` / trust class
- `schema_version`

**Optional:**
- Linked question / EvidenceRequest id
- Structured value / answer id
- Free-text content
- Media reference
- Supports / contradicts hypothesis ids
- Staleness / expiry metadata

---

## 3. EvidenceRequest

**Purpose:** What the deterministic core needs next from the user.  
**Owner:** Reasoning layer → consumed by Conversation layer  
**Mutability:** Immutable once issued

**Required fields:**
- `request_id`
- `session_id`
- `needed_evidence_type` / goal
- `safety_level`
- `preferred_methods` (e.g. structured choice, photo, visual check)
- `schema_version`

**Optional:**
- Candidate answer options
- Related hypothesis ids (what this request is trying to discriminate)
- Human phrasing goal / constraints
- Preconditions

---

## 4. Hypothesis

**Purpose:** A possible failure mode under consideration.  
**Owner:** DecisionContext / Reasoning  
**Mutability:** Score and status may change; core identity is stable within a session

**Required fields:**
- `hypothesis_id` (stable within session; usually linked to package failure mode id)
- `failure_mode_ref` (package-scoped)
- `current_score` / confidence
- `status` (active, leading, ruled_out, etc.)
- `schema_version`

**Optional:**
- Supporting evidence ids
- Contradicting evidence ids
- Ruled-out reason
- Safety class

---

## 5. Guidance

**Purpose:** Safe, structured recommendation or action sequence produced after sufficient evidence.  
**Owner:** Reasoning + Safety  
**Mutability:** Immutable once issued to the user

**Required fields:**
- `guidance_id`
- `session_id`
- `type` (safe_check, repair_direction, escalate, stop, verify, etc.)
- `safety_classification`
- `schema_version`

**Optional:**
- Ordered steps
- Required tools
- Required preconditions
- Warnings
- Verification criteria
- Linked hypotheses / outcome expectations

---

## 6. RepairSession

**Purpose:** The full diagnostic and repair attempt for one appliance problem.  
**Owner:** Session service  
**Mutability:** Status and links change over lifecycle; core identity is immutable

**Required fields:**
- `session_id`
- `household_id`
- `appliance_id`
- `created_at`
- `status` (see Session Lifecycle document)
- `package_id` + `package_version`
- `schema_version`

**Optional:**
- Started_by user
- Last_activity_at
- Terminal outcome link
- Resume token / snapshot reference
- Language / locale used

---

## 7. SessionOutcome

**Purpose:** The engineering result of a closed session.  
**Owner:** Session / Learning  
**Mutability:** Written at or near terminal state; thereafter mostly immutable

**Required fields:**
- `outcome_id`
- `session_id`
- `terminal_state` (Success, Unresolved, Unexpected Outcome)
- `schema_version`

**Optional / strongly recommended:**
- Immediate cause
- Root cause
- Contributing factors
- Preventive actions
- Final hypothesis ids
- Verification result
- Linked incident id (if Unexpected Outcome)

---

## 8. HouseholdMemoryEntry

**Purpose:** Durable, privacy-sensitive record that improves future diagnoses.  
**Owner:** Household Memory service  
**Mutability:** Append-mostly; corrections are new entries or explicit supersession

**Required fields:**
- `memory_id`
- `household_id`
- `appliance_id` (when applicable)
- `type` (repair, part_replaced, tool, skill, prevention, note, etc.)
- `created_at`
- `schema_version`

**Optional:**
- Linked session / outcome
- Root cause / prevention summary
- Part or tool details
- Confidence / verification status
- Expiry or relevance metadata

---

## 9. KnowledgePackage (Runtime View)

**Purpose:** The versioned engineering knowledge loaded for diagnosis.  
**Owner:** Knowledge system  
**Mutability:** Immutable at runtime once loaded

**Required fields:**
- `package_id`
- `version`
- `status` (production, staging, engineering_review, deprecated, etc.)
- `manifest_hash` / integrity
- `schema_version` (package format)

**Optional but important:**
- Compatibility range (min/max app version)
- Appliance family / scope
- Dependencies or patches
- Signature / trust metadata

---

## 10. Knowledge Package Manifest

**Purpose:** Machine-readable description of what a package contains and requires.  
**Required concepts:**
- Package identity + version
- Format / schema version
- Target appliance family
- Content summary (failure modes, questions, guidance, etc.)
- Integrity hash
- Compatibility constraints
- Status

---

## Global Rules

1. Every core object carries a `schema_version`.
2. Required fields must be present before an object is considered valid for use by engines.
3. Prefer immutability. When correction is needed, prefer new records or explicit supersession over silent mutation.
4. Ownership boundaries must be respected: engines read DecisionContext; they do not each invent private parallel state.
5. This snapshot is the authority for Version 1. Changes require an explicit decision and version bump.

---

## Version History

**Version 1.0** — 2026-07-21  
Initial locked Core Schema Snapshot for implementation.