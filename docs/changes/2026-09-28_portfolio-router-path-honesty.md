# 2026-09-28 — Portfolio / router path honesty + workspace layout fix

Post-#40 tip `6c5d4be` still had cold-path docs using abbreviated
`App/` / `Shared/` / `Features/` paths (CODEMAP was fixed; portfolio +
architecture-tour were not), a stale portfolio tip pin at `d21d81a`, and
workspace-layout rows claiming `superDemoApp/superDemoAppTests/` (paths that
do not exist at git root).

## Changes

1. Root-resolvable `superDemoApp/…` paths in `docs/portfolio.md`,
   `docs/architecture-tour.md`, `docs/navigation.md`, `docs/design_system.md`,
   and `docs/agent_project_context.md` (shipped features / Current App).
2. Portfolio inventory pin → `6c5d4be` (post #36–#40).
3. Fix workspace-layout test paths to repo-root `superDemoAppTests/` /
   `superDemoAppUITests/`.
4. New gate `tool/check_router_doc_paths.sh` (`--self-test`) wired through
   `check_common_issues.sh`; tooling_map + agents quick reference rows.
5. Clarify checklist_gate Flutter `delivery_checklist.sh` is not an iOS path.

## Proof

- `./tool/check_router_doc_paths.sh --self-test`
- `./tool/check_router_doc_paths.sh`
- `./tool/check_common_issues.sh` (includes new gate)
- `./bin/lint-markdown.sh`
