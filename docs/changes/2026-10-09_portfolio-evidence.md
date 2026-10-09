# Change — portfolio evidence page for technical reviewers

**Date:** 2026-10-09

## What

- Add [`docs/EVIDENCE.md`](../EVIDENCE.md): role + AI-assisted workflow, scope
  limits, CI verification links, and five strongest engineering cases with
  exact source and regression-test citations.
- Link from README (near top) and [`docs/portfolio.md`](../portfolio.md).
- Prefer “technical reviewer” wording in linked architecture/index copy.

## Why

Technical reviewers need a single cold-path proof page: architecture/intent
ownership, honest scope, and runnable regression tests — without inventing
production claims.

## CI note

ui-1 deep-link process-ID flake was fixed earlier in #101; tip Delivery already
green (see change note
[`2026-10-08_ci-ui1-deeplink-launch-flake.md`](2026-10-08_ci-ui1-deeplink-launch-flake.md)).
This change is documentation + reviewer copy; Delivery on this PR is the
verification gate.
