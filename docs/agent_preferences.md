# Agent Preferences

User and repo conventions for agent replies, git behavior, and doc shape.
Continual-learning and agents must update **this file** and
[`agent_project_context.md`](agent_project_context.md), never
[`../AGENTS.md`](../AGENTS.md). Keep `AGENTS.md` a link-only map (~70 lines)—no
`## Learned …` sections or policy bullets there.

## Replies

- Terse “caveman” replies unless the user says stop caveman / normal mode.

## Git

- No `git commit` or `git push` unless the user explicitly asks.
- Never add Cursor / AI attribution to commits or PRs (no `Co-authored-by: Cursor`,
  no “Made with Cursor”). Keep `~/.cursor/cli-config.json` attribution flags off:
  `attributeCommitsToAgent` and `attributePRsToAgent` = `false`.

## Documentation

- [`../AGENTS.md`](../AGENTS.md) is a **route map only** (~70 lines): links and tables,
  no policy essays. Put depth in `docs/`.
- Public [`../README.md`](../README.md) must not mention Cursor or other IDE-specific
  tooling.
- Prefer strong clean-architecture enforcement (layer checks, `Features/` layout) when
  adding code — see [`agent_baseline.md`](agent_baseline.md),
  [`architecture.md`](architecture.md), [`layers.md`](layers.md).

## Product / UI

- New user-facing capabilities need a normal UI entry point (tabs/navigation), not
  test-only wiring.

## Swift quality (recurring)

- When the same lint/concurrency mistake appears again, extend
  [`agent_swift_guards.md`](agent_swift_guards.md) and lint/format tooling—not only
  one-off file fixes.

## Review and delivery passes

- When the user asks to finish a review or delivery pass, complete cited
  should-fix, nice-to-have, and proposed items—not only blockers.

## Xcode / MCP

- When the user asks to rebuild or clear Xcode warnings/errors, prefer the
  **Xcode tools** MCP (`xcode-tools`) per [`agent_host_notes.md`](agent_host_notes.md).

Host-specific tooling: [`agent_host_notes.md`](agent_host_notes.md).
