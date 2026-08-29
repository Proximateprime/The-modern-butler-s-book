# GOLDEN PATH — ONE PERFECT DRYER SESSION

**Status:** Implementation Roadmap Aid  
**Date:** 2026-07-20  
**Purpose:** One clear end-to-end path Cursor can aim at first.

This is not every branch.  
This is the spine.

---

## Golden Path

1. Open App  
2. Create / select household context if needed  
3. Add or select **Dryer**  
4. Capture model info if available (photo / manual entry)  
5. Local knowledge package available or minimal seed loaded  
6. Start Repair Session  
7. Prompt: “What’s going on?”  
8. User: **No heat** (drum still turns).
9. Basic condition checks  
   - Does the drum turn? (**Turns normally**)
   - Easy checks: lint filter, outside vent, visible hose  
10. Evidence stays on the airflow / heat path — not “clothes not drying” as the first question.  
11. Confidence updates toward airflow restriction  
12. Safety check passes for exterior guidance  
13. Safe recommendation: clean lint pathway / check vent restriction  
14. User performs action  
15. Verification: “Did drying improve?”  
16. Success confirmed  
17. Root cause recorded: restricted airflow / lint-vent pathway  
18. Prevention suggestion: clean lint filter every load; check exterior vent periodically  
19. Household Memory updated  
20. Session closed  

---

## What Must Work for This Path

- Session creation
- Observation questions
- Evidence storage
- Simple ranking from seed knowledge
- Safe guidance
- Verification
- Memory write
- Save / resume if interrupted mid-path

---

## Explicitly Out of Scope for First Golden Path

- Perfect OCR
- Full package manager polish
- Voice
- AR
- Multiple appliances
- Payments
- Beautiful UI

---

*If this path works, the project has a real product spine.*