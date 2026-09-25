# 2026-09-25 — Agent worktree + thin maintain (FP-P1-C) + harness closeout (FP-P1-B)

## Summary

Isolated worktrees (`./bin/agent-worktree` → `tool/create_agent_worktree.sh`)
with plan-only default and `--apply` create. Thin `./bin/agent-maintain` for
`session` / `preflight` / `closeout` only (no Flutter host sync day-one).
Docs: host-maintenance, harness scorecard, SAFETY-REPORT template. Linked from
CODEMAP / AGENTS / quick ref / finish gate.

## Paths

- [`../../bin/agent-worktree`](../../bin/agent-worktree)
- [`../../tool/create_agent_worktree.sh`](../../tool/create_agent_worktree.sh)
- [`../../bin/agent-maintain`](../../bin/agent-maintain)
- [`../agent_kb/host-maintenance.md`](../agent_kb/host-maintenance.md)
- [`../ai/harness-scorecard.md`](../ai/harness-scorecard.md) (FP-P1-B)
- [`../agent_kb/safety-report-template.md`](../agent_kb/safety-report-template.md) (FP-P1-B)
- [`../../CODEMAP.md`](../../CODEMAP.md), [`../../AGENTS.md`](../../AGENTS.md),
  [`../agents_quick_reference.md`](../agents_quick_reference.md)
- [`.gitignore`](../../.gitignore) — `.worktrees/`

## Proof

```bash
./bin/agent-worktree --name smoke-plan
./bin/agent-maintain session
./bin/agent-maintain preflight
./bin/agent-maintain closeout
./bin/checklist-fast
```

## Acceptance

- Worktree plans/creates `cursor/<slug>` under `.worktrees/<slug>`; prints `cd` path.
- Never fetches / reuses / overwrites.
- `preflight` prints validation chooser + safety paths.
- Harness areas listed; SAFETY-REPORT template has required sections.
- Documented in CODEMAP.
