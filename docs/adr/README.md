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
- **Decision** — What we chose
- **Consequences** — What follows (gates, non-goals, revisit triggers)

## Related

- Task router: [`../../CODEMAP.md`](../../CODEMAP.md)
- Timed tour: [`../architecture-tour.md`](../architecture-tour.md)
- Sonar detail (kept as standalone decision note): [`../sonar-decision.md`](../sonar-decision.md)
