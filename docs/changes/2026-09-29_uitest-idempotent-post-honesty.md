# 2026-09-29 — Idempotent POST UITest replay honesty

## Summary

`testIdempotentPostDemoIsReachable` must prove Accepted on first send and
Simulated duplicate-safe on second send — not merely that any outcome title
(including Failed) appears.

## Why

Mac Codex scan on tip `e399339` (rank 3 / e2e-15 after Host bridge #55): waiting
for `idempotentPostOutcomeTitle` alone never exercises replay and accepts Failed.

## Changes

- UITest: assert title `Accepted`, tap again, assert `Simulated duplicate-safe`
- `docs/testing.md` row clarified
- Portfolio tip pin → `8dd35a5` (#55)

## Proof

- GHA Delivery UITests on this PR (iPhone lane)
- Linux: markdown + common-issues / scorecard / router

## Out of scope

P2-A screenshots; visionOS; tip-pin-only ships.
