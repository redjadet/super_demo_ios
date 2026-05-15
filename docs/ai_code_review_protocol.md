# AI Code Review Protocol

Use before accepting AI-written or heavily AI-shaped changes.

## Review Order

1. Request fit: does diff solve the asked problem only?
2. Apple-native fit: can SwiftUI, Observation, SwiftData, Swift Concurrency, Swift Testing, or App Intents solve this without extra dependency?
3. Architecture: any boundary leak between Presentation, Domain, Data?
4. Concurrency: MainActor isolation, cancellation, actor safety, no detached fire-and-forget unless justified.
5. Persistence: SwiftData schema, relationship, delete, uniqueness, migration, test fixture impact.
6. UI: accessibility, Dynamic Type, **light + dark from day one** (semantic colors, paired
   previews), loading/empty/error states.
7. Universal layout: iPhone, iPad split/Stage Manager, and Mac window behavior.
8. Errors: typed failures, user-safe messages, logs with privacy-safe metadata.
9. Tests: behavior assertions, edge cases, regression proof.
10. Security/privacy: no secrets, no over-broad permissions, no sensitive logs.
11. System integration: App Intents only expose stable, user-meaningful actions/entities.
12. Maintainability: minimal dependency additions, naming clarity, no unused scaffolding.

## AI Smell Matrix

| Smell | Risk | Fix |
| --- | --- | --- |
| View owns business rules | hard to test, duplicated behavior | move to use case or domain service |
| Concrete service in feature model | brittle tests, hidden global state | inject protocol |
| Unstructured `Task {}` | cancellation/race bugs | tie task to lifecycle or explicit owner |
| New `ObservableObject` in iOS 17+ feature | legacy data flow, noisy invalidation | use `@Observable` + `@State`; keep `ObservableObject` for legacy/iOS 16 |
| Fixed iPhone-only layout | clipped iPad/Mac UI | adaptive containers and responsive proof |
| Main-thread blocking I/O | jank | async API or background actor |
| Raw string routes | broken deep links | typed route enum/path model |
| `try?` around important work | silent data loss | typed error and explicit handling |
| `print` logs | noisy, privacy risk | OSLog with privacy annotations |
| SwiftData model edit without migration note | store breakage | migration plan and focused test |
| Third-party package for platform feature | supply-chain and API drift | use Apple API or document tradeoff |
| App Intent mirrors unstable UI | broken system shortcuts | expose stable domain action only |

## Acceptance Gate

Accept only when:

- diff is understandable,
- proof command passed or blocker is explicit,
- edge/failure paths were considered,
- future agent can reproduce validation from docs/commands.
