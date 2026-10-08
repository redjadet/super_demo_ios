# Agent customization layers (Cursor / Codex)

## Context

Translate “mods vs hooks vs skills” guidance into this repo’s Cursor/Codex
harness without Claude-specific files. Hard merge gates already live in `bin/`
and GHA; agent hooks stay convenience-only.

## Change

- Added [`docs/ai/agent-customization-layers.md`](../ai/agent-customization-layers.md)
  (decision ladder, hook limits, secrets posture).
- Repo skills: [`ci-iphone-shards.md`](../ai-sdlc/skills/ci-iphone-shards.md),
  [`docs-change-note.md`](../ai-sdlc/skills/docs-change-note.md).
- Tracked [`tool/cursor-template/.cursorignore`](../../tool/cursor-template/.cursorignore);
  `install-cursor-rules.sh` copies it to the workspace root.
- Cross-links: `AGENTS.md`, context ladder, SDLC kit, gates, host notes.

## Proof

- `python3 ./tool/check_ci_contracts.py` — pass (Linux VM).
- `./bin/lint-markdown.sh` — pass on edited Markdown.
- `./tool/check_common_issues.sh` — pass (includes new template file).
- `.cursorignore` Agent behavior — **not run** (host manual).

## Trade-offs

- Skipped `beforeReadFile` deny hook: Cursor Agent enforcement reported unreliable;
  `.cursorignore` is the supported workaround per Cursor docs/community.
- No duplicate Codex-only skill tree; lockfile `.agents/skills/` unchanged.
