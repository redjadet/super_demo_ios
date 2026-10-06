# CI faster PR checks (2026-10-06)

## Why

Hosted PR critical path was dominated by a single `Checklist · iPhone test` job
(~33m median wall). Lint (~0.7m) and platform builds (~3.5m) were already
parallel and not on the critical path. First parallelization (build-once + 3
shards) only moved wall to ~33.0m — shard simulator pre-boot (5–7m each) and
build→artifact→shard handoff kept the critical path long.

## What changed

Adopted `redjadet/flutter_bloc_app` PR CI patterns, adapted for Xcode:

- **`changes` scope job** + `./bin/checklist --print-scope` /
  `tool/checklist_scope.sh` (docs-only allowlist; unknown → full CI)
- **Parallel lanes** with required **`Delivery checklist`** aggregator
- **Default layout (`CI_IPHONE_LAYOUT=single`):** one `Checklist · iPhone` job
  boots the sim in the background during setup/Flutter/`build-for-testing`,
  then runs all 187 tests via `test-without-building` with
  `-parallel-testing-enabled YES` (3 workers / simulator clones) — no
  cross-job artifact round-trip
- **Compare/fallback (`CI_IPHONE_LAYOUT=sharded`):** units in the build job;
  UI on `ui-a` / `ui-b` shards with early background boot + 2 parallel workers
- **Reuse-only simulators:** `tool/ci_simulator_pick_existing.sh` (never
  create/erase by default); `tool/ci_simulator_boot_bg.sh` /
  `tool/ci_simulator_await.sh`
- **Composite setup** `.github/actions/setup-ios-ci` — `HOMEBREW_NO_AUTO_UPDATE`,
  optional lean brew packages, SPM/DerivedData/SourcePackages/Flutter-embed
  caches; Flutter rebuild skipped on embed cache hit
- **Concurrency:** `cancel-in-progress` only for `pull_request` (never main)
- **Docs-only PRs:** Xcode lanes bypass on Ubuntu; aggregator still green

## Non-goals

- Did not remove or skip any production test (same suite composition: 187).
- Did not rename the required **`Delivery checklist`** check.
- Did not add failure-hiding retries (kept single Accessibility / launch-progress
  reboot retry already in `bin/ci-iphone-test.sh`).

## Follow-ups during CI iteration

- Sourced `ensure_ci_simulator.sh` from GHA must use `BASH_SOURCE` for ROOT.
- Compat static guards use `grep` so UI shards need no Brewfile `rg`.
- CI pins the newest *installed* simulator runtime by default (no multi-GB
  `-downloadPlatform`); set `CI_DOWNLOAD_IOS_PLATFORM=1` to opt in. Compat
  check allows older-runtime fallback when newest has incompatible
  `supportedDeviceTypes`.
- Target: median critical path ≤ ~20m for code-change PRs (measure ≥2 green
  runs after this iteration).
