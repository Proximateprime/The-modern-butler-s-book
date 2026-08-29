# MVP FEATURE LIST & SUCCESS CRITERIA
## The Modern Butler's Book  
**Status:** Frozen for Version 1 / MVP  
**Date:** 2026-07-16  
**Authority:** Product & Engineering — do not expand without explicit re-planning

---

## MVP Mission

Build the smallest complete product that proves the core loop:

A user can add an appliance, describe a real symptom in natural language, receive intelligent adaptive follow-up questions, understand possible causes with explanations and confidence, track the session, verify an outcome, and see that outcome become permanent household memory — while staying fully within safety boundaries and working offline for core paths.

---

## Exact In-Scope Features (MVP)

### Account & Profile
- Secure account creation (email / social / guest mode with later upgrade)
- Lightweight skill assessment → initial skill level (Beginner → Intermediate range)
- Explanation preference (Simple / Balanced / Detailed)
- Privacy consent and basic controls
- User Skill Profile storage

### Appliance Setup
- Manual appliance creation (category, manufacturer, model, nickname, location label, approximate age)
- Basic OCR label scanning (model / serial) with confirmation
- Appliance digital profile page
- Simple status (Healthy / Needs Attention / Under Investigation)

### Core Repair Session
- Start troubleshooting from Home, Appliance profile, or “Something is wrong”
- Multi-modal symptom input (text + voice notes + optional photo)
- Structured Observation → Evidence conversion
- Adaptive follow-up questions (one primary question at a time + “Why this matters”)
- Current understanding + confidence indicator
- Evidence timeline / progress view
- Risk & Safety Engine gating of all guidance
- Skill-adaptive explanation depth
- Session auto-save and resume (including after offline periods)
- Verification questions after user reports action/outcome
- Structured final outcome (Resolved / Partial / Maintenance / Professional Recommended / Unresolved)
- Automatic session summary generation

### Household Memory
- Permanent Repair Session history attached to each appliance
- Basic maintenance record logging
- “This appliance had a similar issue X months ago” surface when relevant
- Export of personal repair history (PDF or structured)

### Offline & Sync
- Local storage of appliances, recent sessions, preferences
- Ability to continue a session offline and sync later
- Clear offline status messaging
- Conflict resolution for multi-device (basic)

### Privacy & Trust
- Clear privacy snapshot in FTUE
- User control over photos and optional media
- Easy data export and deletion
- No persistent home maps
- Transparent “why this question” and confidence communication

### Platform Basics
- Flutter mobile app (iOS + Android)
- Supabase (or equivalent) backend for auth, database, storage
- Basic AI service abstraction (cloud model for reasoning + explanation)
- Home dashboard showing appliances + active sessions
- Simple notifications for interrupted sessions and basic maintenance reminders

---

## Explicitly Out of Scope for MVP

- Full AR overlays
- Advanced 3D interactive models
- Predictive remaining-life estimates at scale
- Multi-property / landlord professional tools
- Manufacturer deep integrations or official diagnostics
- Service marketplace / technician booking
- Full community intelligence UI and leaderboards
- Advanced gamification / skill certification tracks
- Every appliance category (focus on 3–4 core: dishwasher, washer, dryer, refrigerator)
- Perfect Knowledge Graph coverage for all models
- Continuous video or always-on camera features
- Any relaxation of Safety Invariants

---

## Success Criteria (MVP Done When)

A real user can:

1. Create an account and complete the lightweight skill assessment
2. Add at least one real appliance (manual or OCR)
3. Start a troubleshooting session and describe a real symptom in natural language
4. Answer a short series of adaptive questions that feel intelligent and relevant
5. See a clear current understanding, confidence level, and supporting evidence
6. Receive skill-appropriate, safety-gated next-step guidance
7. Complete verification and close the session with a structured outcome
8. See the session permanently saved in the appliance’s history
9. Return later and have the app remember previous context
10. Do the core flow while offline (with graceful degradation) and sync successfully afterward
11. Understand why the app asked each question and why it reached its current view
12. Feel that the app was calm, respectful, honest about uncertainty, and never pushed them into unsafe territory

**Quantitative targets (early indicators):**
- Session completion rate (start → structured outcome) ≥ 40% in closed beta
- Users report increased understanding of the problem (qualitative + simple rating)
- Zero safety-gate violations in testing
- Offline sessions successfully sync without data loss
- Core loop feels useful even with limited seed knowledge

---

## Post-MVP Expansion Order (Do Not Start Until MVP Succeeds)

1. Improved vision evidence extraction and photo confirmation quality
2. Stronger Knowledge Graph seeding and model-specific data
3. Better voice-first experience
4. Predictive maintenance suggestions based on age + history
5. Household sharing and multi-user permissions
6. Early AR experiments (optional enhancement)
7. Premium subscription scaffolding and deeper analytics
8. Professional / multi-property tools

---

## Freezing Rule

This MVP list is frozen.  

Any proposed addition must answer:
- Does it prove the core intelligence + memory + trust loop?
- Can it be built without delaying the first real-user validation?
- Does it stay inside Safety Invariants and Non-Negotiables?

If the answer is no, it waits for Version 1.1 or Version 2.

---

*This document is the single source of truth for what “MVP done” means. Build this and nothing more until it is proven with real users.*