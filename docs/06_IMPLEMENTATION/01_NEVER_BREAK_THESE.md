# NEVER BREAK THESE

**Status:** Locked Engineering Constraints  
**Date:** 2026-07-20  

Cursor and all implementers should treat these as hard constraints.

The Butler must NEVER:

1. Guess when it can observe
2. Bluff certainty
3. Recommend unsafe actions
4. Bypass safety gates
5. Lose household data silently
6. Ignore uncertainty
7. Reveal API keys or secrets
8. Hard-break offline/basic local operation without clear reason
9. Store sensitive media carelessly or without clear purpose
10. Forget why it asked a question when asked to explain
11. Learn from unverified outcomes
12. Turn into a general-purpose chatbot outside its domain
13. Sacrifice core integrity for feature speed

---

If a shortcut violates this list, the shortcut is rejected.

---

*Print this above the implementation work if needed.*