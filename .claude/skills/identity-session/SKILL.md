---
name: identity-session
description: Authentication and session rules aligned with NIST SP 800-63-4. Use when touching login, sign-up, account recovery, tokens, sessions, MFA, passkeys/WebAuthn or OAuth/OIDC flows on any platform.
---

# Identity and session

Why: phishing is the dominant vector and OTP/SMS does not resist it; NIST SP 800-63-4 (final, July 2025) moved the baseline.

1. **Offer a phishing-resistant option.** At AAL2 the verifier must offer at least one phishing-resistant option; at AAL3 it is mandatory. OTP, out-of-band codes and passwords are **not** phishing resistant. Synced passkeys qualify for AAL2. *Essential (passkeys: Recommended; AAL3 with non-exportable keys: Advanced).*
2. **MFA available**, at no extra cost to the user.
3. **Passwords:** check against breached-password lists; no forced periodic rotation; no composition puzzles.
4. **Session tokens:** random, server-validated, expire, invalidated on logout and on credential change.
5. **Recovery is as strong as login.** A weak reset flow is the real login.
6. **Mobile and desktop OAuth/OIDC:** run in the system browser with PKCE, never in an embedded WebView.
7. **Store tokens in the OS vault** (Keychain/Keystore/credential manager), never in preferences or `localStorage` (see `data-privacy`).

## Verify
- Tests: expired token rejected; logout invalidates server-side; password change kills other sessions; recovery cannot bypass MFA.
- Rate limiting / backoff on login, recovery and any password-protected resource (per secret and per network origin; never trust a client-supplied IP header unless the edge overwrites it).
- No token, password or session ID in logs, URLs, deep links or analytics.

## Gotchas
- "Remember me" is a long-lived token: scope it and make it revocable.
- Magic links and OTP are convenient, not phishing resistant.

Sources: NIST SP 800-63-4 / 63B-4 (Jul 2025); OWASP Top 10:2025 A07; OWASP ASVS 5.0 (authentication, session, OAuth/OIDC chapters).
