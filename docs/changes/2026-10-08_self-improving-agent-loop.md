# Self-improving agent loop docs (2026-10-08)

## Summary

Named the post-run learn/reflect/memory/skill pipeline for agents and humans
directing them. Depth lives in on-demand `docs/ai/`; `AGENTS.md` stays a map.

## Changes

- New owner: [`../ai/self-improving-loop.md`](../ai/self-improving-loop.md)
- Cross-links: KB Durable Learning, memory ladder, using-agents-here,
  context ladder, review/finish gates, ai-sdlc concept map, skills README,
  docs/ai indexes, one AGENTS Task map row
- Honesty: file + Cursor Agent Store memory only; no Redis/Postgres/vector claims

## Validation

- `./bin/lint-markdown.sh`
- `./tool/check_markdown_relative_links.sh`
- `./tool/check_router_doc_paths.sh` (as applicable)

## Non-goals

- Harness/Engineering score bumps, app code, CI workflow edits, tip-pin fluff
