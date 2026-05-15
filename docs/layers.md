# Layers And Responsibilities

Enforced under `superDemoApp/Features/<Name>/` by
[`../tool/check_layer_boundaries.sh`](../tool/check_layer_boundaries.sh). See
[`architecture.md`](architecture.md).

## Presentation

Owns:

- SwiftUI views
- Observation-first feature models
- user events
- screen state
- formatting for display
- navigation intents

Must not own:

- persistence details
- URL construction
- JSON decoding
- business invariants

## Domain

Owns:

- entities and value objects
- use cases
- repository protocols
- business errors
- pure validation rules

Domain imports `Foundation` only when needed. No SwiftUI, SwiftData, UIKit, or
URLSession-specific types.

## Data

Owns:

- SwiftData models
- DTOs
- mappers
- API clients
- repository implementations
- cache/sync mechanics

Data translates infrastructure failures into domain failures.
