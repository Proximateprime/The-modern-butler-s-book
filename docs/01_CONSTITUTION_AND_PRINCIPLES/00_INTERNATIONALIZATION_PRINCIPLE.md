# INTERNATIONALIZATION PRINCIPLE

**Status:** Locked Engineering Principle  
**Version:** 1.0  
**Date:** 2026-07-21  

---

## Principle

The entire runtime of The Modern Butler’s Book must be **language-neutral**.

The following must never depend on any natural language (including English):

- DecisionContext
- EvidenceRequest
- Knowledge Packages
- Safety Rules
- Deterministic reasoning and confidence logic
- Session state and outcomes

Only the Conversation / UI layer is allowed to translate internal identifiers and structured data into the user’s language.

---

## Why This Exists

This design allows one engineering knowledge base to support many languages without duplicating diagnostic logic or safety rules.

Engineering truth remains singular.  
Presentation is localizable.

---

## Implementation Rule

Internal identifiers, failure mode keys, evidence types, and safety classifications must be language-agnostic codes or structured data.  
Human-readable text is generated only at the final presentation boundary.

---

## Version History

**Version 1.0** — 2026-07-21  
Locked as a foundational engineering principle.
