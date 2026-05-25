# AI Code Review Protocol

Use before accepting AI-written or heavily AI-shaped changes.

## Review Order

1. Request fit: does diff solve the asked problem only?
2. Apple-native fit: use [`apple-development-practices.md`](apple-development-practices.md) before adding dependency or custom platform behavior.
3. Architecture: any boundary leak between Presentation, Domain, Data?
4. Concurrency/performance: MainActor, cancellation, actor safety, `Sendable`,
   strict-concurrency warnings, no unjustified detached tasks or main-thread hangs.
5. Persistence: SwiftData schema, relationship/delete behavior, indexes, uniqueness, history, migration, fixture impact.
6. UI/universal: accessibility, Dynamic Type, light/dark previews, loading/empty/error states, iPhone/iPad/Mac behavior, appropriate Liquid Glass.
7. Errors/diagnostics: typed failures, user-safe messages, `Logger` privacy, signposts when useful.
8. Tests: behavior assertions, edge cases, regression proof, parallel-safe fixtures.
9. Security/privacy: no secrets, over-broad permissions, sensitive logs, or unreviewed privacy manifest / required-reason API impact.
10. System integration: App Intents expose stable, user-meaningful actions/entities and match current Apple availability.
11. Maintainability: minimal dependency additions, naming clarity, no unused scaffolding.

## AI Smell Matrix

| Smell | Risk | Fix |
| --- | --- | --- |
| View owns business rules | hard to test, duplicated behavior | move to use case or domain service |
| Concrete service in feature model | brittle tests, hidden global state | inject protocol |
| Unstructured `Task {}` | cancellation/race bugs | tie task to lifecycle or explicit owner |
| New `ObservableObject` in iOS 17+ feature | legacy data flow, noisy invalidation | use `@Observable` + `@State`; keep `ObservableObject` for legacy/iOS 16 |
| Fixed iPhone-only layout | clipped iPad/Mac UI | adaptive containers and responsive proof |
| Main-thread blocking I/O | jank | async API or background actor |
| Suppressed concurrency warning | race or invalid isolation hidden | fix ownership, actor boundary, or `Sendable` first |
| Raw string routes | broken deep links | typed route enum/path model |
| `try?` around important work | silent data loss | typed error and explicit handling |
| `print` logs | noisy, privacy risk | OSLog with privacy annotations |
| SwiftData model edit without migration note | store breakage | migration plan and focused test |
| Missing SwiftData index/unique invariant | slow or duplicate data | add `#Index`, uniqueness, or repository invariant |
| Shared file/store/static in Swift Testing | parallel flake | isolate fixture or serialize suite |
| Privacy manifest ignored after API/dependency change | App Store rejection risk | review `PrivacyInfo.xcprivacy` / required-reason APIs |
| Sensitive interpolation in logs | privacy leak | mark values private/sensitive with `Logger` |
| Liquid Glass on content cards | hierarchy noise, legibility risk | reserve for controls/navigation layers |
| Third-party package for platform feature | supply-chain and API drift | use Apple API or document tradeoff |
| App Intent mirrors unstable UI | broken system shortcuts | expose stable domain action only |

## Acceptance Gate

Accept only when:

- diff is understandable,
- proof command passed or blocker is explicit,
- edge/failure paths were considered,
- future agent can reproduce validation from docs/commands.
