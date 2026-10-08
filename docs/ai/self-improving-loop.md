# Self-improving agent loop

Design **learning after each run** as carefully as model choice. This page is the
on-demand owner for that loop. It does **not** replace safety contracts, gates,
or the context ladder — it names how runs compound into reusable guidance.

Human framing: [`../using-agents-here.md`](../using-agents-here.md).  
Workflow / finish: [`../agent_knowledge_base.md`](../agent_knowledge_base.md).  
Gates: [`../ai-sdlc/gates.md`](../ai-sdlc/gates.md).

## Pipeline

```text
planner → tool executor → evaluation → reflection → memory → skill library
```

| Stage | What happens here | Repo surface |
| --- | --- | --- |
| **Planner** | Goal, write-set, owners, proof bar | Ask / `ai-sdlc` intent→plan; context ladder |
| **Tool executor** | Edit + run named commands | `./bin/*`, Xcode/MCP, tests |
| **Evaluation** | Execution results beat self-review | Test/CI/log output; empty ≠ pass |
| **Reflection** | Critic score before ship; revise if weak | Review protocol + finish gate (below) |
| **Memory** | Keep knowledge, not logs | Purpose map below |
| **Skill library** | Promote proven workflows | `ai-sdlc/skills/`, host skills lock, playbooks |

One verifiable behavior per step still applies
([`../ai-sdlc/skills/progressive-prompting.md`](../ai-sdlc/skills/progressive-prompting.md)).

## Reflection (critic before ship)

Before claiming done or opening/merge-ready PR:

1. Score the work against the ask (fit, proof, honesty, residual risk).
2. If composite is **below ~8/10**, revise once (usual) before shipping.
3. High-stakes code (layers, offline/sync, release-sensitive): allow **2–3**
   reflect→revise passes; stop after that and switch to evidence
   ([`../agent_knowledge_base.md`](../agent_knowledge_base.md) traps).
4. An extra LLM critic pass is cheaper than a wrong merge — but **CI/tests win**
   over unaided self-praise.

Use [`../ai_code_review_protocol.md`](../ai_code_review_protocol.md) and
[`../agent_kb/legibility_and_finish_gate.md`](../agent_kb/legibility_and_finish_gate.md)
as the critic checklist; do not invent a parallel scoring product.

## Memory by purpose (this repo — honest)

There is **no** Redis / Postgres / vector store for agent memory in this
portfolio. Memory is files + hosting stores you already have:

| Purpose | Meaning | Where it lives |
| --- | --- | --- |
| **Session** | Active goal, write-set, blockers | Chat context; local `tasks/codex/todo.md` (gitignored); Project Agent Store `notes.md` |
| **Preferences** | Stable user/repo conventions | [`../agent_preferences.md`](../agent_preferences.md); Cursor Project `preferences.md` |
| **Past experiences** | Verified lessons / patterns | Owning `docs/`, `docs/changes/`, `docs/audits/`; Project Store `docs/` plans & e2e |
| **Relationships** | Who/what to load for a topic | [`context_loading.md`](context_loading.md) conditional owners; [`../../CODEMAP.md`](../../CODEMAP.md); skills indexes |

Compiled memory rules:
[`../agent_kb/memory_and_context_ladder.md`](../agent_kb/memory_and_context_ladder.md).

## Learn from real feedback

| Prefer | Over |
| --- | --- |
| Named gate output (`./bin/verify-swift.sh`, checklist, GHA Delivery) | “Looks good” self-review |
| Failed test / CI log → fix → store what worked | Re-prompting the same blind spot |
| Reconstructable SAFETY-REPORT evidence | Chat-only claims |

Promotion path: repeated manual check → test, fixture, script, or owning doc
([`../development-feedback-loop.md`](../development-feedback-loop.md)).

## Skill library, not prompt library

Keep **proven workflows** short and loadable:

- Institutional skills: [`../ai-sdlc/skills/`](../ai-sdlc/skills/README.md)
- Host Apple skills pin: [`../../skills-lock.json`](../../skills-lock.json) +
  [`../agent_host_notes.md`](../agent_host_notes.md)
- Playbooks / gates: incident playbook, validation routing, checklist gate

Do **not** grow a pile of one-off prompts in always-loaded rules. Prefer a skill
or owning doc when the same approach succeeds twice.

## Learn from success too

On green runs, record compact reusable facts when they will matter again:

- Approach that worked (command sequence, owner doc, seam)
- Confidence / stakes mode used (vibe vs structured vs agentic)
- Timing only if useful (e.g. which gate caught the bug)

Put successes in the same durable places as failure lessons — not only in chat.

## What to remember / skip

| Keep | Skip |
| --- | --- |
| Successful workflows and high-confidence fixes | Raw chat transcripts |
| Preferences and recurring conventions | Failed noise / one-off flukes |
| Patterns with owners + proof commands | Duplicates of existing docs |
| Lessons that change the next agent’s first move | Speculative tips without evidence |

When a lesson belongs in two places, pick **one** owner and link.

## After each non-trivial run

1. Evaluation evidence attached (command + result).
2. Critic pass ≥ ~8 or residual risk named.
3. If reusable: update owning doc / change note / preference / skill — not
   `AGENTS.md` essays ([`../agent_preferences.md`](../agent_preferences.md)).
4. Finish via SAFETY-REPORT when required.

## What this page does not claim

- New product features, tip-pin inventory, or scorecard bumps.
- External memory infrastructure beyond files and Cursor Agent Store.
- That reflection replaces tests or human merge judgment.

## Related

- Context ladder: [`context_loading.md`](context_loading.md)
- AI-native SDLC kit: [`../ai-sdlc/README.md`](../ai-sdlc/README.md)
- Harness scorecard: [`harness-scorecard.md`](harness-scorecard.md)
- Index: [`README.md`](README.md)
