# ADR 0001 — Feature layering (Presentation / Domain / Data)

- **Status:** Accepted
- **Date:** 2026-09-25
- **Owners:** [`../layers.md`](../layers.md), [`../architecture.md`](../architecture.md),
  [`../feature-template.md`](../feature-template.md)

## Context

Portfolio reviewers and agents need a single, enforceable rule for where UI,
business rules, and persistence/network live. Without an explicit decision,
features drift toward “god” view models and Domain imports of SwiftUI/SwiftData.

## Decision

Adopt **three-layer features** under `superDemoApp/Features/<Name>/`:

| Layer | Owns | Must not own |
| --- | --- | --- |
| Presentation | SwiftUI, observation models, screen state, navigation intents | Persistence, URL/JSON, business invariants |
| Domain | Entities, use cases, repository protocols, pure validation | SwiftUI, SwiftData, UIKit, URLSession types |
| Data | SwiftData models, DTOs, mappers, API clients, repository impls | UI / product navigation |

Enforce with [`../../tool/check_layer_boundaries.sh`](../../tool/check_layer_boundaries.sh),
[`../../tool/check_feature_folder_contract.sh`](../../tool/check_feature_folder_contract.sh),
and [`../../tool/check_feature_import_leaks.sh`](../../tool/check_feature_import_leaks.sh)
(via `./bin/lint.sh`). Shared cross-feature code lives in `Shared/` or `App/`
composition roots — not feature↔feature imports. See [`../modularity.md`](../modularity.md).

## Consequences

- New layered features must ship Presentation / Domain / Data folders when marked
  layered (`tool/config/layered_features.txt` + feature template).
- Lint failure on illegal imports is a merge blocker, not a style suggestion.
- Cross-feature reuse goes through Domain protocols + App composition, not
  direct Feature A → Feature B imports.
