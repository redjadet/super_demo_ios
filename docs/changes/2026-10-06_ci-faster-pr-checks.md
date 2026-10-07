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
- **Default layout (`iphone_layout=sharded`):** units in `iphone-build`; UI on
  matrix shards `ui-1`…`ui-4` (6 cases each = 24). Artifact handoff strips
  `*.dSYM` before upload. Shard jobs boot the sim **after** product download
  via `tool/ci_simulator_boot_ready.sh` (retry once) — overlapping boot with
  download starved `bootstatus` (ui-4 fail on run `37490468148`).
- **Optional single layout (`iphone_layout=single`):** one `Checklist · iPhone`
  job with background boot during setup/build (no artifact round-trip).
- **Reuse-only simulators:** `tool/ci_simulator_pick_existing.sh` (never
  create/erase by default); `tool/ci_simulator_boot_bg.sh` /
  `tool/ci_simulator_await.sh` / `tool/ci_simulator_boot_ready.sh`
- **Composite setup** `.github/actions/setup-ios-ci` — `HOMEBREW_NO_AUTO_UPDATE`,
  optional lean brew packages, SPM/DerivedData/SourcePackages/Flutter-embed
  caches; Flutter rebuild skipped on embed cache hit
- **Concurrency:** `cancel-in-progress` only for `pull_request` (never main)
- **Docs-only PRs:** Xcode lanes bypass on Ubuntu; aggregator still green

## Non-goals

- Did not remove or skip any production test (same suite composition: 187).
- Did not rename the required **`Delivery checklist`** check.
- Kept a **single** reboot+retry for Accessibility / launch-progress /
  UI-query timeouts in `bin/ci-iphone-test.sh` (no unlimited retries).

## Observed floor (honest)

Sharded layout with Flutter cache hit still lands ~**28–33m** critical path
(build ~10m + UI shard ~14–18m including artifact download/boot). The ≤20m
stretch target is **not** met without thinning coverage or infra changes;
this PR keeps the proven ~**6m** improvement vs ~34m baseline.

## Follow-ups during CI iteration

- Sourced `ensure_ci_simulator.sh` from GHA must use `BASH_SOURCE` for ROOT.
- Compat static guards use `grep` so UI shards need no Brewfile `rg`.
- CI pins the newest *installed* simulator runtime by default (no multi-GB
  `-downloadPlatform`); set `CI_DOWNLOAD_IOS_PLATFORM=1` to opt in. Compat
  check allows older-runtime fallback when newest has incompatible
  `supportedDeviceTypes`.
- Boot sim **after** shard artifact download (`ci_simulator_boot_ready.sh`).
- Harden Items chrome waits + move `testItemRowOpensDetail` off heavy eng shards.
