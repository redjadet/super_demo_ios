# Using agents here (for humans)

Short guide for people directing AI agents in this repo. Agent loop detail stays
in [`agent_knowledge_base.md`](agent_knowledge_base.md) and
[`ai/context_loading.md`](ai/context_loading.md). This page is the **human**
entry: which mode to use, what to load, how to judge output.

Themes adapted (not quoted) from Rahul Gite’s Level Up Coding take
([Sep 28](https://medium.com/@rahul.gite11/what-googles-new-sdlc-paper-got-right-about-ai-assisted-software-development))
on Google’s
[The New SDLC With Vibe Coding](https://www.kaggle.com/whitepaper-the-new-SDLC-with-vibe-coding)
(see also [Osmani notes](https://addyosmani.com/blog/new-sdlc-vibe-coding/)).

## Stakes decide the mode

Same models can sit anywhere on a spectrum. **Stakes** choose the mode—not
enthusiasm for agents.

| Mode | When it fits here | Repo expectation |
| --- | --- | --- |
| **Vibe** | Throwaway exploration, throwaway spike, local note | Do not merge without climbing gates; treat output as disposable |
| **Structured** | Small, clear change with known owners | Write-set + owning docs + `./bin/checklist-fast` (or targeted proof) |
| **Agentic** | Multi-file feature, architecture, release-sensitive work | Spec/acceptance in the ask → tests/evals → implement → full verification + human review |

Ambiguous stakes → default **structured**, not vibe. Portfolio / CI honesty
rules still apply either way ([`portfolio.md`](portfolio.md)).

## Agent = model + harness

Reliability comes less from “better prompts” than from the **harness** around
the model: rules, tools, sandboxes, orchestration, guardrails, monitoring.

In this repo the harness already includes:

- Lean always-loaded map: [`../AGENTS.md`](../AGENTS.md)
- Progressive docs: [`ai/context_loading.md`](ai/context_loading.md)
- Safety + approvals: [`agent_kb/agent_safety_contracts.md`](agent_kb/agent_safety_contracts.md)
- Validation chooser: [`agents_quick_reference.md`](agents_quick_reference.md)
- Merge proof: [`engineering/checklist_gate.md`](engineering/checklist_gate.md)
- Maturity scorecard (agent tooling, not app quality):
  [`ai/harness-scorecard.md`](ai/harness-scorecard.md)

Debug harness first when agents fail repeatedly (missing owner doc, wrong gate,
empty tool output treated as proof).

## Always-loaded vs on-demand context

| Layer | What | Why |
| --- | --- | --- |
| **Always-loaded** | `AGENTS.md` map (~70 lines), preferences/facts links | Cheap, stable invariants every turn |
| **On-demand** | Feature docs, DESIGN, testing essays, plans | Loaded only when the task triggers them |

Stuffing every essay into always-loaded context **dilutes** signal and burns
tokens. Prefer maps + conditional owners
([`ai/context_loading.md`](ai/context_loading.md)). Humans: put durable rules in
owning `docs/` files, not chat or a fat `AGENTS.md`.

## Conductor vs orchestrator

| Role | You do | Agent does | Good for |
| --- | --- | --- | --- |
| **Conductor** | Steer turn-by-turn in the IDE/chat | Narrow edits you watch | Exploration, unfamiliar files, taste-sensitive UI |
| **Orchestrator** | Hand a goal + boundaries + proof bar; review the result | Plan → edit → run gates → report | Well-specified migrations, test generation, docs honesty |

Moving from conductor → orchestrator is a **skills** shift (clear specs, evals,
spotting confident wrongness)—not only a tooling toggle. Either role: you still
own merge judgment.

## Spec → tests → implementation → verification

For non-trivial work, order the contract before generation:

1. **Spec** — goal, write-set, non-goals, acceptance (even a short bullet list).
2. **Tests / evals** — extend unit/UI/checklist proof so “done” is checkable
   ([`testing.md`](testing.md), [`feature-template.md`](feature-template.md)).
3. **Implementation** — smallest coherent slice inside existing seams.
4. **Verification** — named command from the validation chooser; empty output ≠
   pass ([`engineering/validation_routing_fast_vs_full.md`](engineering/validation_routing_fast_vs_full.md)).

Tracked **intent → spec → plan → REVIEW** templates for multi-file features:
[`ai-sdlc/README.md`](ai-sdlc/README.md). Deterministic gates (scripts/CI, not
vendor hook JSON): [`ai-sdlc/gates.md`](ai-sdlc/gates.md).

Generation is cheap. **Verification, judgment, and direction** are the craft.

## Judgment: the verification bottleneck

Agents often deliver a fast ~80% that looks finished. The last stretch—edge
cases, layer boundaries, platform honesty, release risk—needs human scrutiny.

Review **process**, not only the final diff:

- Did the agent load the right owners and declare a write-set?
- Was proof matched to change type (fast vs full)?
- Are claims reconstructable (~10 min) per SAFETY-REPORT?

Use [`ai_code_review_protocol.md`](ai_code_review_protocol.md). Prefer stopping
re-prompt loops after two near-misses—switch to evidence
([`agent_knowledge_base.md`](agent_knowledge_base.md)).

## Economics (practical)

- **Vibe** is cheap up front and expensive later (token churn, reverse-engineering,
  security cleanup) when the code must live.
- **Agentic** costs more up front (spec, tests, structured context) and less per
  feature when the harness holds.

For this portfolio sample: invest agentic discipline on merge-bound paths;
allow vibe only for disposable spikes you will not ship.

## What this page does not claim

- New product features or tip-pin inventory.
- That industry cost ratios apply as measured facts for this repo.
- That Harness or Engineering scorecards changed because you read this.

## Related

- Agent map: [`../AGENTS.md`](../AGENTS.md)
- AI-native SDLC kit: [`ai-sdlc/README.md`](ai-sdlc/README.md)
- Commands: [`agents_quick_reference.md`](agents_quick_reference.md)
- Feedback loop: [`development-feedback-loop.md`](development-feedback-loop.md)
- Index: [`README.md`](README.md)
