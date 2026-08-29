# NON-NEGOTIABLES
## The Modern Butler's Book  
**One-Page Principles**  
**Version:** 1.0  
**Date:** 2026-07-16  
**Status:** Locked Foundation

---

These ten principles are the permanent foundation of the product, company, and architecture.  
They override feature requests, growth pressure, and short-term convenience.

### 1. Observation Before Conclusion
Users describe what they see, hear, smell, or feel.  
The system never requires the user to diagnose.  
The system gathers evidence before recommending action.

### 2. Safety Before Convenience
Hard safety gates (electrical internals, gas, sealed refrigerant, high-risk actions) never unlock for any skill level.  
The Risk & Safety Engine has final authority.  
See `01_SAFETY_INVARIANTS.md`.

### 3. Evidence Before Assumption
Every recommendation must be grounded in structured Evidence objects and Knowledge Graph relationships.  
Generative models interpret and explain; they do not invent facts or override structured knowledge.

### 4. Explainability Before Fluency
Users and engineers must always be able to understand:
- Why a question is asked
- Why a hypothesis is leading
- Why confidence changed
- Why a professional is recommended

### 5. Privacy Before Surveillance
The system learns from repairs, not from people’s homes.  
No persistent home maps or continuous camera recording by default.  
Personal Household Memory is strictly separated from Community Intelligence.  
Users own and can export/delete their data.

### 6. Offline-First Core Path
Core troubleshooting, history viewing, and session continuation must work without internet.  
Cloud AI enhances the experience; it is never required for basic usefulness.

### 7. Modular Specialized Engines
No single AI model owns the entire system.  
Reasoning, Evidence, Risk, Knowledge Graph, Learning, Household Memory, Vision, and Voice remain distinct, replaceable modules coordinated by the Orchestration Layer.

### 8. Learn Only From Verified Outcomes
Learning updates are versioned, reversible, quality-gated, and based on verified results.  
Bad data and unverified reports never automatically rewrite core engineering knowledge or safety rules.

### 9. Progressive Skill Adaptation Without Risk Escalation
Guidance becomes richer, clearer, and more efficient as skill grows.  
Skill never removes safety boundaries or hard gates.

### 10. Empowerment Over Dependency
The goal is more capable humans who understand their appliances and make better decisions.  
The product succeeds when users feel more confident and less helpless — not when they become dependent on the app for every decision.

---

## How to Use These Principles

- Every feature proposal must be checked against these ten points.
- Every AI prompt used for code generation or content must include these principles.
- If a growth opportunity or technical shortcut violates any of these, it is rejected.
- New team members must read this page and the Safety Invariants before contributing.

---

## One-Line Version (for quick reference)

**Observe → Evidence → Reason → Explain → Stay Safe → Remember → Improve only from verified reality → Keep the human capable and in control.**

---

*This page is intentionally short. Print it. Put it on the wall. Refer to it constantly.*