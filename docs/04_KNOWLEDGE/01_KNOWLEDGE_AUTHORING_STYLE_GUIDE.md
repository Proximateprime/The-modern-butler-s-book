# KNOWLEDGE AUTHORING STYLE GUIDE

**Status:** Implementation Guidance  
**Date:** 2026-07-20  
**Authority:** Pre-Cursor Preparation  

---

## Purpose
Ensure the first knowledge packages are consistent, safe, and usable by the reasoning loop.

---

## Authoring Rules

1. **Write for observation, not expertise**  
   Prefer checks a normal person can do safely.

2. **Separate facts from advice**  
   Failure modes, symptoms, and relationships are knowledge.  
   Guidance must still pass safety gates.

3. **Prefer common cases first**  
   Cover high-frequency problems before rare edge cases.

4. **Mark uncertainty**  
   If a relationship is weak or situational, do not present it as strong.

5. **Never encode unsafe instructions as normal steps**  
   Prohibited work stays prohibited regardless of knowledge content.

6. **Every failure mode should answer:**
   - What symptoms suggest it?
   - What safe observations help confirm/deny it?
   - What is commonly confused with it?
   - When should this escalate?

---

## Minimum Fields for Early Seed Knowledge

For each major item, aim to include:

- Name / slug
- Plain-language description
- Related symptoms
- Related failure modes
- Safe observation methods
- Rough likelihood notes (common / uncommon)
- Safety notes if relevant
- Source / confidence note (even if “initial seed”)

---

## Quality Bar for Version 1 Seed
Not encyclopedic.  
But not sloppy.

A good seed package should let the Butler:
- Ask sensible questions
- Avoid ridiculous jumps
- Distinguish a few major causes
- Know when to stop and escalate

---

## Anti-Patterns
- Copy-pasting random internet repair steps without structure
- Encoding “replace part X” as the first response
- Ignoring airflow / basic conditions
- Mixing gas/electrical internal work into normal paths

---

*Knowledge quality is now one of the top product risks. Author carefully.*