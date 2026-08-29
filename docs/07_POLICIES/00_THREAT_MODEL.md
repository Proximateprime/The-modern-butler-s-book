# THREAT MODEL (INITIAL)

**Status:** Implementation Specification  
**Version:** 1.0  
**Date:** 2026-07-20  
**Authority:** Engineering Specification  

**Depends On:**  
- Security as Tier-1 Principle  
- API Cost and Abuse Protection  
- Domain Boundary Policy

---

## Purpose

Identify realistic threats early and attach mitigations before code sprawl makes them expensive to fix.

This is not a full enterprise security audit. It is a practical starter threat model for a household repair product.

---

## Priority Threats

### 1. API Abuse / Cost Attacks
**Threat:** Bots or scripted clients burn model budget through free or anonymous paths.  
**Mitigations:** Rate limits, quotas, abuse detection, circuit breakers, domain boundary enforcement.

### 2. Prompt Injection
**Threat:** Malicious user input or embedded content tries to override system rules.  
**Mitigations:** Strict separation of system instructions vs user content, never let model output directly authorize unsafe actions, keep safety decisions deterministic.

### 3. Knowledge Poisoning
**Threat:** Bad community or generated knowledge enters packages and degrades diagnosis.  
**Mitigations:** Versioning, review gates, provenance, no automatic promotion of unverified knowledge into core truth.

### 4. Account Takeover
**Threat:** Attacker accesses household history or synced data.  
**Mitigations:** Strong auth practices, least privilege, secure session handling, careful recovery flows.

### 5. Stolen Device
**Threat:** Local household data is exposed if a phone is lost.  
**Mitigations:** OS-level protections, app-level sensitivity awareness, minimal unnecessary local retention, remote sign-out where applicable.

### 6. Backend Breach
**Threat:** Cloud data or secrets are exposed.  
**Mitigations:** Secret management, encryption, least privilege, minimal cloud data, no raw payment storage.

### 7. Fake or Manipulated Repair Outcomes
**Threat:** Learning systems are polluted by junk outcomes.  
**Mitigations:** Learn only from verified outcomes, quality gates, reversible proposals.

### 8. Malicious Uploads
**Threat:** Photos/files used as attack vectors or storage abuse.  
**Mitigations:** Type checks, size limits, careful processing, no execution of uploaded content.

---

## Design Intent

Security work should follow real threats, not generic fear.  
Every major feature should be checked against this list.

---

## Version History

**Version 1.0** — 2026-07-20  
Initial practical threat model.

---

*This document should evolve as the system gains real users and real attack surface.*