# 2026-09-29 — Host bridge ping UITest honesty

## Summary

`testHostBridgePingDemoReturnsResponse` requires a successful
`feed.cacheStatus` JSON response (`"ok":true`, echoed `"id":"demo-1"`,
`"source"`) — not merely nonempty / non-placeholder text.

## Why

Mac Codex scan on tip `e399339` (rank 2 / e2e-14 after #53): any nonempty
response after Ping could pass, including encode failures and `"ok":false`.

## Changes

- `EngineeringDemosUITests.testHostBridgePingDemoReturnsResponse` — assert
  successful decoded shape for the fixed demo request
- `docs/testing.md` row clarified
- Portfolio tip pin → `8dd35a5` (#55)

## Proof

- GHA Delivery UITests on this PR (iPhone lane)
- Linux: markdown + common-issues / scorecard / router

## Out of scope

Idempotent POST replay (e2e-15); P2-A screenshots; visionOS.
