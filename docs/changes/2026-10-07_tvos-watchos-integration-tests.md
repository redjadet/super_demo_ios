# Change — watchOS / tvOS Feed companion integration tests

**Date:** 2026-10-07

## What

- Added `superDemoAppWatchTests` and `superDemoAppTVTests` (hosted XCTest).
- Shared `FeedCompanionDemoSnapshot` seed factories used by companion UI + tests.
- `./bin/ci-watch-build.sh` / `./bin/ci-tvos-build.sh` prefer `xcodebuild test`
  on a concrete Simulator UDID; fall back to unsigned `build` when only a
  generic destination exists.
- Real App Group tests save/restore any prior snapshot (Codex review).

## Proof

Mac mini Simulator: 5/5 watch + 5/5 tvOS cases **TEST SUCCEEDED**.

## Honesty

GHA may still compile-only when no concrete watch/tv Simulator UDID is
available; see `docs/testing.md`.
