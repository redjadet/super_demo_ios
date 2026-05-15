# Agent Baseline (non-negotiables)

Apply on every change unless the user overrides for a scoped task.

- Smallest reversible diff; every changed line traces to the request or required validation/doc update.
- UI stays SwiftUI-first; no UIKit bridge unless native SwiftUI cannot meet the need.
- UI/design work follows [`../DESIGN.md`](../DESIGN.md) and [`design_system.md`](design_system.md).
- UI responsive on **all iPhones, iPads, and Macs** — follow
  [`universal-apple-platforms.md`](universal-apple-platforms.md) and the
  [`design_system.md`](design_system.md) consistency contract; reuse `Shared/Presentation/`.
- Apple-native first: SwiftUI, Observation, SwiftData, Swift Concurrency, Swift Testing, App Intents when appropriate.
- Domain has no SwiftUI, SwiftData, URLSession, or platform UI dependencies.
- Data owns persistence/network DTO mapping; repositories hide storage and transport.
- Async work uses Swift Concurrency; isolate mutable shared state with `@MainActor` or actors.
- SwiftData model changes need migration thinking, preview fixture update, and focused persistence tests.
- New user-facing flows need accessibility, Dynamic Type, **light and dark from day one**
  (semantic colors + light/dark `#Preview`), and critical UI tests when workflows matter.
- Repeated failure → add repo capability (script, test, doc), not a longer prompt.
- Layered features under `Features/<Name>/` must pass
  [`../tool/check_layer_boundaries.sh`](../tool/check_layer_boundaries.sh) (runs in `./bin/lint.sh`).

See also: [`architecture.md`](architecture.md), [`layers.md`](layers.md),
[`apple-development-practices.md`](apple-development-practices.md),
[`agent_knowledge_base.md`](agent_knowledge_base.md) (finish gate).
