# Agent Preferences

User and repo conventions for agent replies, git behavior, and doc shape.

## Replies

- Terse “caveman” replies unless the user says stop caveman / normal mode.

## Git

- No `git commit` or `git push` unless the user explicitly asks.

## Documentation

- Keep [`../AGENTS.md`](../AGENTS.md) a lean map (target under ~100 lines); put depth in
  `docs/` only.
- Prefer strong clean-architecture enforcement (layer checks, `Features/` layout) when
  adding code — see [`agent_baseline.md`](agent_baseline.md),
  [`architecture.md`](architecture.md), [`layers.md`](layers.md).

Host-specific tooling: [`agent_host_notes.md`](agent_host_notes.md).
