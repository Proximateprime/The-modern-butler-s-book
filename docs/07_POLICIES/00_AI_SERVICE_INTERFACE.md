# AI SERVICE INTERFACE (PROVIDER ABSTRACTION)

**Status:** Implementation Specification  
**Version:** 1.0  
**Date:** 2026-07-20  
**Authority:** Engineering Specification  

**Depends On:**  
- Engineering Principles — AI Cost & Local-First  
- Determinism Policy  
- Domain Boundary Policy  
- Module 8.0 — Local-First Knowledge Package Architecture

---

## Purpose

The Butler must not call a specific AI vendor directly throughout the codebase.

All model access goes through one abstraction layer:

```
Butler Systems
      ↓
AI Service Interface
      ↓
Provider Adapters
  - Grok
  - Claude
  - GPT
  - Gemini
  - Local models
```

This protects cost control, portability, testing, and long-term survival if a provider changes pricing, policy, or quality.

---

## Responsibilities of the Interface

- Accept structured requests, not raw ad-hoc prompts scattered across the app
- Apply shared system rules (safety, domain boundary, formatting expectations)
- Route to the selected provider
- Return normalized responses
- Expose errors in a common taxonomy
- Support logging of token usage / cost metrics
- Allow provider switching without rewriting diagnostic logic

---

## What the Interface Should Receive

Prefer structured state over giant blobs of knowledge:

- Current hypotheses
- Confidence values
- Relevant evidence
- Communication goal (ask question / explain / summarize / escalate)
- User communication preferences
- Session constraints

Do **not** dump entire manuals or full knowledge packages into the model by default.

---

## What Remains Outside the LLM

These must stay deterministic / local:

- Hypothesis ranking core
- Confidence calculation direction
- Safety gate decisions
- Knowledge package retrieval
- Question utility ranking policy
- Session state transitions

The LLM communicates and explains. It does not own the diagnostic backbone.

---

## Design Intent

One clean interface now can save major rework later when providers, prices, or model strengths change.

---

## Version History

**Version 1.0** — 2026-07-20  
Initial specification for provider-agnostic AI access.

---

*This document is binding for all cloud or local model integrations.*