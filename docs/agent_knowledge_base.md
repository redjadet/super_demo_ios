# Agent Knowledge Base

Use this file for agent workflow. Use task-specific docs for implementation
details.

## Core Beliefs

| Belief | Repo rule |
| --- | --- |
| Context beats instructions. | Read current files, current diff, and owning docs before broad edits. |
| AI output = draft. | Review generated code before accepting it. |
| Project facts beat generic iOS tips. | Check `xcodebuild -list`, project files, and local source before assuming setup. |
| Closed loop. | Plan, execute, verify, report proof. |
| Codebase = memory. | Durable conclusions belong in docs, tests, scripts, or plans. |
| Tools beat prompts. | Prefer Xcode/build/test output over model memory. |
| Missing capability beats retry. | Repeated failure needs a small doc/test/script/check, not another prompt. |
| Enforce invariants, not taste. | Automate boundaries; keep local implementation freedom. |
| Fast feedback is a product constraint. | Use previews, mocks, tests, and platform proof to shorten manual loops. |
| Harness beats model choice. | Protect context, memory, orchestration, and recovery. |

## AI Productivity Traps

AI can be slower when it produces almost-correct code: polished surface, subtle
repo mismatch. SwiftUI and Xcode amplify mismatch cost through state ownership,
platform settings, generated project files, and build-signing constraints.

Repo guardrails:

- Treat AI output as draft; prefer smallest coherent change inside existing
  seams: SwiftUI/Observation, feature layers, composition roots, repo scripts.
- Stop re-prompt loops. If two cycles are almost right, switch to evidence:
  read owning code/docs, implement manually, add missing fixture/test/script.
- Patch exact failing lines instead of regenerating whole files/views.
- Run narrowest honest validation early; see
  [Validation Routing](engineering/validation_routing_fast_vs_full.md).
- Architecture consistency beats local correctness. Code that works in isolation
  but violates feature layers or platform support is net loss.
- Start from feature/domain boundary, dependency graph, and contracts. Avoid
  screen-centric rewrites, giant feature models, hidden dependencies, and
  cross-feature leakage.
- Add abstractions only when they remove repeated behavior or hide an external
  dependency. Do not add indirection for style.

## Progressive Disclosure

1. [`../AGENTS.md`](../AGENTS.md)
2. This file
3. [`apple-development-practices.md`](apple-development-practices.md)
4. [`../DESIGN.md`](../DESIGN.md), [`design_system.md`](design_system.md), and
   [`universal-apple-platforms.md`](universal-apple-platforms.md) when touching UI
5. [`architecture.md`](architecture.md) and [`layers.md`](layers.md) when touching `Features/`
6. [`agent_project_context.md`](agent_project_context.md)
7. [`ai_code_review_protocol.md`](ai_code_review_protocol.md)
8. [`development-feedback-loop.md`](development-feedback-loop.md)
9. [`agents_quick_reference.md`](agents_quick_reference.md)
10. task docs from [`README.md`](README.md)
11. targeted source and tests

## Agent loop

Plan once → execute end-to-end → verify → report proof. Ask only blockers:
credentials/tooling, ambiguity below ~95% confidence, user-owned choice.

Non-trivial work: local `tasks/codex/todo.md` (gitignored), context ladder below, one
observe/revise loop.

## Execution Contract

- Define Goal / Context / Boundaries / Verification before non-trivial work.
- Use [Adaptive Execution](agent_kb/adaptive_execution.md) for effort scaling,
  search budget, ambiguity handling, and stop rules.
- Keep write set small and reversible.
- Prefer feature slices that can be built and tested.
- Use existing app target and scheme unless task proves otherwise.
- Treat empty/truncated tool output as missing proof.
- Before report: self-check request, changed files, validation, blockers, residual risk.

## iOS Agent Finish Gate

Detailed finish/report rules:
[Legibility And Finish Gate](agent_kb/legibility_and_finish_gate.md).

Check every non-trivial iOS change:

- Architecture boundary: Presentation, Domain, Data dependencies point right way;
  `./bin/lint.sh` layer check passes for any `Features/` paths touched.
- Apple-native fit: follow [`apple-development-practices.md`](apple-development-practices.md).
- Concurrency/style: MainActor isolation, strict-concurrency fixes, 4-space Swift,
  `./bin/verify-swift.sh`, and [`agent_swift_guards.md`](agent_swift_guards.md).
- Persistence: SwiftData migration, indexes, uniqueness, history, delete behavior, fixtures.
- Networking: typed request/response, cancellation, retry/idempotency, timeout, offline behavior.
- UI: follow [`../DESIGN.md`](../DESIGN.md); accessibility, Dynamic Type, **light + dark**
  (semantic colors, paired previews — [`design_system.md`](design_system.md#light-and-dark-mode-required-from-day-one)),
  loading/empty/error states, no clipped controls.
- Feedback loop: preview/mock states cover manual setup paths; repeated manual checks become
  tests, scripts, fixtures, or release checklists; see [`development-feedback-loop.md`](development-feedback-loop.md).
- Universal layout: all iPhones, iPads, Mac sizes; shared `AdaptiveNavigationShell`; proof
  via `./bin/ci.sh` iPad + Mac lanes — [`universal-apple-platforms.md`](universal-apple-platforms.md).
- Privacy/security: no secrets; least permission; user data, manifest, entitlement, required-reason API impact checked.
- Tests: fast logic coverage; integration/UI proof; parallel-safe Swift Testing fixtures.
- Universal compile: iPad simulator + macOS builds in `./bin/ci.sh` and GitHub Actions.
- Performance: no avoidable main-thread hangs, body-time heavy work, or broad invalidation.
- Operational clarity: future agent can reproduce proof from repo commands.

## Context Ladder

For feature/refactor/debug:

1. `git status --short`
2. `xcodebuild -list -project superDemoApp.xcodeproj`
3. owning docs in `docs/`
4. `rg` for current symbols and patterns
5. targeted source/test reads
6. focused build/test command

Unknown file or stale-context recovery:
[Memory And File Discovery](agent_kb/memory_and_context_ladder.md).

Tool choice and MCP/connector boundaries:
[Tool Orchestration](agent_kb/tool_orchestration.md).

## Long Session Health

- Treat memory as layers: active facts in context, durable evidence in files,
  rules in instruction docs.
- Compact tool output to decisions, evidence, paths, and blockers.
- Watch circuit-breaker symptoms: repeated contradictions, stale file claims,
  lost goal, invented tool output, or circular repair attempts.
- After two failed repair loops or clear context drift, stop generation, reread
  source files, restate Goal / Context / Boundaries / Verification, then
  continue from verified state.
- If reset was needed because repo guidance was missing, add smallest durable
  capability: doc pointer, script, test, fixture, skill, or automation rule.

## Durable Learning

If a verified lesson will matter again, put it in one of:

- `docs/changes/`
- `docs/plans/`
- `docs/audits/`
- local `tasks/codex/todo.md` (gitignored)
- owning implementation doc under `docs/`
- [`agent_preferences.md`](agent_preferences.md) and
  [`agent_project_context.md`](agent_project_context.md) — not
  [`../AGENTS.md`](../AGENTS.md) (map-only; no learned-section growth)

Cursor team skills are pinned in [`../skills-lock.json`](../skills-lock.json); restore
with `npx skills experimental_install -y`. Do not duplicate skill content in `docs/`.

Do not leave reusable conclusions only in chat.
