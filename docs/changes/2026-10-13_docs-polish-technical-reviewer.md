# Change — docs polish for technical reviewers

**Date:** 2026-10-13

## What

- Tighten README, evidence, portfolio, and architecture-tour prose: drop
  interview-coach phrasing (“talk track”, “trajectory”, “one-liners if asked”).
- Reframe AI assistance: agents handle typing and syntax; the owner keeps
  architecture, intent, edge cases, and acceptance of evidence.
- Correct workspace layout facts in `AGENTS.md` and
  [`agent_project_context.md`](../agent_project_context.md): published git root
  is the repository root; Swift sources live under `superDemoApp/`.
- Light index and linked-doc wording (`docs/README.md`, `CODEMAP.md`,
  performance-lab / incident / failure-map cross-references).
- Clarify the evidence table’s pointer to PR #107 after that PR merged.

## Why

Technical reviewers should meet clear, confident documentation without hype or
ambiguous agent/layout claims.

## Verification

Docs-only: `./bin/lint-markdown.sh` (and related docs checks used by CI’s
docs-only route). No app or test source changes.
