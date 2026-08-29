# DESIGN PRINCIPLES

**Status:** Locked  
**Version:** 1.3  
**Date:** 2026-07-20  
**Authority:** Foundational Architecture  

This document contains the short, permanent design principles of The Modern Butler’s Book.  

These principles sit above individual modules. Every future architecture decision, feature, engine, and implementation choice should be checked against this list.  

If a proposed design violates one or more of these principles, it should be rethought.

---

## The Principles

1. **Observe before concluding.**  
   The system must gather structured observations before forming conclusions. Users report what they see, hear, smell, or feel. The system performs the interpretation.

2. **Never ask engineering questions; ask observation questions.**  
   The user should never be required to understand or answer technical engineering questions. All requests must be translated into simple, safe, everyday observations.

3. **Translate engineering into human language.**  
   The Butler is responsible for converting engineering needs into natural, accessible language and interactions. The user should not have to adapt to the system’s internal model.

4. **Never let the AI guess when it can observe.**  
   When a safe observation is possible, the system should prefer collecting real evidence over making assumptions or relying solely on statistical patterns.

5. **Verification is more valuable than confidence.**  
   High confidence without verification is insufficient. The system must prioritize confirming outcomes before treating a repair as complete or learning from it.

6. **Every explanation should increase understanding, not just solve the problem.**  
   Explanations exist to help the user become more capable over time. They should build genuine understanding rather than simply justifying the system’s recommendation.

7. **The AI adapts to the user; the user should not have to adapt to the AI.**  
   Communication style, complexity, and interaction method should adapt to the user’s comfort, past success, and current context. The burden of adaptation belongs to the system.

8. **Engineering truth is permanent; conversation is flexible.**  
   Core engineering knowledge and causal relationships must remain stable and versioned. How that knowledge is communicated to the user may change and improve over time.

9. **Learn only from verified outcomes, never from assumptions.**  
   The system may only update its knowledge or recommendations based on outcomes that have been explicitly verified. Unverified or assumed results must not influence learning.

10. **Reduce uncertainty with the least effort from the user.**  
    When multiple ways exist to gather useful evidence, the system should choose the method that minimizes user effort, confusion, and risk while still producing reliable information.

11. **Optimize for Outcome, Not Conversation Speed.**  
    The Butler shall optimize for the user’s total success rather than minimizing the length of the conversation.  

    This means the system may intentionally spend additional time gathering evidence when doing so is expected to reduce the overall cost of diagnosis and repair.  

    Total cost includes, but is not limited to:  
    - Time spent diagnosing  
    - Time spent repairing  
    - Cost of unnecessary replacement parts  
    - Risk of incorrect repairs  
    - Likelihood of repeat failures  
    - User frustration  
    - Probability of successful first-time repair  

    The Butler should continuously evaluate the tradeoff between collecting more evidence and acting on existing confidence. It should stop asking questions when additional evidence is unlikely to meaningfully improve the outcome.  

    The objective is not the shortest conversation.  
    The objective is the highest probability of solving the user’s real problem with the lowest overall human cost.

12. **Access Before Monetization.**  
    The Modern Butler’s Book exists to help people solve real-world problems safely and confidently.  

    Core diagnostic guidance, safety information, maintenance education, and public reasoning resources should remain freely accessible whenever practical.  

    Monetization should come from added convenience, personalization, professional capabilities, enterprise tools, and advanced features — not from withholding essential repair knowledge.  

    Every monetization decision should answer one question:  

    > “Does this sustain the mission, or does it create unnecessary friction for someone who simply needs help?”

13. **Engineering Efficiency Enables Accessibility.**  
    The objective is not simply to maximize profit.  
    The objective is to engineer the system efficiently enough that operating costs remain low, allowing lower prices, broader free access, and continued product improvement.  

    Every recurring dollar saved through good engineering is a dollar that can potentially be returned to users through lower pricing, expanded free access, or continued product improvements.  

    Prefer local, deterministic, and cached solutions whenever they deliver equivalent user value. Use cloud AI when it adds unique value, not as a default substitute for structured systems.

---

## How to Use This Document

When evaluating any new feature, module, or change, ask:

> Does this violate any of the Design Principles?

If the answer is yes, the design should be revised before proceeding.

These principles are intentionally short. They are meant to be memorable and usable as a quick reference during design and implementation.

---

## Version History

**Version 1.0** — 2026-07-19  
Initial locked set of foundational design principles.

**Version 1.1** — 2026-07-19  
Added Principle 11: Optimize for Outcome, Not Conversation Speed.

**Version 1.2** — 2026-07-19  
Added Principle 12: Access Before Monetization.

**Version 1.3** — 2026-07-20  
Added Principle 13: Engineering Efficiency Enables Accessibility.

---

*This document is binding. All future architecture and implementation decisions must remain consistent with these principles.*