# Audit — CI green baseline (2026-09-15)

## Context

After feed/items hardening and toolchain fixes, confirm main CI is green and
record remaining improvement order.

## Evidence

- Commit: `8e34c5e` — Fix markdownlint MD012 trailing blanks in changelog.
- Workflow: [CI run 34910171465](https://github.com/redjadet/super_demo_ios/actions/runs/34910171465)
  — **success** (lint, iphone-test, platform-builds).
- Prior red: SwiftLint pin mismatch (0.63.2 vs brew 0.65.1); SwiftFormat `#if`
  indent; MD012 trailing blanks. Fixed on main.
- Xcode on CI: `tool/select_xcode.sh` selected `/Applications/Xcode_26.6.app
  [released]` on `macos-26`.

## Findings

- Demo hardening (cancel, stale cache, deep links, OSLog crash monitor,
  ModelContainer recovery) is on main with green CI.
- SwiftFormat was unpinned (local 0.61.1 vs brew floating) — drift risk remains
  until version gate lands.
- Still deferred (intentional): vendor crash SDK, Keychain auth, associated
  domains, Liquid Glass chrome, App Intents.

## Risk

Low for merge gate. Medium for future brew bumps without a SwiftFormat pin.

## Recommended next step

P1 hygiene (SwiftFormat pin + this audit), then portfolio-visible P2 Liquid Glass
chrome and P3 Keychain token refresher behind a demo flag.
