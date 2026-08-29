# API COST BUDGET TEMPLATE

**Status:** Implementation Aid  
**Date:** 2026-07-20  

Track this as features appear. Exact numbers will change; the habit matters.

---

## Template

| Feature / Step | Local? | Cloud AI? | Est. Calls | Est. Tokens In | Est. Tokens Out | Est. Cost | Notes |
|----------------|--------|-----------|------------|----------------|-----------------|-----------|-------|
| Model lookup | Yes | No | 0 | 0 | 0 | $0 | OCR/local mapping preferred |
| Load knowledge package | Yes | No | 0 | 0 | 0 | $0 | Download/package only |
| Hypothesis ranking | Yes | No | 0 | 0 | 0 | $0 | Deterministic |
| Question selection | Yes | No | 0 | 0 | 0 | $0 | Deterministic policy |
| Phrase next question | Maybe | Optional | 1 |  |  |  | Only if natural language needed |
| Explain why question asked | Maybe | Optional | 1 |  |  |  | Cache/reuse when possible |
| Session summary | Maybe | Optional | 1 |  |  |  | Structured first, prose second |
| Voice presentation | Local TTS preferred | Premium/cloud optional |  |  |  |  | Presentation layer |
| Image understanding | Case-by-case | Optional |  |  |  |  | Avoid continuous video AI |

---

## Target Mindset

- Default cost of a common repair path should trend downward over time
- Every repeated cloud call is a candidate for replacement by local knowledge or deterministic logic
- Premium experiences may cost more; core diagnosis should stay efficient

---

*Fill this in during implementation. Do not wait for perfect estimates.*