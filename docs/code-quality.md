# Code quality overview

Human-readable quality map for `superDemoApp`. **Not** the enforcement layer —
gates live in `bin/` / `tool/` and must pass on their own.

Reviewer evidence map:
[`engineering/engineering-evidence-map.md`](engineering/engineering-evidence-map.md).

## Coverage honesty

| Claim | Status |
| --- | --- |
| Measured line/branch `%` on `main` | **Documented unavailable** |
| README / shields.io coverage `%` badge | **Forbidden** until a real artifact exists |
| Hosted PR “tests green ⇒ coverage known” | **False** — tests green ≠ coverage measured |

**Why unavailable:** Hosted GitHub Actions `iphone-test` **does** run
`xcodebuild test` (unit + UI) on a concrete newest-runtime iPhone Simulator
(`CI_IPHONE_GENERIC_BUILD=0` — see [`testing.md`](testing.md),
[`ci-cd-map.md`](ci-cd-map.md), ADR 0005). That lane does **not** pass
`-enableCodeCoverage YES`, upload Codecov/Coveralls, or publish a filtered `%`
artifact. Escape hatch `CI_IPHONE_GENERIC_BUILD=1` is build-only and is **not**
the PR default.

**Optional local / nightly measurement:** `./bin/coverage-iphone.sh` runs
`xcodebuild test -enableCodeCoverage YES` and prints the `.xcresult` path for
inspection. It is **not** a PR gate and must not invent a README badge until a
named summary artifact exists and a change note allows it.

**When a badge is allowed:** only after a named, reproducible measurement
(e.g. that script or a nightly job + published summary artifact) and an
explicit change note. Until then, say “coverage undocumented” — never invent a
`%`.

Evidence-map gate also forbids fake coverage badges on README
(`./tool/check_engineering_evidence_map.sh`).

## CI honesty (PR-lane vs local)

Aligned with [`ci-cd-map.md`](ci-cd-map.md) and
[`adr/0005-ci-pr-vs-local-honesty.md`](adr/0005-ci-pr-vs-local-honesty.md):

| Lane | Role | Do not claim |
| --- | --- | --- |
| GHA `lint` / `iphone-test` / `platform-builds` → **`checklist`** | Hosted PR / merge gate | “Full unit/UI suite ran on every PR” |
| Local `./bin/checklist` | Authoritative **delivery / merge proof** | That GHA alone proved every local test |
| Local `./bin/ci` | Fastlane-orchestrated same lanes | Duplicate of checklist when both already green |
| Docs / tooling | `./bin/checklist-fast` | Merge readiness without naming the command |

Script name map (Flutter → iOS): [`tooling_map.md`](tooling_map.md).
Gate detail: [`engineering/checklist_gate.md`](engineering/checklist_gate.md).

Record local test results separately when they diverge from hosted build
results. Bitrise rows in the CI map are equivalents only — not live.

## Enforcement commands (source of truth)

| Concern | Command / doc |
| --- | --- |
| Format + SwiftLint + agent patterns | `./bin/verify-swift.sh` |
| Layers + modularity + evidence map | `./bin/lint.sh` |
| Layer boundaries only | `./tool/check_layer_boundaries.sh` |
| Feature folder + import leaks | `./tool/check_feature_folder_contract.sh`, `./tool/check_feature_import_leaks.sh` — [`modularity.md`](modularity.md) |
| Evidence map gate | `./tool/check_engineering_evidence_map.sh` |
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
| Senior habits map | [`engineering/senior-coding-patterns-map.md`](engineering/senior-coding-patterns-map.md) |
| Style | [`code-style.md`](code-style.md), [`agent_swift_guards.md`](agent_swift_guards.md) |
| Review | [`ai_code_review_protocol.md`](ai_code_review_protocol.md) |
| Sonar deferral | [`sonar-decision.md`](sonar-decision.md) |

## Out of scope (this overview)

- Inventing coverage thresholds or `%` badges.
- Replacing enforcement gates with prose.
- Supply-chain scanners (FP-P2-A) or live SonarCloud.
- Agent harness maturity (tracked separately from app implementation evidence).
