# 2026-09-25 — Code quality overview + coverage honesty (FP-P1-D)

## Why

Flutter-parity P1: give reviewers a single quality overview separate from
enforcement, and state coverage as **documented unavailable** instead of a fake
`%` badge. Align PR-lane vs local-test honesty with the CI map.

## Changes

- Add [`docs/code-quality.md`](../code-quality.md) — overview, enforcement
  command table, coverage honesty, CI honesty.
- Point [`docs/ci-cd-map.md`](../ci-cd-map.md) at coverage status (no measured
  artifact; no badge).
- Link from CODEMAP, docs index, AGENTS task map, architecture tour, Engineering
  scorecard (replace “later” pointer).

## Proof

```bash
./bin/checklist-fast
./tool/check_engineering_quality_scorecard.sh
```

## Acceptance

- Doc states enforcement commands.
- Coverage badge only if measured — currently **unavailable**; never fake.
- PR-lane vs local-test honesty aligned with `docs/ci-cd-map.md`.
