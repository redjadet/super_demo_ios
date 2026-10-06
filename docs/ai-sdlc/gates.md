# Deterministic gates (“hooks” without vendor hook JSON)

Industry “hooks” = **must-run checks** before claiming done or merging. This
repo already has them as scripts and CI jobs. Agents must run the matching lane;
do not invent Claude-only hook config.

## Must-run before claiming done

| Change type | Gate command | Notes |
| --- | --- | --- |
| Any Markdown / docs | `./bin/lint-markdown.sh` | Also in `checklist-fast` / CI lint |
| Any Swift edit | `./bin/verify-swift.sh` | Format **then** lint; never lint alone |
| Docs / tooling / small Swift | `./bin/checklist-fast` | Prefer before PR for docs-only |
| SwiftUI / navigation / universal UI | `./bin/checklist` | Warnings as errors |
| Merge / PR delivery | `./bin/checklist` + GHA job **`checklist`** | [`../engineering/checklist_gate.md`](../engineering/checklist_gate.md) |
| Closeout report | `./bin/agent-maintain closeout` | SAFETY-REPORT reminder |

Chooser detail: [`../agents_quick_reference.md`](../agents_quick_reference.md),
[`../engineering/validation_routing_fast_vs_full.md`](../engineering/validation_routing_fast_vs_full.md).

## What each lane enforces

| Lane | Enforces |
| --- | --- |
| `./bin/verify-swift.sh` | SwiftFormat, SwiftLint, 4-space indent, agent patterns, layer boundaries |
| `./bin/lint.sh` | Same lint stack without auto-format; used by Xcode build script |
| `./bin/lint-markdown.sh` | markdownlint-cli2 on repo Markdown |
| `./tool/check_layer_boundaries.sh` | Domain/Presentation/Data import bans |
| `./tool/check_feature_folder_contract.sh` | Layered feature folder shape |
| `./tool/check_feature_import_leaks.sh` | No cross-feature imports |
| `./tool/check_common_issues.sh` | Sim runtime, AASA parity, relative Markdown links, router paths |
| `./bin/checklist` | Lint + iPhone test + iPad/Mac/watch builds (local delivery) |
| GHA `lint` / `iphone-test` / `platform-builds` / `checklist` | Hosted merge gate — [`../ci-cd-map.md`](../ci-cd-map.md) |

## Optional local automation (not Claude hooks)

| Install | Behavior |
| --- | --- |
| `./tool/install-cursor-rules.sh` | Cursor rules + SwiftFormat-after-edit (fail open) |
| `./tool/install-git-hooks.sh` | `pre-commit` → `./bin/verify-swift.sh` on staged `.swift` |

These reduce drift; they **do not** replace checklist / CI. Skip pre-commit only
with explicit `SKIP_SWIFT_VERIFY=1` or `--no-verify` when the human asked.

## Protected / sensitive paths (agent write discipline)

No CODEOWNERS file today. Treat these as **high-scrutiny write-set** — declare
them in `plan.md` and prefer human approval (SAFETY-02 / SAFETY-06):

| Path / area | Why |
| --- | --- |
| `.github/workflows/` | Hosted CI shape; avoid conflicting with in-flight CI PRs |
| `superDemoApp.xcodeproj/` | Easy to break schemes/signing |
| `Config/`, entitlements, privacy manifests | Release / ATS / privacy impact |
| `fastlane/` signing + Match | Credentialed lanes need approval |
| Cross-feature imports / new `Features/` layout | Enforced by modularity scripts |
| Flutter embed prepare / frameworks | Generated; follow [`skills/flutter-add-to-app.md`](skills/flutter-add-to-app.md) |
| Secrets, Keychain demos, token stores | SECURITY skill; no secret commits |

Parallel work: do not edit open PR core files for unrelated kits (for example CI
workflow PRs or offline outbox feature PRs) unless that is the assigned task.

## PR review vs plan

When `docs/ai-sdlc/features/<slug>/plan.md` (or an example path) is present,
reviewers check the **diff against the plan**: write-set, acceptance, and proof
commands. See [`../ai_code_review_protocol.md`](../ai_code_review_protocol.md)
and [`../commit-and-pr-guidelines.md`](../commit-and-pr-guidelines.md).

## Agent reminder (copy into finish notes)

```text
1. Ran: ./bin/verify-swift.sh and/or ./bin/lint-markdown.sh as applicable
2. Ran: validation chooser lane (checklist-fast or checklist)
3. If features/<slug>/ exists: REVIEW.md filled; diff matches plan.md
4. No secrets; write-set respected; residual risk named
```
