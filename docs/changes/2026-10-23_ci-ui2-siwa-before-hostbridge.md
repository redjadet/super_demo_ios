# Change — ui-2 SIWA before HostBridge

**Date:** 2026-10-23

## What

Reorder `CI_IPHONE_TEST_SHARD=ui-2` so
`testSignInWithAppleDemoIsReachable` runs immediately after
`testLaunchShowsAddItemControl`, before
`testHostBridgePingDemoReturnsResponse`.

## Why

PR #113 Delivery run
[39951355789](https://github.com/redjadet/super_demo_ios/actions/runs/39951355789):
**Checklist · iPhone test (ui-2)** failed
`testSignInWithAppleDemoIsReachable` twice (including the existing
Accessibility / UI-query sim reboot retry) with
`Timed out while evaluating UI query` while resolving
`signInWithAppleDemoLink`. Remaining ui-2 cases passed. Same early-order
pattern as ui-1 deep links / ui-2 launch-first; no assertion weakening.

## Proof

- Shard map: `tool/ci_iphone_test_shards.sh` (coverage unchanged).
- `python3 tool/check_ci_contracts.py` (full UI case coverage once).
