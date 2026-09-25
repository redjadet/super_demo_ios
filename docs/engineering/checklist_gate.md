# Checklist gate (delivery / merge)

Honest Apple/Swift counterpart to Flutter `flutter_bloc_app`'s `./bin/checklist`
delivery gate. Same **role**: one named proof humans and agents must pass before
merge — not a second parallel theater.

## What runs

| Lane | Local | Hosted CI (`.github/workflows/ci.yml`) |
| --- | --- | --- |
| Markdown lint | `./bin/lint-markdown.sh` | job `lint` → Fastlane `ci_lint` |
| DESIGN.md (DesignMD) | `./tool/check_design_md.sh` | job `lint` → `ci_lint` (includes DesignMD) |
| Swift lint + modularity + scorecard | `./bin/lint.sh` | job `lint` |
| Common issues | `./tool/check_common_issues.sh` | job `lint` |
| iPhone build/test | `./bin/ci-iphone-test.sh` | job `iphone-test` |
| iPad + Mac builds | `./bin/ci-platform-builds.sh` | job `platform-builds` |
| Aggregate gate | `./bin/checklist` (single command) | job **`checklist`** (needs the three macos jobs) |

**Xcode warnings are errors** on checklist / CI xcodebuild lanes
(`SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`, `GCC_TREAT_WARNINGS_AS_ERRORS=YES`).
Escape only with `XCODEBUILD_ALLOW_WARNINGS=1` (not for merge proof).

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

Hosted `iphone-test` may be build + limited UI smoke on some runners; local
`./bin/checklist` runs the full iPhone test path via `./bin/ci-iphone-test.sh`.
See [`../adr/0005-ci-pr-vs-local-honesty.md`](../adr/0005-ci-pr-vs-local-honesty.md)
and [`../ci-cd-map.md`](../ci-cd-map.md). Name the exact proof command in finish
reports — do not claim “CI = all local tests”.

## Related

- Chooser: [`validation_routing_fast_vs_full.md`](validation_routing_fast_vs_full.md)
- Quick ref: [`../agents_quick_reference.md`](../agents_quick_reference.md)
- Flutter reference: `bin/checklist` → `tool/delivery_checklist.sh` (CI runs it)
