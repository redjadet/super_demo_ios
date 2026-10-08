# Change — retry ui-2 app-launch timeout flake

**Date:** 2026-10-08

## What

`./bin/ci-iphone-test.sh` treats `Timed out while launching application` like
other Accessibility / launch-progress flakes (one sim reboot + shard retry).

## Why

PR #103 Delivery run
[37810297399](https://github.com/redjadet/super_demo_ios/actions/runs/37810297399):
**Checklist · iPhone test (ui-2)** failed only
`testHostBridgePingDemoReturnsResponse` with
`Timed out while launching application via Xcode` (~254s). Remaining ui-2
cases passed; prior head on the same PR was green. README-only merge from main
did not change product code — environmental first-launch wedge.

## Proof

- Pattern matches the failing log line; no shard coverage change.
- PR Delivery: Checklist · iPhone test (ui-2) + Delivery checklist.
