# CI / CD map

Honest stage map for `superDemoApp`. **Bitrise rows are equivalents only** — this
repo does not run on Bitrise today. Optional sketch: [`../bitrise.yml.example`](../bitrise.yml.example).

**Delivery checklist gate:** local `./bin/checklist` · hosted GHA job `checklist`.
Canon: [`engineering/checklist_gate.md`](engineering/checklist_gate.md).

## Stages

| Stage | Hosted GitHub Actions | Local `./bin/checklist` / `./bin/ci.sh` | Manual Release Smoke | Credentialed beta lane |
| --- | --- | --- | --- | --- |
| Lint (+ DesignMD) | Yes — job `lint` → `bundle exec fastlane ci_lint` | Yes (checklist lint slice / Fastlane `ci`) | Optional | — |
| Unit / UI smoke | Job `iphone-test` → `./bin/ci-iphone-test.sh` on newest iPhone Simulator (`CI_IPHONE_GENERIC_BUILD=0`); escape hatch `=1` for generic build-only — see [`testing.md`](testing.md) | Yes — same script; warnings as errors | Optional targeted `xcodebuild test` | — |
| Platform builds | Job `platform-builds` → `./bin/ci-platform-builds.sh` (iPad + Mac + watchOS) | Yes (unless `CHECKLIST_SKIP_PLATFORM_BUILDS=1` / `CI_SKIP_PLATFORM_BUILDS=1`; watch skip: `CI_SKIP_WATCH_BUILD=1`) | — | — |
| Widget extension | Built/embedded with iPhone/iPad app targets (`superDemoAppWidget`, App Group snapshot + Feed refresh Live Activity UI); **not** embedded on Mac (`platformFilter = ios`) | Same as app lanes | — | Device App Group / Live Activity Island may need device; GHA compiles only |
| Flutter add-to-app | iPhone + iPad lanes: `subosito/flutter-action` → `./tool/prepare_flutter_embed.sh` (**`--no-codesign`**) → `SUPERDEMO_REQUIRE_FLUTTER_EMBED=1`; Mac lane skips Flutter link (sdk-filtered) | Same prepare on macOS before iOS Simulator run | — | Frameworks not committed; see [`flutter-add-to-app.md`](flutter-add-to-app.md) |
| Share extension | Built/embedded with iPhone/iPad (`superDemoAppShare`, App Group inbox); **not** embedded on Mac (`platformFilter = ios`) | Same as app lanes | Manual share sheet on Simulator/device | Unsigned Simulator may lack App Group; empty URL/text shares are not written; Engineering demo can seed inbox |
| watchOS companion | Scheme `superDemoAppWatch` + embed Watch Content on iPhone/iPad (`platformFilter = ios`); `./bin/ci-watch-build.sh` from platform-builds; shared `FeedWidgetShared` snapshot DTO | Same platform lane (skip with `CI_SKIP_WATCH_BUILD=1`) | Watch Simulator / device | Watch App Group is **local** (not phone↔watch sync); seed demo on watch when absent; visionOS not in this slice |
| Gate | Job **`checklist`** requires the three macos jobs | `./bin/checklist` (single-command) or `./bin/ci.sh` | — | — |
| Archive | **Not** normal PR CI | Optional local archive | [`release-smoke.yml`](../.github/workflows/release-smoke.yml) `build-ipa` (manual `workflow_dispatch`) | Clean archive inside beta lane |
| TestFlight upload | Needs signing + App Store Connect credentials — **not** on every PR | — | — | `./bin/fastlane-run ios beta` |

**Merge proof:** local `./bin/checklist` (single-command delivery gate). Hosted
merge requires GHA job **`checklist`** green. Record local test results
separately from hosted CI when they diverge. See
[`engineering/checklist_gate.md`](engineering/checklist_gate.md).

## Real identifiers

| Piece | Where |
| --- | --- |
| Workflow | `.github/workflows/ci.yml` — jobs `lint`, `iphone-test`, `platform-builds`, **`checklist`** |
| Runner / Xcode | Hosted jobs: `runs-on: xcode-27`. Workflow sets `SUPER_DEMO_XCODE_MIN_VERSION=27`; each macos job runs `source ./tool/select_xcode.sh` (newest **released** Xcode; today **27.1** / GM build). iPhone destination: newest iOS Simulator runtime that ships with that Xcode (`tool/ensure_ci_simulator.sh` / `tool/ios_simulator_runtime.sh`); prefer iPhone **Pro** → Pro Max → Plus → base, skip Duo/Fold/Air; UDID case normalized. Escape: `runs-on: macos-26` + `SUPER_DEMO_XCODE_MIN_VERSION=26.5` |
| Release smoke | `.github/workflows/release-smoke.yml` — job `build-ipa` (same `xcode-27` + select step) |
| Scripts | `./bin/checklist`, `./bin/checklist-fast`, `./bin/lint.sh`, `./bin/ci-iphone-test.sh`, `./bin/ci-platform-builds.sh`, `./bin/ci.sh`, `./bin/fastlane-run` |
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
