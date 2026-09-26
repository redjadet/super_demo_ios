# CI / CD map

Honest stage map for `superDemoApp`. **Bitrise rows are equivalents only** — this
repo does not run on Bitrise today. Optional sketch: [`../bitrise.yml.example`](../bitrise.yml.example).

**Delivery checklist gate:** local `./bin/checklist` · hosted GHA job `checklist`.
Canon: [`engineering/checklist_gate.md`](engineering/checklist_gate.md).

## Stages

| Stage | Hosted GitHub Actions | Local `./bin/checklist` / `./bin/ci.sh` | Manual Release Smoke | Credentialed beta lane |
| --- | --- | --- | --- | --- |
| Lint (+ DesignMD) | Yes — job `lint` → `bundle exec fastlane ci_lint` | Yes (checklist lint slice / Fastlane `ci`) | Optional | — |
| Unit / UI smoke | Job `iphone-test` → `./bin/ci-iphone-test.sh` (often **build + limited UI**; see [`testing.md`](testing.md) — do not assume full suite parity with every local run) | Yes — same script; warnings as errors | Optional targeted `xcodebuild test` | — |
| Platform builds | Job `platform-builds` → `./bin/ci-platform-builds.sh` (iPad + Mac) | Yes (unless `CHECKLIST_SKIP_PLATFORM_BUILDS=1` / `CI_SKIP_PLATFORM_BUILDS=1`) | — | — |
| Widget extension | Built/embedded with iPhone/iPad app targets (`superDemoAppWidget`, App Group snapshot + Feed refresh Live Activity UI); **not** embedded on Mac (`platformFilter = ios`) | Same as app lanes | — | Device App Group / Live Activity Island may need device; GHA compiles only |
| Share extension | Built/embedded with iPhone/iPad (`superDemoAppShare`, App Group inbox); **not** embedded on Mac (`platformFilter = ios`) | Same as app lanes | Manual share sheet on Simulator/device | Unsigned Simulator may lack App Group; Engineering demo can seed inbox |
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
| Release smoke | `.github/workflows/release-smoke.yml` — job `build-ipa` |
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
