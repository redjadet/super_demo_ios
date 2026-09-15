# Audit — CI green baseline (2026-09-15)

## Context

After feed/items hardening and toolchain fixes, confirm main CI is green and
record the portfolio improvement order that followed.

## Evidence

- Baseline commit: `8e34c5e` — Fix markdownlint MD012 trailing blanks in changelog.
- Baseline workflow: [CI run 34910171465](https://github.com/redjadet/super_demo_ios/actions/runs/34910171465)
  — **success** (lint, iphone-test, platform-builds).
- Prior red: SwiftLint pin mismatch (0.63.2 vs brew 0.65.1); SwiftFormat `#if`
  indent; MD012 trailing blanks. Fixed on main.
- Xcode on CI: `tool/select_xcode.sh` selected `/Applications/Xcode_26.6.app
  [released]` on `macos-26`.
- Latest hygiene: `70fe3b8` — MainActor isolation + layer-check grep fallback;
  [CI run 34957828941](https://github.com/redjadet/super_demo_ios/actions/runs/34957828941)
  — **success**.

## Findings

- Demo hardening (cancel, stale cache, deep links, OSLog crash monitor,
  ModelContainer recovery) is on main with green CI.
- Roadmap **P1–P6 shipped** on main:
  - P1 SwiftFormat pin
  - P2 Liquid Glass chrome
  - P3 Keychain token demo (flag-gated)
  - P4 Associated Domains + HTTPS deep links
  - P5 OSSignposts + Feed cache TTL
  - P6 App Intents (Open Feed / Items / Production Risks)
- Follow-up: MainActor `nonisolated` constants + layer-check `rg`/`grep` fallback
  (`docs/changes/2026-09-15_mainactor-isolation-layer-check.md`).
- Follow-up: SwiftData store wipe + recreate before in-memory
  (`c6e38cf`; `docs/changes/2026-09-15_swiftdata-store-recovery.md`).
- Still deferred (intentional): vendor crash SDK, production auth beyond demo
  Keychain flag, App Store / TestFlight release packaging,
  formal `SchemaMigrationPlan`.

## Risk

Low for merge gate. SwiftFormat/SwiftLint pins reduce brew-drift risk. Layer
checks no longer depend on ripgrep being on Xcode’s PATH.

## Recommended next step

No queued P7+. Pick a new portfolio goal before starting work (for example:
vendor crash SDK, real auth refresh against a backend, or release-lane polish).
