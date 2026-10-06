# Skill: security

Repo security posture for agents. Deep checklist:
[`../../security-checklist.md`](../../security-checklist.md).

## Rules

1. **No secrets in git** — tokens, `.env`, match keys, ASC credentials stay out of
   source, docs, screenshots, and chat paste.
2. **Demo ≠ production auth** — Keychain / Sign in with Apple demos are portfolio
   wiring (`-KeychainTokenDemo`, Engineering demos). Do not claim OAuth production.
3. **Log redaction** — use `Logger` / existing `RedactedAPILogger` paths; never log
   Authorization headers or bodies.
4. **Least privilege** — no new entitlements, background modes, tracking, or
   required-reason APIs without owner docs + release impact.
5. **ATS / HTTPS** — prefer HTTPS; document exceptions.
6. **Credentialed lanes** — TestFlight / match / release need SAFETY-02 approval
   ([`../../agent_kb/agent_safety_contracts.md`](../../agent_kb/agent_safety_contracts.md)).

## Proof

- Secret scan via common-issues / checklist lint lanes
- Manual: confirm no new secrets in `git diff`
