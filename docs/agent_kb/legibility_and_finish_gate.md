# Legibility And Finish Gate

Back: [Agent Knowledge Base](../agent_knowledge_base.md)

See also: [AI Code Review Protocol](../ai_code_review_protocol.md) and
[Validation Routing](../engineering/validation_routing_fast_vs_full.md).

## Agent Legibility

Agents reason over inspectable state.

- Prefer app-visible proof: screenshots, Xcode build/test output, UI tests,
  simulator evidence, logs, fixtures, and focused repo scripts.
- Runtime evidence needs agent-runnable trigger plus stable
  log/metric/trace/fixture signal. Human-only dashboards are not proof.
- Turn unclear goals into inspectable artifacts: acceptance criteria, data-flow
  sketch, fixture, dry-run, focused proof command, or explicit blocker.
- Non-trivial risk needs an acceptance contract before broad execution.
- Spec items must map to deterministic proof: test, fixture, script, lint,
  screenshot, log/metric, or explicit manual blocker. If not evaluable, treat
  it as intent/context, not spec.
- Long or tool-heavy work needs stop rules: retry, fallback, ask, abstain, or
  report.
- Keep state inspectable: tracker, checklist, commands, failures, retries,
  blockers.
- UI/design chain: [DESIGN.md](../../DESIGN.md) ->
  [design_system.md](../design_system.md) ->
  [universal-apple-platforms.md](../universal-apple-platforms.md).
- UI proof covers real workflow first, expected states, light/dark, Dynamic
  Type, and iPhone/iPad/Mac layout stability with no clipped text or incoherent
  overlap.
- Prefer repo-local examples, fixtures, scripts, and generated project settings
  over chat-only claims.
- For runtime work, expose narrow runnable surface first: preview state, sample
  repository, UI smoke path, focused test, or release dry-run.

## Finish Gate

Closeout template: [`safety-report-template.md`](safety-report-template.md).
Reminders: `./bin/agent-maintain closeout`. Host ops:
[`host-maintenance.md`](host-maintenance.md).

Before final report or commit, self-verify:

- Edge cases: empty, malformed, duplicate, concurrent, offline/resume,
  permission-denied, slow/large input.
- Failure paths: error surface, retry/rollback/idempotency, cleanup,
  user-visible state, logs/metrics.
- Readability: names, seams, comments, tests, and docs make next change obvious.
- Operational clarity: run, verify, and debug steps are discoverable from repo
  artifacts.
- Breakage impact: first failure signal, blast radius, detection, and safe
  recovery path.
- Drift: intent, spec, docs, tests, and implementation still match after patch.
