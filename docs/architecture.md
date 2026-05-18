# Architecture

Use Clean Architecture when a feature grows beyond a simple view.

```text
Presentation -> Domain <- Data
```

## Goals

- Keep business rules independent from SwiftUI, SwiftData, URLSession, and app lifecycle.
- Keep UI state predictable with Observation-first feature models and explicit actions.
- Make persistence and networking replaceable in tests.
- Add structure only when it reduces real complexity.

## Feature Shape

```text
Features/<FeatureName>/
  Presentation/
  Domain/
  Data/
```

For very small features, files may stay flat until complexity justifies folders.
Do not scaffold unused layers.

## Composition

The app entry point wires dependencies. Views receive feature models or factories.
Domain protocols sit closer to use cases than infrastructure.

## Decision Rule

- One simple SwiftUI screen: direct view + local SwiftData can be acceptable **only**
  outside `Features/` (legacy flat layout). Migrate before adding rules or side effects.
- Screen with rules, side effects, network, or sync: use `Features/<Name>/` layers and
  an `@Observable` feature model + use case + repository protocol.
- Shared behavior across features: extract to shared domain/service only after second real use.

## Automated enforcement

`./bin/lint.sh` runs [`../tool/check_layer_boundaries.sh`](../tool/check_layer_boundaries.sh).

When code lives under `superDemoApp/Features/<Name>/`:

| Layer | Forbidden imports |
| --- | --- |
| `Domain/` | SwiftUI, SwiftData, UIKit, AppKit, URLSession, Combine |
| `Presentation/` | SwiftData, URLSession |
| `Data/` | SwiftUI, UIKit, AppKit |

Rules:

- No `.swift` files directly under `Features/<Name>/` (use layer folders).
- Empty layer folders log a warning.

See [`layers.md`](layers.md), [`module-structure.md`](module-structure.md).

## Reference implementation

Copy `superDemoApp/Features/Items/` when scaffolding a new feature: Domain use cases,
Data repository + SwiftData model, Presentation `@Observable` feature model + SwiftUI view.

## Production Readiness Dashboard

`Features/ProductionReadiness/` is the senior-level reference slice:

- Domain owns dashboard entities, scoring rules, repository protocol, and display errors.
- Data owns deterministic sample data plus the remote API-health adapter backed by
  `Shared/Networking`.
- Presentation owns SwiftUI state, conditional visual modifiers, preview states, and the
  UIKit showcase entry.
- UIKit interop stays intentionally bounded: collection performance and custom transitions
  are iOS-only, while the universal SwiftUI shell still builds on Mac.

Architecture trade-off: this repo uses clear boundaries where behavior needs tests, but it
does not claim one architecture is always best. Simple screens can stay simple; production
flows need predictable ownership, controlled dependencies, and explicit failure paths.
Composition lives in `superDemoApp/App/`.
