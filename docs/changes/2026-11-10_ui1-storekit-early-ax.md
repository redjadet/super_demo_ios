# Change — ui-1 StoreKit early + typed prefix waits

**Date:** 2026-11-10

## What

- Reorder `CI_IPHONE_TEST_SHARD=ui-1` so StoreKit runs immediately after deep
  links, before idempotent POST and local-notification demos.
- `UiTestSupport.waitForIdentifierPrefix` polls cells / staticTexts /
  otherElements / buttons with `BEGINSWITH` instead of one long
  `descendants(.any).waitForExistence`.
- StoreKit empty/unavailable fallthrough timeout raised to 15s (still
  terminal-state only).

## Why

PR #116 Delivery run
[42860011085](https://github.com/redjadet/super_demo_ios/actions/runs/42860011085)
on Xcode **27.2**: `testStoreKitProductQueryDemoIsReachable` failed twice
(including sim-reboot retry) with `Timed out while evaluating UI query` while
resolving `Any (First Match)` / `storeKitStatusEmpty` after Load. Coverage
unchanged — order + query shape only.

## Proof

- `python3 tool/check_ci_contracts.py`
- Local `testStoreKitProductQueryDemoIsReachable` on iPhone 18 Pro / 27.2
