# AI Agent Playbook

## Start

1. Read [`../AGENTS.md`](../AGENTS.md).
2. Check `git status --short`.
3. Read [`apple-development-practices.md`](apple-development-practices.md).
4. Read task-relevant docs.
5. Inspect current source with `rg`.
6. Define validation before editing (chooser in [`agents_quick_reference.md`](agents_quick_reference.md)).

## During Work

- Patch smallest coherent slice.
- Keep architecture boundaries visible.
- Prefer compileable checkpoints.
- Use app-visible proof for UI changes when possible.
- Do not overwrite user changes.
- Do not invent package APIs; verify in project or official docs.
- Prefer Apple-native APIs; document tradeoff before adding dependencies.

## iOS-Specific Checks

- SwiftUI body has no heavy side effects.
- UI is universal: compact iPhone, iPad split/regular, and Mac window sizes.
- Feature models are `@Observable` and `@MainActor` when driving UI.
- Async tasks handle cancellation and stale results.
- SwiftData context stays out of Domain.
- Views have accessibility labels/traits for custom controls.
- Dynamic Type and dark mode do not break layout.
- App Intents expose only stable, user-meaningful actions/entities.

## Report

Final response includes:

- changed files,
- validation command and result,
- blocker if any,
- residual risk if validation was partial.
