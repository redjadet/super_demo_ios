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

- One simple SwiftUI screen: direct view + local SwiftData can be acceptable.
- Screen with rules, side effects, network, or sync: introduce an `@Observable` feature model + use case + repository protocol.
- Shared behavior across features: extract to shared domain/service only after second real use.
