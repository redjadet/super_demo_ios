# CI faster PR checks (2026-10-06)

## Why

Hosted PR critical path was dominated by a single `Checklist · iPhone test` job
(~33m median wall). Lint (~0.7m) and platform builds (~3.5m) were already
parallel and not on the critical path.

## What changed

Adopted `redjadet/flutter_bloc_app` PR CI patterns, adapted for Xcode:

- **`changes` scope job** + `./bin/checklist --print-scope` /
  `tool/checklist_scope.sh` (docs-only allowlist; unknown → full CI)
- **Parallel lanes** with required **`Delivery checklist`** aggregator
- **Build once, test many:** `build-for-testing` artifact → matrix
  `test-without-building` shards (`unit-and-app-ui`, `engineering-a`,
  `engineering-b`) covering the same tests (still skips
  `testLaunchPerformance` on CI)
- **Composite setup** `.github/actions/setup-ios-ci` (Xcode select, Flutter,
  Brewfile, SPM/DerivedData/Flutter-embed + Homebrew caches)
- **Concurrency:** `cancel-in-progress` only for `pull_request` (never main)
- **Docs-only PRs:** Xcode lanes bypass on Ubuntu; matrix shards skipped;
  aggregator still green

## Non-goals

- Did not remove or skip any production test (same suite composition).
- Did not rename the required **`Delivery checklist`** check.
- Did not add failure-hiding retries (kept single Accessibility / launch-progress
  reboot retry already in `bin/ci-iphone-test.sh`).

## Follow-ups during CI iteration

- Sourced `ensure_ci_simulator.sh` from GHA must use `BASH_SOURCE` for ROOT.
- iPhone test shards need Brewfile (`rg`) for runtime-compat guards.
- CI pins the newest *installed* simulator runtime by default (no multi-GB
  `-downloadPlatform`); set `CI_DOWNLOAD_IOS_PLATFORM=1` to opt in. Compat
  check allows older-runtime fallback when newest has incompatible
  `supportedDeviceTypes`.
