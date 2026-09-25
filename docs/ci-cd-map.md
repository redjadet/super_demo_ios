# CI / CD map

Honest stage map for `superDemoApp`. **Bitrise rows are equivalents only** — this
repo does not run on Bitrise today. Optional sketch: [`../bitrise.yml.example`](../bitrise.yml.example).

## Stages

| Stage | Hosted GitHub Actions | Local `./bin/ci.sh` | Manual Release Smoke | Credentialed beta lane |
| --- | --- | --- | --- | --- |
| Lint | Yes — job `lint` → `bundle exec fastlane ci_lint` | Yes (via Fastlane `ci`) | Optional | — |
| Unit / UI smoke | Job `iphone-test` → `./bin/ci-iphone-test.sh` (often **build + limited UI**; see [`testing.md`](testing.md) — do not assume full suite parity with every local run) | Yes — same Fastlane CI lanes as GHA | Optional targeted `xcodebuild test` | — |
| Platform builds | Job `platform-builds` → `./bin/ci-platform-builds.sh` (iPad + Mac) | Yes (unless `CI_SKIP_PLATFORM_BUILDS=1`) | — | — |
| Gate | Job `lint-build-test` requires the three macos jobs | Author re-runs `./bin/ci.sh` | — | — |
| Archive | **Not** normal PR CI | Optional local archive | [`release-smoke.yml`](../.github/workflows/release-smoke.yml) `build-ipa` (manual `workflow_dispatch`) | Clean archive inside beta lane |
| TestFlight upload | Needs signing + App Store Connect credentials — **not** on every PR | — | — | `./bin/fastlane-run ios beta` |

**Merge proof:** local `./bin/ci.sh`. Record local test results separately from
hosted CI build results when they diverge.

## Real identifiers

| Piece | Where |
| --- | --- |
| Workflow | `.github/workflows/ci.yml` — jobs `lint`, `iphone-test`, `platform-builds`, `lint-build-test` |
| Release smoke | `.github/workflows/release-smoke.yml` — job `build-ipa` |
| Scripts | `./bin/lint.sh`, `./bin/ci-iphone-test.sh`, `./bin/ci-platform-builds.sh`, `./bin/ci.sh`, `./bin/fastlane-run` |
| Fastlane | `fastlane/Fastfile` — `ci_lint`, CI aggregate, `ios beta`, `ios release` |
| Agent chooser | [`agents_quick_reference.md`](agents_quick_reference.md) |

## Bitrise equivalents (not live)

| GHA / local | Equivalent Bitrise step (sketch) |
| --- | --- |
| `lint` | Script → `./bin/lint.sh` or `bundle exec fastlane ci_lint` |
| `iphone-test` | Script → `./bin/ci-iphone-test.sh` |
| `platform-builds` | Script → `./bin/ci-platform-builds.sh` |
| Beta upload | Fastlane match/certs + `./bin/fastlane-run ios beta` with secrets |

Do not claim the repository is configured on Bitrise unless a live app exists.
