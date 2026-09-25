# ADR 0003 — Vendor crash SDK deferred

- **Status:** Accepted (deferred vendor integration)
- **Date:** 2026-09-25
- **Owners:** [`../incident-playbook.md`](../incident-playbook.md),
  `superDemoApp/Shared/Diagnostics/`, [`../portfolio.md`](../portfolio.md)

## Context

Production apps usually ship Crashlytics, Sentry, or similar. This repo is a
portfolio demo: adding a vendor SDK without secrets, triage ownership, and
TestFlight proof would create badge theater and secret-leak risk.

## Decision

**Defer vendor crash / analytics SDKs.** Keep an in-repo swap point:

- Default: `OSLogCrashMonitor` — non-fatals → OSLog (`crash-monitor` category).
- Protocol: `CrashMonitoring` (adapter ready for a future vendor).
- Do **not** claim Organizer / vendor dashboards until a real adapter + delivery
  path is proven.

Document the gap honestly in release notes / incident playbook rather than
wiring an unpaid cloud product for show.

## Consequences

- Diagnostics demos prove OSLog + redaction + adapter shape — not Crashlytics.
- Release checklist may *recommend* configuring a vendor before production
  crash analytics; that is a future opt-in, not day-1 scope.
- Agents must not add Firebase/Sentry SPM packages or tokens under this ADR
  without an explicit new decision that names owner, secrets policy, and proof.
- Revisit when: maintainer opts in with credentials, triage owner, and a
  TestFlight (or equivalent) crash path.
