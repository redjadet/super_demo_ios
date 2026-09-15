# Context loading ladder

**Canonical** progressive load order. Other agent docs link here; do not
duplicate this list.

## Ladder

1. [`../../AGENTS.md`](../../AGENTS.md) — repository entry map.
2. Task evidence — targeted code/tests inside the declared write-set.
3. Non-trivial work — [`ai_failure_risks.md`](ai_failure_risks.md) Pre-Flight +
   [`../agent_kb/agent_safety_contracts.md`](../agent_kb/agent_safety_contracts.md).

Skills / MCP: see [`../agent_host_notes.md`](../agent_host_notes.md) and
[`../../skills-lock.json`](../../skills-lock.json). Prefer repo docs over vendor
skill text when they conflict.

## Conditional owners

| Trigger | Load |
| --- | --- |
| Features layers / new feature | [`../architecture.md`](../architecture.md), [`../layers.md`](../layers.md), [`../feature-template.md`](../feature-template.md) |
| SwiftUI / design / light–dark | [`../../DESIGN.md`](../../DESIGN.md), [`../design_system.md`](../design_system.md), [`../universal-apple-platforms.md`](../universal-apple-platforms.md) |
| Swift indent / MainActor / lint | [`../agent_swift_guards.md`](../agent_swift_guards.md); `./bin/verify-swift.sh` |
| SwiftData / offline | [`../offline-first.md`](../offline-first.md) |
| Networking / sync | [`../sync-and-networking.md`](../sync-and-networking.md) |
| App Intents / deep links | [`../navigation.md`](../navigation.md); `App/AppIntents/` |
| Commands / validation choice | [`../agents_quick_reference.md`](../agents_quick_reference.md), [`../engineering/validation_routing_fast_vs_full.md`](../engineering/validation_routing_fast_vs_full.md) |
| Code review | [`../ai_code_review_protocol.md`](../ai_code_review_protocol.md) |
| Host / Cursor / Xcode MCP | [`../agent_host_notes.md`](../agent_host_notes.md), [`../agent_kb/tool_orchestration.md`](../agent_kb/tool_orchestration.md) |
| Harness doctrine | [`../agent_knowledge_base.md`](../agent_knowledge_base.md) |
| Topic unknown | [`../README.md`](../README.md) |

## Avoid loading early

- Entire `Features/<Name>/` trees before the feature's Domain boundary
- Duplicate testing essays — use [`../testing.md`](../testing.md)
- Cursor / agent plan files under `docs/plans/` or `docs/superpowers/plans/`
  (local-only, gitignored) unless you are editing that plan on disk

## Discovery refresh

1. `git status --short`
2. `xcodebuild -list -project superDemoApp.xcodeproj` when project shape unclear
3. Owning docs above
4. Targeted `rg` + source/test reads
5. Narrowest honest validation command
