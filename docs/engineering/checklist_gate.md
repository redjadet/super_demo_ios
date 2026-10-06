# Checklist gate (delivery / merge)

Honest Apple/Swift counterpart to Flutter `flutter_bloc_app`'s `./bin/checklist`
delivery gate. Same **role**: one named proof humans and agents must pass before
merge — not a second parallel theater.

## What runs

| Lane | Local | Hosted CI (`.github/workflows/ci.yml`) |
| --- | --- | --- |
| Markdown lint | `./bin/lint-markdown.sh` | job `lint` → Fastlane `ci_lint` |
| DESIGN.md (DesignMD) | `./tool/check_design_md.sh` | job `lint` → `ci_lint` (includes DesignMD) |
| Swift lint + modularity + evidence map | `./bin/lint.sh` | job `lint` |
| Common issues | `./tool/check_common_issues.sh` (sim runtime compat + AASA parity/live-host DNS honesty + Markdown relative links) | job `lint` |
| iPhone build/test | `./bin/ci-iphone-test.sh` | job `iphone-test` |
| iPad + Mac + watchOS builds | `./bin/ci-platform-builds.sh` (watch: `./bin/ci-watch-build.sh`) | job `platform-builds` |
| Aggregate gate | `./bin/checklist` (single command) | job **`checklist`** (needs the three macos jobs) |

**Xcode warnings are errors** on checklist / CI xcodebuild lanes via project
build settings (`SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`,
`GCC_TREAT_WARNINGS_AS_ERRORS=YES` on `superDemoApp.xcodeproj` configs — not
xcodebuild CLI overrides, which break SPM packages that already get
`-suppress-warnings`). Escape only with `XCODEBUILD_ALLOW_WARNINGS=1` (not for
merge proof).

## When to run

| Moment | Command |
| --- | --- |
| Docs / tooling / small Swift | `./bin/checklist-fast` |
| Before opening a PR (local delivery) | `./bin/checklist` |
| Hosted merge gate | GHA **`checklist`** green on the PR |
| Fastlane alias | `./bin/fastlane-run checklist` / `checklist_fast` |

Pre-commit (optional install via `./tool/install-git-hooks.sh`) runs
`./bin/verify-swift.sh` on staged `.swift` only — **not** a substitute for the
checklist gate.

## Failure look

- Any step exits non-zero → stop; fix that lane; re-run.
- Xcode warning under treat-as-error → build fails like an error.
- GHA: any of `lint` / `iphone-test` / `platform-builds` red → aggregate
  `checklist` fails → **do not merge**.

## Honesty (PR vs local)

Hosted `iphone-test` defaults to concrete newest-runtime iPhone + `xcodebuild
test` (`CI_IPHONE_GENERIC_BUILD=0`). The generic build-only path is an escape
hatch only. Local `./bin/checklist` uses the same script. See
[`../adr/0005-ci-pr-vs-local-honesty.md`](../adr/0005-ci-pr-vs-local-honesty.md)
and [`../ci-cd-map.md`](../ci-cd-map.md). Name the exact proof command in finish
reports.

## Related

- Chooser: [`validation_routing_fast_vs_full.md`](validation_routing_fast_vs_full.md)
- Agent gates map (“hooks” → scripts/CI): [`../ai-sdlc/gates.md`](../ai-sdlc/gates.md)
- Quick ref: [`../agents_quick_reference.md`](../agents_quick_reference.md)
- Flutter reference (in `flutter_bloc_app`, not this repo): `bin/checklist` →
  `tool/delivery_checklist.sh` — iOS equivalent is `./bin/checklist` (see
  [`../tooling_map.md`](../tooling_map.md))
