# Tooling map — Flutter `flutter_bloc_app` → iOS `superDemoApp`

Lean agent router. Flutter has a large `tool/check_*.sh` catalog; iOS keeps a
**small honest surface** over SwiftLint / Xcode / Fastlane. Do not expect a
1:1 Dart gate for every Flutter script.

Canon gates: [`engineering/checklist_gate.md`](engineering/checklist_gate.md),
[`agents_quick_reference.md`](agents_quick_reference.md).

## `bin/` parity

| Flutter | iOS | Notes |
| --- | --- | --- |
| `./bin/checklist` | `./bin/checklist` | Delivery / merge gate |
| `./bin/checklist-fast` | `./bin/checklist-fast` | Docs/tooling lane |
| `./bin/checklist_fix` | `./bin/checklist_fix` | Re-run + optional `./bin/format` |
| `./bin/format` | `./bin/format` → `format.sh` | SwiftFormat |
| `./bin/agent-maintain` | `./bin/agent-maintain` | Thin: session / preflight / closeout |
| `./bin/agent-worktree` | `./bin/agent-worktree` | `.worktrees/<slug>`, branch `cursor/<slug>` |
| `./bin/install-git-hooks` | `./bin/install-git-hooks` | → `tool/install-git-hooks.sh` |
| `./bin/clean-build-caches` | `./bin/clean-build-caches` | DerivedData / `.build` (dry-run default) |
| `./bin/prune-git-stale` | `./bin/prune-git-stale` | Merged topics + stale worktrees (dry-run) |
| *(Flutter CI via checklist)* | `./bin/ci` → `ci.sh` | Fastlane-orchestrated same lanes |
| — | `./bin/lint` → `lint.sh` | SwiftLint strict + modularity |
| — | `./bin/lint-markdown` | markdownlint-cli2 |
| — | `./bin/verify` / `verify-swift` | Format + lint for agents |
| `integration_*` | `./bin/ci-iphone-test.sh` | UI smoke / tests — not Flutter Driver |
| `router_feature_validate` | **N/A** | GoRouter-only |
| `upgrade_validate_all` | **N/A day-one** | No Melos; use Xcode/SPM manually |

## `tool/` parity (spirit)

| Flutter theme | iOS equivalent |
| --- | --- |
| `delivery_checklist.sh` | `bin/checklist` (composes lint + CI scripts) |
| `check_design_md.sh` | `tool/check_design_md.sh` |
| `check_feature_folder_contract.sh` | same name (via `./bin/lint`) |
| `check_feature_modularity_leaks.sh` | `tool/check_feature_import_leaks.sh` |
| `check_clean_architecture_imports.sh` | `tool/check_layer_boundaries.sh` |
| `check_engineering_quality_scorecard_gate.sh` | `tool/check_engineering_quality_scorecard.sh` |
| `integration_preflight` / device readiness | `tool/check_simulator_runtime_compat.sh` (+ `ensure_ci_simulator`) |
| Cubit/BLoC/Hive/Dio gates | **Skip** — not applicable |
| `create_agent_worktree.sh` | `tool/create_agent_worktree.sh` |
| `clean_build_caches.sh` | `tool/clean_build_caches.sh` (Xcode) |
| `prune_git_stale.sh` | `tool/prune_git_stale.sh` (lean) |
| Host sync / Melos / Dart analyze | **Not ported** — see host-maintenance.md |

## When to run what

| Intent | Command |
| --- | --- |
| Just formatted Swift | `./bin/verify` |
| Docs / DESIGN / tooling | `./bin/checklist-fast` |
| Pre-PR delivery | `./bin/checklist` |
| Hosted merge | GHA job **`checklist`** green |
| Disk reclaim | `./bin/clean-build-caches` then `--apply` |
| Stale worktrees/branches | `./bin/prune-git-stale` then `--apply` |
| Agent session start | `./bin/agent-maintain preflight` |
| Agent finish | `./bin/agent-maintain closeout` |

## Out of scope (do not fake)

- Melos / `dart analyze` / `flutter test` wrappers
- Hive / get_it / GoRouter / deferred-import scanners
- Copying all 200 Flutter `tool/check_*.sh` files

Prefer extending `tool/check_agent_swift_patterns.sh` + SwiftLint when a **real**
in-repo smell shows up (`FP-P2-C` in the Flutter-parity plan).
