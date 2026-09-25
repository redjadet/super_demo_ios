# Checklist gate + agent tooling parity

## Summary

Flutter-parity for the **delivery checklist gate** and agent-facing `bin/`/`tool/`
surface (not a blind copy of Dart scanners).

### Gate

- Local `./bin/checklist` composes the same scripts CI uses (`ci-iphone-test`,
  `ci-platform-builds`) with DesignMD + lint.
- GHA aggregate job **`checklist`** (was `lint-build-test`); lane jobs labeled
  Checklist · …
- `ci_lint` / Fastlane `ci` include DesignMD.
- Xcode warnings → errors via `tool/xcode_warnings_as_errors_flags.sh`.
- Canon: [`../engineering/checklist_gate.md`](../engineering/checklist_gate.md).
- PR template: `.github/pull_request_template.md`.

### Tooling surface (Flutter names)

| Added | Role |
| --- | --- |
| `bin/format`, `lint`, `lint-markdown`, `verify`, `verify-swift`, `ci` | Name aliases → existing `*.sh` |
| `bin/install-git-hooks` | → `tool/install-git-hooks.sh` |
| `bin/clean-build-caches` + `tool/clean_build_caches.sh` | DerivedData / `.build` (dry-run) |
| `bin/prune-git-stale` + `tool/prune_git_stale.sh` | Merged topics + stale worktrees |
| `bin/checklist_fix` | Re-run checklist; optional format between passes |
| `docs/tooling_map.md` | Flutter → iOS script map |

`agent-maintain` proof lanes now point at `./bin/checklist` + GHA `checklist`.

## Agent impact

- Prefer Flutter-style names (`./bin/format`, `./bin/lint`, `./bin/checklist`).
- Merge only when GHA **Delivery checklist** is green.
- Do not expect Hive/GoRouter/Melos scanners on iOS — see tooling map.

## Proof

```bash
./bin/checklist --help
./bin/agent-maintain preflight
./bin/clean-build-caches
./bin/prune-git-stale
./bin/lint-markdown.sh
./bin/lint
```

Follow-up commit: MainActor fixes for `DiagnosticRedaction`, `FeedPost`,
`ReviewerDemoFixtures.sampleFeedPosts`, and `CachingFeedRepository` default
publisher arg (warnings-as-errors under `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`).
