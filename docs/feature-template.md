# Feature Scaffolding Template

Use when feature complexity justifies layers. **Required layout:**

```text
superDemoApp/Features/<FeatureName>/
  Presentation/
  Domain/
  Data/
```

Imports and folders are enforced by [`../tool/check_layer_boundaries.sh`](../tool/check_layer_boundaries.sh)
(via `./bin/lint.sh`). Read [`architecture.md`](architecture.md) and [`layers.md`](layers.md) first.

## Goal

What user outcome does this feature provide?

## Domain

- Entity/value objects:
- Use cases:
- Repository protocols:
- Failure cases:

## Data

- Local persistence:
- Remote API:
- DTO/model mapping:
- Sync/conflict policy:

## Presentation

Read [`../DESIGN.md`](../DESIGN.md), [`design_system.md`](design_system.md), and
[`universal-apple-platforms.md`](universal-apple-platforms.md) first.

- Navigation shell: `AdaptiveNavigationShell` from `Shared/Presentation/` (see Items).
- Screens:
- Feature model state:
- User events:
- Loading/empty/error states:
- Responsive layouts: compact iPhone, iPad regular/split, Mac resizable — `./bin/ci.sh`
- **Light and dark:** semantic colors only; asset catalog Any+Dark for custom roles;
  `#Preview` per screen in light and dark (see design_system.md)
- Platform differences: only when split vs stack is insufficient; no device-model checks
- Accessibility:

## Verification

- Unit tests:
- Integration tests:
- UI tests:
- iPhone/iPad/Mac layout proof:
- Manual proof:
- Build command:

## Stop Criteria

- Smallest useful workflow works.
- Failure path visible.
- Tests/proof recorded.
- Docs updated if pattern changed.
