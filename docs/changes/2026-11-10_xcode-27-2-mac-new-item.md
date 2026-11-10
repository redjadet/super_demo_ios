# Change — Xcode 27.2 verify + Mac ⌘N owns New Item

**Date:** 2026-11-10

## Behavior

Local Mac mini / Lacie verification on **Xcode 27.2** (`27B52`) with iOS **27.2**
Simulator and a standard **iPhone 18 Pro** (not Duo). README / agent / CI-map
pins state 27.2 as the verified local toolchain while hosted `xcode-27` may
still select 27.1 until runners refresh.

On macOS, `CommandGroup(after: .newItem)` left system **New Window** on ⌘N, so
UITests and reviewers could open a second window instead of creating a note.
`MacAppCommands` now uses `CommandGroup(replacing: .newItem)`. Under
`-UITesting`, `MacUITestingWindowPlacement` re-centers the main window so AX
geometry is not stuck at `inf, inf` on multi-display hosts. MacPortfolioUITests
prefer keyboard focus paths and `itemRow-*` identifiers.

## Verification

- `CI_IPHONE_TEST_SHARD=unit|ui-1|ui-2|ui-3|ui-4` on iPhone 18 Pro / iOS 27.2: PASS
- `./bin/ci-platform-builds.sh` (iPad Pro 13 M5 build, macOS build, watchOS/tvOS
  compile-only — no watch/tv runtimes installed): PASS
- iPad unit + thin UI smoke; macOS `superDemoAppTests`: PASS
- MacPortfolioUITests: build-for-testing PASS; full interactive run still host-
  sensitive (Automation / display). Assertions not weakened.

## Scope

No CI workflow weakening. Deployment floors unchanged (26.7).
