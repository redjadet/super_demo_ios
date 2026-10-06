# AI-native SDLC kit (tool-agnostic)

Translate the **intent → spec → plan → review** loop into tracked Markdown that
**any** coding agent (Cursor, Codex, others) can follow. Humans approve at gates.
This kit does **not** depend on a single vendor’s slash commands, tag system, or
hook JSON.

Human framing (stakes / harness / judgment): [`../using-agents-here.md`](../using-agents-here.md).  
Agent map: [`../../AGENTS.md`](../../AGENTS.md).  
Workflow doctrine: [`../agent_knowledge_base.md`](../agent_knowledge_base.md).

## Loop

```text
intent  →  spec  →  plan  →  implement  →  REVIEW  →  merge gates
  ↑ human approve     ↑ human approve      ↑ human approve
```

| Stage | Artifact | Who approves | Stop if |
| --- | --- | --- | --- |
| Intent | `intent.md` | Human | Goal / non-goals unclear |
| Spec | `spec.md` | Human | Acceptance not checkable |
| Plan | `plan.md` | Human | Write-set or proof bar missing |
| Implement | code + tests | Agent + human spot-check | Diff drifts from plan |
| Review | `REVIEW.md` | Human | Plan/spec not met; gates red |
| Merge | `./bin/checklist` + GHA `checklist` | Human | Any lane fails |

Local-only scratch plans under `docs/plans/` stay gitignored. **Shared** feature
artifacts for multi-agent / PR review live under
[`features/<slug>/`](features/README.md) (this kit).

## Concept map (industry idea → this repo)

| Idea | Repo form | Path |
| --- | --- | --- |
| Agent instruction file | Lean always-loaded map | [`../../AGENTS.md`](../../AGENTS.md) |
| Progressive context | Ladder + conditional owners | [`../ai/context_loading.md`](../ai/context_loading.md) |
| Intent / spec / plan / review | Feature artifact kit | `templates/`, `features/<slug>/` |
| Institutional skills | Short policy skills (any agent) | [`skills/`](skills/README.md) |
| Deterministic hooks | Documented gates (scripts/CI) | [`gates.md`](gates.md) |
| Feedback loops | Proof before done + review vs plan | [`gates.md`](gates.md), [`../ai_code_review_protocol.md`](../ai_code_review_protocol.md) |

## When to use artifacts

| Work | Artifacts |
| --- | --- |
| Docs-only / typo / one-file fix | Optional; prefer write-set in the ask |
| Small structured change | Short `intent` + acceptance in PR body may suffice |
| Multi-file feature, offline/sync, layers, release-sensitive | Full kit under `features/<slug>/` |

## Templates and example

- Blank templates: [`templates/`](templates/)
- Filled Feed / SwiftUI / networking example: [`examples/feed-stale-banner-honesty/`](examples/feed-stale-banner-honesty/)

## Hard bans (this kit)

Do **not** add or reference vendor-only Claude Code files (`CLAUDE.md`,
`.claude/`), Anthropic-only slash commands, Claude Tag, Claude-only hook JSON,
Anthropic API keys, or Claude-specific GitHub Actions. Prefer Codex + Cursor +
shell gates already in `bin/` and `.github/workflows/`.

## Related

- Skills index: [`skills/README.md`](skills/README.md)
- Gates (“hooks”): [`gates.md`](gates.md)
- Feature scaffold: [`../feature-template.md`](../feature-template.md)
- Review protocol: [`../ai_code_review_protocol.md`](../ai_code_review_protocol.md)
- Safety: [`../agent_kb/agent_safety_contracts.md`](../agent_kb/agent_safety_contracts.md)
