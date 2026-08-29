# SUGGESTED FOLDER STRUCTURE

**Status:** Implementation Aid  
**Date:** 2026-07-20  

This is a starting structure, not sacred architecture.

```
/app                 # UI / screens / navigation
/domain              # core domain types and session concepts
/reasoning           # ranking, confidence, question selection
/knowledge           # packages, graph access, seed data
/household           # appliances, memory, history
/communication       # phrasing, explanations, user-facing language
/security            # auth boundaries, secret handling, privacy helpers
/api                 # AI service interface and provider adapters
/tests               # path tests, safety tests, fixtures
/assets              # diagrams/models later
/docs                # Product Bible exports / engineering notes
```

## Rules of Thumb

- Deterministic diagnosis stays out of UI widgets
- AI provider details stay inside `/api`
- Knowledge package loading stays inside `/knowledge`
- Household memory stays inside `/household`
- Tests should be able to run a golden path without the full UI

---

*Reorganize later if needed, but start coherent.*