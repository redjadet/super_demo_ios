# Change — watch/tvOS Simulator launch retry + ui-2 launch test order

**Date:** 2026-10-08

## What

- `./bin/ci-watch-build.sh` and `./bin/ci-tvos-build.sh` retry hosted `test` once
  when Simulator launch fails with termination-assertion / install-launch flakes
  (shutdown → erase → boot, same coverage).
- `ui-2` shard runs `testLaunchShowsAddItemControl` first so Items chrome is
  checked before long Engineering + Feed UI cases.
- `testLaunchShowsAddItemControl` relaunches once when Items chrome does not
  settle (no skipped assertions).

## Why

Main CI run `37744806904` (post–#95 merge) failed on watchOS Simulator launch
and `ui-2` `testLaunchShowsAddItemControl` (`waitForItemsChrome` timeout after
~25s). PR #95 had green `platform-builds` and `ui-2`; failures look
environmental / ordering-sensitive, not missing coverage.

## Proof

- `python3 ./tool/check_ci_contracts.py` (shard coverage unchanged).
- PR CI: `platform-builds` + `Checklist · iPhone test (ui-2)`.
