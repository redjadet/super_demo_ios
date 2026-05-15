# Dependency Injection

Use explicit dependencies. Avoid service locators and global mutable singletons
unless there is a documented platform reason.

## Defaults

- Inject protocols into use cases and feature models.
- Build concrete services at app composition boundaries.
- Use factory closures for SwiftUI previews and tests.
- Keep dependencies narrow: pass what a type actually needs.

## Example Shape

```swift
import Observation

protocol ItemRepository {
    func items() async throws -> [ItemEntity]
    func addItem(_ item: ItemEntity) async throws
}

@MainActor
@Observable
final class ItemsFeatureModel {
    private let repository: ItemRepository

    init(repository: ItemRepository) {
        self.repository = repository
    }
}
```

## Testability Rule

If a feature model or use case cannot be tested without real network, disk, clock,
or randomness, dependency boundaries are too concrete.
