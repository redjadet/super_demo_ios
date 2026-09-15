# Memory And File Discovery

Back: [Agent Knowledge Base](../agent_knowledge_base.md)

See also: [Agent Project Context](../agent_project_context.md).

## Memory Compounding

Next session should be smarter without bloating docs.

- Treat source docs, plans, changes, tests, scripts, fixtures, and host trackers
  as compiled memory.
- File reusable conclusions into owning source doc, `docs/changes/`,
  local `docs/plans/` (gitignored), `docs/audits/`, or local
  `tasks/codex/todo.md`.
- Preserve source-of-truth boundaries: code/tests beat summaries; source docs
  beat host templates; user corrections beat inferred rules.
- Do not dump chat transcripts or generic summaries. Add compact, cited,
  actionable facts only.
- No cron/autonomous behavior without explicit user approval.
- Prefer maps, `rg`, Xcode project inspection, and targeted validation over
  separate RAG layers.
- Semantic lint during doc/agent changes: stale plans, duplicate rules,
  source/host-template contradictions, reusable conclusions stranded in chat or
  local trackers.
- Before feature/refactor work, audit related code, tests, docs, plans, known
  bugs, workarounds, deprecated patterns, unusual helpers. Carry only
  high-signal landmines into `Context` or `Boundaries`.

## File Discovery Layers

Use when target file is unknown.

- Map: [AGENTS.md](../../AGENTS.md), [agent_knowledge_base.md](../agent_knowledge_base.md),
  [README.md](../README.md), task docs.
- Project context: [agent_project_context.md](../agent_project_context.md) for
  versions, caveats, platform pins, shipped features, and forbidden patterns.
- Compiled memory: owning docs, `docs/changes/`, local `docs/plans/`
  (gitignored), `docs/audits/`, local tracker. Chat is pointer only; verify
  drift-prone facts.
- Structure: `xcodebuild -list -project superDemoApp.xcodeproj`, `rg --files`,
  and feature folders under `superDemoApp/Features/` and `superDemoApp/Shared/`.
- Raw files: targeted reads for edit/proof; `rg` when ownership is unclear.

When archaeology finds a real landmine, carry it into Context or Boundaries.
Do not turn broad background into prompt bulk.
