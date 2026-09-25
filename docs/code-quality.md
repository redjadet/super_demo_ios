# Code quality overview

Human-readable quality map for `superDemoApp`. **Not** the enforcement layer —
gates live in `bin/` / `tool/` and must pass on their own.

Measured Engineering claim: [`engineering/engineering-quality-scorecard.md`](engineering/engineering-quality-scorecard.md)
(overall = **min** of areas; README Engineering badge only when gate passes).

## Coverage honesty

| Claim | Status |
| --- | --- |
| Measured line/branch `%` on `main` | **Documented unavailable** |
| README / shields.io coverage `%` badge | **Forbidden** until a real artifact exists |
| Hosted PR “tests green ⇒ coverage known” | **False** — see CI honesty below |

**Why unavailable:** GitHub Actions `iphone-test` runs a **build-heavy** lane via
`./bin/ci-iphone-test.sh` and does **not** run `xcodebuild test` (hang risk on
hosted runners — [`testing.md`](testing.md)). There is no checked-in coverage
rollup, no Codecov/Coveralls upload, and no local script that publishes a
filtered `%` for badges.

**When a badge is allowed:** only after a named, reproducible measurement
(e.g. local/CI `xcodebuild test -enableCodeCoverage YES` + published summary
artifact) and an explicit change note. Until then, say “coverage undocumented”
— never invent a `%`.

Scorecard gate already forbids fake coverage badges on README
(`./tool/check_engineering_quality_scorecard.sh`).

## CI honesty (PR-lane vs local)

Aligned with [`ci-cd-map.md`](ci-cd-map.md) and
[`adr/0005-ci-pr-vs-local-honesty.md`](adr/0005-ci-pr-vs-local-honesty.md):

| Lane | Role | Do not claim |
| --- | --- | --- |
| GHA `lint` / `iphone-test` / `platform-builds` → `lint-build-test` | Hosted PR gate | “Full unit/UI suite ran on every PR” |
| Local `./bin/ci.sh` | Authoritative **merge proof** | That GHA alone proved every local test |
| Docs / tooling | `./bin/checklist-fast` | Merge readiness without naming the command |

Record local test results separately when they diverge from hosted build
results. Bitrise rows in the CI map are equivalents only — not live.

## Enforcement commands (source of truth)

| Concern | Command / doc |
| --- | --- |
| Format + SwiftLint + agent patterns | `./bin/verify-swift.sh` |
| Layers + modularity + Eng scorecard | `./bin/lint.sh` |
| Layer boundaries only | `./tool/check_layer_boundaries.sh` |
| Feature folder + import leaks | `./tool/check_feature_folder_contract.sh`, `./tool/check_feature_import_leaks.sh` — [`modularity.md`](modularity.md) |
| Engineering X/10 gate | `./tool/check_engineering_quality_scorecard.sh` |
| Docs / fast proof | `./bin/checklist-fast` |
| Local merge proof | `./bin/ci.sh` |
| Validation chooser | [`agents_quick_reference.md`](agents_quick_reference.md), [`engineering/validation_routing_fast_vs_full.md`](engineering/validation_routing_fast_vs_full.md) |

## Architecture and review

| Topic | Doc |
| --- | --- |
| Task → path | [`../CODEMAP.md`](../CODEMAP.md) |
| Layers / features | [`layers.md`](layers.md), [`feature-template.md`](feature-template.md), [`modularity.md`](modularity.md) |
| Offline rules | [`offline-invariants.md`](offline-invariants.md) |
| Decisions | [`adr/README.md`](adr/README.md) |
| Style | [`code-style.md`](code-style.md), [`agent_swift_guards.md`](agent_swift_guards.md) |
| Review | [`ai_code_review_protocol.md`](ai_code_review_protocol.md) |
| Sonar deferral | [`sonar-decision.md`](sonar-decision.md) |

## Out of scope (this overview)

- Inventing coverage thresholds or `%` badges.
- Replacing scorecard / lint gates with prose.
- Supply-chain scanners (FP-P2-A) or live SonarCloud.
- Agent harness score (separate from Engineering X/10).
