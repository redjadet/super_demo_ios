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
| iPhone build-for-testing | Job `iphone-build` → `./bin/ci-iphone-build-for-testing.sh`; uploads Products / `.xctestrun` | Optional local `./bin/ci-iphone-build-for-testing.sh` | — | — |
| Unit / UI smoke | Matrix job `iphone-test` shards → `./bin/ci-iphone-test.sh` with `test-without-building` (`CI_IPHONE_GENERIC_BUILD=0`); escape hatch `=1` for generic build-only — see [`testing.md`](testing.md) | Full unsharded `./bin/ci-iphone-test.sh`; warnings as errors | Optional targeted `xcodebuild test` | — |
| Platform builds | Job `platform-builds` → `./bin/ci-platform-builds.sh` (iPad + Mac + watchOS) | Yes (unless `CHECKLIST_SKIP_PLATFORM_BUILDS=1` / `CI_SKIP_PLATFORM_BUILDS=1`; watch skip: `CI_SKIP_WATCH_BUILD=1`) | — | — |
| Widget extension | Built/embedded with iPhone/iPad app targets (`superDemoAppWidget`, App Group snapshot + Feed refresh Live Activity UI); **not** embedded on Mac (`platformFilter = ios`) | Same as app lanes | — | Device App Group / Live Activity Island may need device; GHA compiles only; stale Home Screen: see [`performance-lab.md`](performance-lab.md#widget-appex-install--deriveddata-playbook) |
| Flutter add-to-app | iPhone + iPad lanes: `subosito/flutter-action` → `./tool/prepare_flutter_embed.sh` (**`--no-codesign`**) → `SUPERDEMO_REQUIRE_FLUTTER_EMBED=1`; Mac lane skips Flutter link (sdk-filtered) | Same prepare on macOS before iOS Simulator run | — | Frameworks not committed; see [`flutter-add-to-app.md`](flutter-add-to-app.md) |
| Share extension | Built/embedded with iPhone/iPad (`superDemoAppShare`, App Group inbox); **not** embedded on Mac (`platformFilter = ios`) | Same as app lanes | Manual share sheet on Simulator/device | Unsigned Simulator may lack App Group; empty URL/text shares are not written; Engineering demo can seed inbox |
| watchOS companion | Scheme `superDemoAppWatch` + embed Watch Content on iPhone/iPad (`platformFilter = ios`); `./bin/ci-watch-build.sh` from platform-builds; shared `FeedWidgetShared` snapshot DTO | Same platform lane (skip with `CI_SKIP_WATCH_BUILD=1`) | Watch Simulator / device | Watch App Group is **local** (not phone↔watch sync); seed demo on watch when absent; visionOS not in this slice |
| Gate | Job **`checklist`** (`Delivery checklist`) requires `changes` + `lint` + `iphone-build` + `iphone-test` shards + `platform-builds` (docs-only: shards may be skipped) | `./bin/checklist` (single-command) or `./bin/ci.sh` | — | — |
| Archive | **Not** normal PR CI | Optional local archive | [`release-smoke.yml`](../.github/workflows/release-smoke.yml) `build-ipa` (manual `workflow_dispatch`) | Clean archive inside beta lane |
| TestFlight upload | Needs signing + App Store Connect credentials — **not** on every PR | — | — | `./bin/fastlane-run ios beta` |

**Merge proof:** local `./bin/checklist` (single-command delivery gate). Hosted
merge requires GHA job **`checklist`** green. Record local test results
separately from hosted CI when they diverge. See
[`engineering/checklist_gate.md`](engineering/checklist_gate.md).

## Real identifiers

| Piece | Where |
| --- | --- |
| Workflow | `.github/workflows/ci.yml` — jobs `changes`, `lint`, `iphone-build`, matrix `iphone-test`, `platform-builds`, **`checklist`** |
| Runner / Xcode | Hosted Xcode jobs: `runs-on: xcode-27` via `.github/actions/setup-ios-ci` (`source ./tool/select_xcode.sh`). Workflow sets `SUPER_DEMO_XCODE_MIN_VERSION=27` (newest **released** Xcode by ProductBuildVersion; prefer clean non-`_beta` path aliases; today **27.1** / GM). Docs-only bypasses use `ubuntu-latest`. `iphone-build` timeout 45m; each `iphone-test` shard 40m. iPhone destination: newest iOS Simulator runtime that ships with that Xcode (`tool/ensure_ci_simulator.sh` / `tool/ios_simulator_runtime.sh`); create only types in that runtime’s `supportedDeviceTypes` (avoids simctl 403 when e.g. iPhone 18 Pro is unsupported on some 27.1 images); prefer Pro → Pro Max → Plus → base, skip Duo/Fold/Air; UDID case normalized. Escape: `runs-on: macos-26` + `SUPER_DEMO_XCODE_MIN_VERSION=26.5` |
| Concurrency | `cancel-in-progress` only when `github.event_name == 'pull_request'` (never on `main`) |
| Release smoke | `.github/workflows/release-smoke.yml` — job `build-ipa` (same `xcode-27` + select step) |
| Scripts | `./bin/checklist` (`--print-scope`), `./bin/checklist-fast`, `./bin/lint.sh`, `./bin/ci-iphone-build-for-testing.sh`, `./bin/ci-iphone-test.sh`, `./bin/ci-platform-builds.sh`, `./bin/ci.sh`, `./bin/fastlane-run`, `./bin/coverage-iphone.sh` (optional local/nightly coverage; not a PR gate); scope: `tool/checklist_scope.sh` |
| Warnings as errors | `tool/xcode_warnings_as_errors_flags.sh` (used by iPhone + platform scripts) |
| Fastlane | `fastlane/Fastfile` — `ci_lint`, `ci`, `checklist`, `checklist_fast`, `ios beta`, `ios release` |
| Agent chooser | [`agents_quick_reference.md`](agents_quick_reference.md) |
| Gate doc | [`engineering/checklist_gate.md`](engineering/checklist_gate.md) |

## Bitrise equivalents (not live)

| GHA / local | Equivalent Bitrise step (sketch) |
| --- | --- |
| `lint` | Script → `./bin/lint.sh` or `bundle exec fastlane ci_lint` |
| `iphone-test` | Script → `./bin/ci-iphone-test.sh` |
| `platform-builds` | Script → `./bin/ci-platform-builds.sh` |
| Beta upload | Fastlane match/certs + `./bin/fastlane-run ios beta` with secrets |

Do not claim the repository is configured on Bitrise unless a live app exists.
