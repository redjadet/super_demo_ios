# Host maintenance (thin) — agent worktrees + session helpers

Back: [`agent_knowledge_base.md`](../agent_knowledge_base.md)

Day-one surface only — **no** Flutter-style host sync / install / trim.

## Entrypoints

| Command | Role |
| --- | --- |
| `./bin/agent-worktree` | Plan or create an isolated git worktree (`tool/create_agent_worktree.sh`) |
| `./bin/agent-maintain session` | Read-only session map |
| `./bin/agent-maintain preflight` | Validation chooser + safety contract paths |
| `./bin/agent-maintain closeout` | Finish-gate reminders + SAFETY-REPORT template pointer |

## Worktrees

Defaults (override with flags):

- Branch: `cursor/<slug>`
- Path: `.worktrees/<slug>` (gitignored)
- Base: `origin/main` (must already exist locally — script **never** fetches)
- Mode: plan-only unless `--apply`

```bash
./bin/agent-worktree --name fp-example          # print plan + cd path
./bin/agent-worktree --name fp-example --apply  # create branch + worktree
cd "$(./bin/agent-worktree --name fp-example --apply | sed -n 's/^worktree|cd|//p')"
```

Safety: never fetch, delete, reuse, or overwrite existing branches/paths.

## When to run

| Situation | Command |
| --- | --- |
| Non-trivial task start / cold session | `./bin/agent-maintain preflight` |
| Unclear entry docs | `./bin/agent-maintain session` |
| Before claiming non-trivial work done | `./bin/agent-maintain closeout` |
| Isolated slice off `main` | `./bin/agent-worktree --name <slug> [--apply]` |

## Related

- Validation chooser: [`../agents_quick_reference.md`](../agents_quick_reference.md)
- Safety contracts: [`agent_safety_contracts.md`](agent_safety_contracts.md)
- SAFETY-REPORT template: [`safety-report-template.md`](safety-report-template.md)
- Finish gate: [`legibility_and_finish_gate.md`](legibility_and_finish_gate.md)
- Harness scorecard: [`../ai/harness-scorecard.md`](../ai/harness-scorecard.md)
- Task router: [`../../CODEMAP.md`](../../CODEMAP.md)
