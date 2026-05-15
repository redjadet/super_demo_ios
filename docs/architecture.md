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
Composition lives in `superDemoApp/App/`.
