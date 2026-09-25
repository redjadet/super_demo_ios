# 2026-09-25 — ADR bootstrap (FP-P0-D)

## Why

Flutter-parity P0: make layering, offline posture, crash-vendor deferral,
Sonar skip, and CI PR-vs-local honesty visible as short ADRs — not only prose
scattered across topic docs.

## Changes

- Add [`docs/adr/README.md`](../adr/README.md) index.
- Add five ADRs (Status / Context / Decision / Consequences):
  - [`0001-feature-layering.md`](../adr/0001-feature-layering.md)
  - [`0002-offline-first-posture.md`](../adr/0002-offline-first-posture.md)
  - [`0003-crash-vendor-deferred.md`](../adr/0003-crash-vendor-deferred.md)
  - [`0004-sonarcloud-skip.md`](../adr/0004-sonarcloud-skip.md) →
    [`sonar-decision.md`](../sonar-decision.md)
  - [`0005-ci-pr-vs-local-honesty.md`](../adr/0005-ci-pr-vs-local-honesty.md)
- Link index from [`CODEMAP.md`](../../CODEMAP.md),
  [`architecture-tour.md`](../architecture-tour.md), and [`docs/README.md`](../README.md).

## Proof

- Docs-only slice: `./bin/checklist-fast`
