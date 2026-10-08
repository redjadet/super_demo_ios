# CI / CD map

Honest stage map for `superDemoApp`. **Bitrise rows are equivalents only** — this
repo does not run on Bitrise today. Optional sketch: [`../bitrise.yml.example`](../bitrise.yml.example).

**Delivery checklist gate:** local `./bin/checklist` · hosted GHA job `checklist`.
Canon: [`engineering/checklist_gate.md`](engineering/checklist_gate.md).

## Stages

| Stage | Hosted GitHub Actions | Local `./bin/checklist` / `./bin/ci.sh` | Manual Release Smoke | Credentialed beta lane |
| --- | --- | --- | --- | --- |
| Change scope | Job `changes` → `./bin/checklist --print-scope` (`tool/checklist_scope.sh`) | Same `--print-scope`; docs-only local route skips Xcode | — | — |
| Lint (+ DesignMD) | Job `lint` → `bundle exec fastlane ci_lint` (docs-only: markdown + DesignMD + scope contract on Ubuntu) | Yes (checklist lint slice / Fastlane `ci`) | Optional | — |
| iPhone build + test | Default `iphone_layout=sharded`: `iphone-build` (units) + matrix `iphone-test` (`ui-1`…`ui-4`); sim boot after artifact download (`ci_simulator_boot_ready.sh`). Optional `single`: one `iphone` job with background boot | Full unsharded `./bin/ci-iphone-test.sh`; warnings as errors | Optional targeted `xcodebuild test` | — |
| Platform builds | Job `platform-builds` → `./bin/ci-platform-builds.sh` (iPad + Mac + watchOS + tvOS) | Yes (unless `CHECKLIST_SKIP_PLATFORM_BUILDS=1` / `CI_SKIP_PLATFORM_BUILDS=1`; watch skip: `CI_SKIP_WATCH_BUILD=1`; tvOS skip: `CI_SKIP_TVOS_BUILD=1`) | — | — |
| Widget extension | Built/embedded with iPhone/iPad app targets (`superDemoAppWidget`, App Group snapshot + Feed refresh Live Activity UI); **not** embedded on Mac (`platformFilter = ios`) | Same as app lanes | — | Device App Group / Live Activity Island may need device; GHA compiles only; stale Home Screen: see [`performance-lab.md`](performance-lab.md#widget-appex-install--deriveddata-playbook) |
| Flutter add-to-app | iPhone + iPad lanes: `subosito/flutter-action` → `./tool/prepare_flutter_embed.sh` (**`--no-codesign`**) → `SUPERDEMO_REQUIRE_FLUTTER_EMBED=1`; Mac lane skips Flutter link (sdk-filtered) | Same prepare on macOS before iOS Simulator run | — | Frameworks not committed; see [`flutter-add-to-app.md`](flutter-add-to-app.md) |
| Share extension | Built/embedded with iPhone/iPad (`superDemoAppShare`, App Group inbox); **not** embedded on Mac (`platformFilter = ios`) | Same as app lanes | Manual share sheet on Simulator/device | Unsigned Simulator may lack App Group; empty URL/text shares are not written; Engineering demo can seed inbox |
| watchOS companion | Scheme `superDemoAppWatch` + `superDemoAppWatchTests`; embed Watch Content on iPhone/iPad (`platformFilter = ios`); `./bin/ci-watch-build.sh` runs `test` when a concrete Watch Simulator UDID exists (else compile-only); one CI retry after shutdown/erase on Simulator launch flakes; shared `FeedWidgetShared` snapshot DTO | Same platform lane (skip with `CI_SKIP_WATCH_BUILD=1`) | Watch Simulator / device | Watch App Group is **local** (not phone↔watch sync); seed demo on watch when absent; GHA often lacks concrete Watch sims → build fallback; Mac mini proves XCTest |
| tvOS companion | Scheme `superDemoAppTV` + `superDemoAppTVTests` (standalone; not embedded in iPhone); `./bin/ci-tvos-build.sh` runs `test` when a concrete tvOS Simulator UDID exists (else compile-only); same `FeedWidgetShared` snapshot DTO | Same platform lane (skip with `CI_SKIP_TVOS_BUILD=1`) | tvOS Simulator / device | TV App Group is **local** (not phone↔TV sync); seed demo on TV when absent; GHA often lacks concrete TV sims → build fallback; Mac mini proves XCTest |
| Gate | Job **`checklist`** (`Delivery checklist`) requires `changes` + `lint` + iPhone lane(s) for the active layout + `platform-builds` (docs-only: Xcode lanes may bypass/skip) | `./bin/checklist` (single-command) or `./bin/ci.sh` | — | — |
| Archive | **Not** normal PR CI | Optional local archive | [`release-smoke.yml`](../.github/workflows/release-smoke.yml) `build-ipa` (manual `workflow_dispatch`) | Clean archive inside beta lane |
| TestFlight upload | Needs signing + App Store Connect credentials — **not** on every PR | — | — | `./bin/fastlane-run ios beta` |

**Merge proof:** local `./bin/checklist` (single-command delivery gate). Hosted
merge requires GHA job **`checklist`** green. Record local test results
separately from hosted CI when they diverge. See
[`engineering/checklist_gate.md`](engineering/checklist_gate.md).

## Real identifiers

| Piece | Where |
| --- | --- |
| Workflow | `.github/workflows/ci.yml` — jobs `changes`, `lint`, `iphone-build` + matrix `iphone-test` (default), optional `iphone`, `platform-builds`, **`checklist`** |
| Runner / Xcode | Hosted Xcode jobs: `runs-on: xcode-27` via `.github/actions/setup-ios-ci` (`source ./tool/select_xcode.sh`). Workflow sets `SUPER_DEMO_XCODE_MIN_VERSION=27` (newest **released** Xcode by ProductBuildVersion; prefer clean non-`_beta` path aliases; today **27.1** / GM). Docs-only bypasses use `ubuntu-latest`. Destination: pick existing iPhone (`tool/ci_simulator_pick_existing.sh`, `CI_SIMULATOR_REUSE_ONLY=1`); shard boot after download via `tool/ci_simulator_boot_ready.sh`. Escape: `runs-on: macos-26` + `SUPER_DEMO_XCODE_MIN_VERSION=26.5` |
| Concurrency | `cancel-in-progress` only when `github.event_name == 'pull_request'` (never on `main`) |
| Release smoke | `.github/workflows/release-smoke.yml` — job `build-ipa` (same `xcode-27` + select step) |
| Scripts | `./bin/checklist` (`--print-scope`), `./bin/checklist-fast`, `./bin/lint.sh`, `./bin/ci-iphone-build-for-testing.sh`, `./bin/ci-iphone-test.sh`, `./bin/ci-platform-builds.sh`, `./bin/ci.sh`, `./bin/fastlane-run`, `./bin/coverage-iphone.sh` (optional local/nightly coverage; not a PR gate); scope: `tool/checklist_scope.sh` |
| Warnings as errors | `tool/xcode_warnings_as_errors_flags.sh` (used by iPhone + platform scripts) |
| Fastlane | `fastlane/Fastfile` — `ci_lint`, `ci`, `checklist`, `checklist_fast`, `ios beta`, `ios release` |
| Agent chooser | [`agents_quick_reference.md`](agents_quick_reference.md) |
| Gate doc | [`engineering/checklist_gate.md`](engineering/checklist_gate.md) |

## PR latency and coverage

The existing four UI shards use measured test durations, rather than equal case
counts. `python3 tool/check_ci_contracts.py` enforces complete, unique UI coverage
except `testLaunchPerformance`, the existing hosted exclusion.

Flutter embed caches use exact input keys covering tracked module files and the
preparation script. Prepared flattened slices are reused after required-directory
checks and a script-digest match. Build-job boot begins after preparation to avoid
competing binary copies. First runs with a new cache key still build Flutter.
Timing evidence and proof commands:
[`changes/2026-10-07_ci-pr-critical-path.md`](changes/2026-10-07_ci-pr-critical-path.md).

## Bitrise equivalents (not live)

| GHA / local | Equivalent Bitrise step (sketch) |
| --- | --- |
| `lint` | Script → `./bin/lint.sh` or `bundle exec fastlane ci_lint` |
| `iphone-test` | Script → `./bin/ci-iphone-test.sh` |
| `platform-builds` | Script → `./bin/ci-platform-builds.sh` |
| Beta upload | Fastlane match/certs + `./bin/fastlane-run ios beta` with secrets |

Do not claim the repository is configured on Bitrise unless a live app exists.
