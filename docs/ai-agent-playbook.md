# AI Agent Playbook

Thin router. Ladder: [`ai/context_loading.md`](ai/context_loading.md). Pre-Flight:
[`ai/ai_failure_risks.md`](ai/ai_failure_risks.md) +
[`agent_kb/agent_safety_contracts.md`](agent_kb/agent_safety_contracts.md).

## Start

1. [`../AGENTS.md`](../AGENTS.md) → context ladder.
2. `git status --short`.
3. [`agent_swift_guards.md`](agent_swift_guards.md) before Swift edits.
4. [`apple-development-practices.md`](apple-development-practices.md) for API defaults.
5. [`development-feedback-loop.md`](development-feedback-loop.md) for UI / device /
   release-sensitive work.
6. Define validation (`agents_quick_reference.md`) before editing.

## During Work

- Smallest coherent slice; compileable checkpoints.
- Architecture boundaries visible (`layers.md`).
- App-visible proof for UI when possible; previews/mocks for slow manual paths.
- Do not overwrite user changes; do not invent package APIs.
- Prefer Apple-native APIs; document tradeoff before dependencies.

## iOS-Specific Checks

- SwiftUI `body`: no heavy side effects.
- Universal UI: iPhone / iPad / Mac (`universal-apple-platforms.md`).
- Previews: loading, empty, populated, error, dark.
- Feature models `@Observable` + `@MainActor`; no `Type()` default args on those inits.
- `./bin/format.sh` before `./bin/lint.sh` after Swift edits.
- Async: cancellation + stale-result handling.
- SwiftData out of Domain.
- Accessibility labels/traits for custom controls; Dynamic Type + light/dark.
- App Intents: stable user-meaningful actions only.

## Report

Changed files; exact proof command + result; blocker; residual risk if partial.

## Rule retention

| Rule | Disposition |
| --- | --- |
| Start ladder / git status | Keep (above) + `ai/context_loading.md` |
| Smallest slice / no overwrite / no invented APIs | Keep |
| Apple-native preference | Keep |
| MainActor / no `Type()` defaults | Keep |
| Cancellation / stale results | Keep |
| Previews + light/dark | Keep |
| Accessibility / Dynamic Type | Keep |
| SwiftData out of Domain | Keep |
| Universal layout | Keep → also `RISK-UNIVERSAL-UI` |
| Report shape | Keep → SAFETY-REPORT / finish gate |
| Long progressive list formerly in KB | Moved → `ai/context_loading.md` |
