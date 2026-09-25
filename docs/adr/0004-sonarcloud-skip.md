# ADR 0004 — SonarCloud skip (portfolio demo)

- **Status:** Accepted
- **Date:** 2026-09-25
- **Detail (canonical note):** [`../sonar-decision.md`](../sonar-decision.md)

## Context

SonarCloud badges look strong on portfolio READMEs, but need an org, secrets,
and triage ownership. Layer lint, SwiftLint, and `./bin/ci.sh` already gate
merge quality without a third-party analysis cloud.

## Decision

**Skip** standing up SonarCloud for this portfolio demo (default **no-go**).

Canonical fields and revisit triggers live only in
[`../sonar-decision.md`](../sonar-decision.md) — do not duplicate policy here.
This ADR indexes that decision into `docs/adr/` for Flutter-parity discoverability.

## Consequences

- No Sonar tokens in repo; no unpaid cloud analysis that cannot run in CI.
- Existing gates remain authoritative: `./bin/verify-swift.sh`, `./bin/lint.sh`
  (including layer boundaries), local/`GHA` map in [`../ci-cd-map.md`](../ci-cd-map.md).
- README must not show a Sonar badge until a future accepted ADR supersedes
  this skip with a green, owned pipeline.
- Revisit when: maintainer explicitly opts in with org, secrets policy, and a
  named triage owner (see sonar-decision note).
