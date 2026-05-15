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

## Progressive Disclosure

1. [`../AGENTS.md`](../AGENTS.md)
2. This file
3. [`apple-development-practices.md`](apple-development-practices.md)
4. [`agent_project_context.md`](agent_project_context.md)
5. [`ai_code_review_protocol.md`](ai_code_review_protocol.md)
6. [`agents_quick_reference.md`](agents_quick_reference.md)
7. task docs from [`README.md`](README.md)
8. targeted source and tests

## Execution Contract

- Define Goal / Context / Boundaries / Verification before non-trivial work.
- Keep write set small and reversible.
- Prefer feature slices that can be built and tested.
- Use existing app target and scheme unless task proves otherwise.
- Treat empty/truncated tool output as missing proof.
- Before report: self-check request, changed files, validation, blockers, residual risk.

## iOS Agent Finish Gate

Check every non-trivial iOS change:

- Architecture boundary: Presentation, Domain, Data dependencies point right way.
- Apple-native fit: SwiftUI, Observation, SwiftData, Swift Concurrency, Swift Testing, App Intents considered before dependencies.
- Concurrency: UI mutations on MainActor; shared mutable state isolated.
- Persistence: SwiftData changes handle migration, uniqueness, delete behavior, and preview/test fixtures.
- Networking: typed request/response, cancellation, retry/idempotency, timeout, offline behavior.
- UI: accessibility, Dynamic Type, dark/light, loading/empty/error states, no clipped controls.
- Universal layout: compact iPhone, iPad split/Stage Manager, and Mac windows.
- Privacy/security: no secrets in repo; least permission; user data minimized.
- Tests: fast unit coverage for logic; integration/UI proof for critical workflows.
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

## Durable Learning

If a verified lesson will matter again, put it in one of:

- `docs/changes/`
- `docs/plans/`
- `docs/audits/`
- local `tasks/codex/todo.md` (gitignored)
- owning implementation doc under `docs/`

Do not leave reusable conclusions only in chat.
