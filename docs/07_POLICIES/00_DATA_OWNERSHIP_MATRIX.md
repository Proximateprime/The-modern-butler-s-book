# DATA OWNERSHIP MATRIX

**Status:** Implementation Specification  
**Version:** 1.0  
**Date:** 2026-07-20  
**Authority:** Engineering Specification  

**Depends On:**  
- Security as Tier-1 Principle  
- Module 4.0 / 4.1 / 4.2 Data Models  
- Module 8.0 — Knowledge Package Architecture

---

## Purpose

For every important data type, the project must be explicit about:

- Who owns it
- Where it is stored
- Whether it can leave the device
- Whether it is encrypted
- When it can be deleted

This prevents accidental privacy and security mistakes during rapid implementation.

---

## Matrix (Initial)

| Data | Primary Store | Cloud Allowed | Encryption Expectation | Notes |
|------|---------------|---------------|------------------------|-------|
| Household Memory | Device first | Optional sync | Yes if synced | User-owned household history |
| Repair Sessions / Evidence | Device first | Optional sync | Yes if synced | Core diagnostic records |
| Photos submitted in session | Device first | Optional | Yes if synced | Keep minimal; user controlled |
| Knowledge Packages | Device after download | Download only | Integrity verification required | Not personal data |
| Account identity | Auth provider / backend | Yes | Standard auth controls | Least privilege |
| Payment data | Payment processor | Tokenized only | Processor-controlled | Never store raw cards in Butler systems |
| API keys / secrets | Secure server/config only | Server only | Secret management required | Never ship private keys in client |
| Anonymous telemetry | Aggregated | Yes, limited | Minimize identifiability | Improvement metrics only |
| Diagnostic traces | Local / eng tools | Optional, careful | Protect if they include personal context | Engineering artifact |

---

## Rules

1. Default to local ownership for personal household data.
2. Cloud sync is optional and explicit where possible.
3. Raw payment data never belongs in Butler databases.
4. Secrets never belong in client code.
5. Knowledge packages are downloadable engineering assets, not personal data.
6. If data is not necessary, do not collect it.

---

## Version History

**Version 1.0** — 2026-07-20  
Initial data ownership matrix.

---

*This matrix should be updated whenever a new major data type is introduced.*