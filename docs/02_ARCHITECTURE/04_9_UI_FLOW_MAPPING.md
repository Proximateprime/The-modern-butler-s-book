# MODULE 4.9 — UI FLOW MAPPING (STATE MACHINE)

**Status:** Locked Architecture  
**Version:** 1.0  
**Date:** 2026-07-18  
**Authority:** Architecture Specification  
**Depends On:**  
- Module 3.5 — Diagnostic Workflow & State Machine  
- Module 3.7 — Predictive Conversation Engine

---

## Purpose

This document provides a high-level mapping between the diagnostic **State Machine** (defined in Module 3.5) and the user interface flow.

It ensures that the UI supports the required states and transitions without violating the architecture.

---

## State-to-Screen Mapping (High Level)

| State                                | Primary UI Focus                              | Key UI Elements |
|--------------------------------------|-----------------------------------------------|-----------------|
| Idle                                 | Home / Start new session                      | Appliance list, "Start Troubleshooting" |
| Appliance Selection                  | Select or add appliance                       | List of appliances, search, add new |
| Basic Condition Verification         | Guided checks                                 | Checklist or simple questions |
| Collect Initial Observations         | Open input                                    | Text input, voice, photo options |
| Adaptive Question Selection          | Structured question cards                     | One question + options + "Other..." + "Why this?" |
| Generate Safe Guidance               | Clear instructions + safety warnings          | Step-by-step guidance, warnings |
| User Performs Action + Verification  | Confirmation + outcome recording              | Action confirmation, result input |
| Root Cause Analysis                  | Summary view                                  | Root cause breakdown |
| Generate Prevention Recommendations  | Actionable recommendations                    | Prioritized list with explanations |
| Session Summary                      | Review screen                                 | Full session recap |
| Session Closed                       | Confirmation + next steps                     | Session complete message, maintenance reminders |

---

## Key UI Principles

- The UI must clearly reflect the current state in the diagnostic workflow.
- Users should always have a way to understand why they are being asked something.
- Navigation should support going back to previous states when safe and appropriate.
- Predictive elements (pre-loaded next questions) should feel seamless.

---

## Version History

**Version 1.0** — 2026-07-18  
Initial high-level UI flow mapping tied to the state machine.

---

## Implementation Notes

This mapping should be used as a reference when designing screens and navigation. More detailed wireframes and interaction design can be developed later, but they must remain consistent with the states defined in Module 3.5.

---

*This document is binding. All user interface flows for diagnostic sessions must align with the state machine defined in Module 3.5.*