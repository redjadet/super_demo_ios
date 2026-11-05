# 2026-11-05 — ADR retrieval + conflict protocol for agents

## What

- [`docs/adr/README.md`](../adr/README.md): agent/reviewer section (load scoped
  ADRs, flag conflicts, ask human; supersede process; format adds options +
  revisit).
- [`docs/ai/context_loading.md`](../ai/context_loading.md): ADR triggers for
  layers, offline/sync, vendor/CI claims.
- [`docs/ai/ai_failure_risks.md`](../ai/ai_failure_risks.md): `RISK-ADR-OVERTURN`.
- [`docs/ai_code_review_protocol.md`](../ai_code_review_protocol.md): ADR fit
  in architecture review step.
- [`AGENTS.md`](../../AGENTS.md) task map → `docs/adr/README.md`.
- [`docs/using-agents-here.md`](../using-agents-here.md): human judgment bullet.

## Why

Existing ADRs (0001–0005) and scripts already record **why** for layering,
offline posture, deferred crash vendor, Sonar skip, and CI honesty. Agents can
still pass tests while overturning that reasoning when ADRs are not in the
generation/review path (see Kokane, *AI Coding Assistant Fixed the Code but
Broke the Architecture Decision*, Level Up Coding, 2026-10-19). This closes the
harness gap without new ADR bureaucracy or app refactors.

## Proof

- `./bin/lint-markdown.sh` (docs-only)
