# 2026-10-06 — AI-native SDLC kit (tool-agnostic)

## Intent

Give Cursor / Codex / other agents a shared **intent → spec → plan → REVIEW**
loop, institutional skills, and a documented map of deterministic gates — without
Claude Code–only files, hooks, or CI.

## Changes

- Added [`../ai-sdlc/`](../ai-sdlc/README.md): README, `gates.md`, templates,
  Feed stale-banner example, skills (security, concurrency, offline/outbox,
  Flutter add-to-app), `features/` live artifact home.
- Cross-links: `AGENTS.md`, `CODEMAP.md`, `llms.txt`, architecture / contributor
  docs, review + commit guidelines, cursor template prove bullet.
- Thin helper: `./bin/agent-verify-done` (prints gate reminder).

## Non-goals

- No `CLAUDE.md`, `.claude/`, Anthropic API keys, or Claude GitHub Actions.
- No edits to open CI (#85) or outbox (#86) workflow/core feature files.
- No product Swift behavior changes.
