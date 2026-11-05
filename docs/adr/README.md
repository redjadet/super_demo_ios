# Architecture Decision Records

Short, durable **go / no-go** records for `superDemoApp`. Canon for behavior
still lives in topic docs (`layers.md`, `offline-first.md`, `ci-cd-map.md`, …);
ADRs make the *decision* and its consequences reviewable in one place.

## Index

| ADR | Title | Status |
| --- | --- | --- |
| [0001](0001-feature-layering.md) | Feature layering (Presentation / Domain / Data) | Accepted |
| [0002](0002-offline-first-posture.md) | Offline-first product posture | Accepted |
| [0003](0003-crash-vendor-deferred.md) | Vendor crash SDK deferred | Accepted |
| [0004](0004-sonarcloud-skip.md) | SonarCloud skip (portfolio demo) | Accepted |
| [0005](0005-ci-pr-vs-local-honesty.md) | CI PR-lane vs local-test honesty | Accepted |

## Format

Each ADR uses:

- **Status** — Accepted / Deferred / Superseded
- **Context** — Why a decision was needed
- **Options considered** — Reasonable alternatives and why they were not chosen
  (include non-code constraints: portfolio scope, secrets, CI cost, ops ownership)
- **Decision** — What we chose
- **Consequences** — Trade-offs, gates, non-goals
- **Revisit when** — Conditions to reconsider (budget, ownership, product scope)

ADRs are **engineering memory**, not permanent law. To overturn a decision,
add a new ADR that states why the old rationale no longer holds, mark the prior
ADR **Superseded** (link both ways), and update topic owners (`layers.md`,
`offline-first.md`, …) if behavior changes.

## Agents and AI reviewers

Before proposing or approving a change that touches **layers**, **offline/sync**,
**diagnostics vendors**, **quality cloud tooling**, or **CI / proof claims**:

1. Read this index and load **scoped** Accepted ADRs (not the whole tree).
2. Distinguish **implementation improvement** (same decision, better code) from
   **overturning the reasoning** (different trade-off, e.g. add Crashlytics,
   enable SonarCloud, bypass Domain/Data boundaries, “fix” sync by guessing server
   state on conflict, claim hosted CI ran the full local suite).
3. If the diff **conflicts** with an Accepted ADR, **stop and ask the human**:
   preserve the recorded decision, or explicitly revisit it (new/superseding ADR +
   human approval). Do **not** silently optimize for passing tests or local convenience.
4. AI review alone does not cover business or portfolio constraints — humans still
   judge ADR fit ([`../ai_code_review_protocol.md`](../ai_code_review_protocol.md)).

Load triggers: [`../ai/context_loading.md`](../ai/context_loading.md). Risk row:
[`../ai/ai_failure_risks.md`](../ai/ai_failure_risks.md) (`RISK-ADR-OVERTURN`).

## Related

- Task router: [`../../CODEMAP.md`](../../CODEMAP.md)
- Timed tour: [`../architecture-tour.md`](../architecture-tour.md)
- Sonar detail (kept as standalone decision note): [`../sonar-decision.md`](../sonar-decision.md)
