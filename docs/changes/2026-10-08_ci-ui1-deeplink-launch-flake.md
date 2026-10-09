# Change — ui-1 deep-link launch flake (process ID)

**Date:** 2026-10-08

## What

- `ui-1` shard runs `testDeepLinkOpensFeedPostDetail` /
  `testDeepLinkOpensItemsTab` **before** the long Engineering demos.
- `testDeepLinkOpensFeedPostDetail` relaunches once when detail chrome does not
  appear (same pattern as `testLaunchShowsAddItemControl`).
- `./bin/ci-iphone-test.sh` treats “does not have a process ID” like other
  Accessibility / launch-progress flakes (one sim reboot + retry).

## Why

Main CI run
[37773620216](https://github.com/redjadet/super_demo_ios/actions/runs/37773620216)
(`857f912`, #97): **Checklist · iPhone test (ui-1)** failed only
`testDeepLinkOpensFeedPostDetail` after three Engineering demos (~238s), with
`Application 'com.ilkersevim.superDemoApp' does not have a process ID`. Builds
and ui-2…ui-4 were green. Next deep-link case (`testDeepLinkOpensItemsTab`)
passed on the same job. This is consistent with a Simulator/XCTest launch
failure after the Engineering demos, but the logs do not isolate its cause
or exclude every routing defect. The detail assertions remain in the test.

## Proof

- `python3 ./tool/check_ci_contracts.py` (shard coverage unchanged).
- PR Delivery (#101): Checklist · iPhone test (ui-1) + Delivery checklist.
- Tip main after merge: Delivery green on
  [37828018857](https://github.com/redjadet/super_demo_ios/actions/runs/37828018857)
  (`17d795f`) — ui-1 included.
