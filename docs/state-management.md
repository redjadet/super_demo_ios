# State Management

Default for modern iOS: native SwiftUI Observation. It is built into SwiftUI,
keeps dependency tracking fine-grained, avoids extra packages, and is easy for
AI agents because ownership rules are explicit.

```text
View action -> @Observable FeatureModel -> UseCase -> Repository -> state update
```

## Decision Matrix

| Scenario | Use |
| --- | --- |
| Local UI value owned by one view | `@State` |
| Child edits parent-owned value | `@Binding` |
| Screen/feature reference state on iOS 17+ | `@Observable` type owned by `@State` |
| Child edits an `@Observable` model property | `@Bindable` |
| Shared app service/configuration | `@Environment(Type.self)` |
| SwiftData query-only list | `@Query` in a thin view, or repository once logic grows |
| iOS 16 or legacy Combine-style state | `ObservableObject` + `@StateObject` / `@ObservedObject` |

Pick ownership first, then wrapper. Do not create a reference model when plain
value state is enough.

## Feature Model Rules

- Use `@Observable` for new screen/feature models when deployment target supports iOS 17+.
- Mark UI-driving feature models `@MainActor`.
- Keep models small: state, user actions, and orchestration only.
- Move business rules into use cases and pure Domain types.
- Inject protocols, clocks, ID generators, and services.
- Model loading, content, empty, and failure states explicitly.
- Keep side effects in action methods, `.task`, or use cases; never in `body`-driven computed values.
- Cancel or ignore stale async work when inputs change.
- Keep SwiftData `ModelContext` out of Domain; prefer repositories once logic grows.

## State Shape

Prefer small enums/structs:

```swift
enum LoadState<Value: Equatable>: Equatable {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(DisplayError)
}
```

Use typed feature state over parallel booleans:

```swift
enum ItemsState: Equatable {
    case loading
    case content([ItemEntity])
    case empty
    case failed(DisplayError)
}
```

## Recommended Pattern

```swift
@MainActor
@Observable
final class ItemsFeatureModel {
    private let loadItems: LoadItemsUseCase
    private(set) var state: ItemsState = .loading

    init(loadItems: LoadItemsUseCase) {
        self.loadItems = loadItems
    }

    func refresh() async {
        state = .loading
        do {
            let items = try await loadItems()
            state = items.isEmpty ? .empty : .content(items)
        } catch {
            state = .failed(DisplayError(error))
        }
    }
}
```

```swift
struct ItemsView: View {
    @State private var model: ItemsFeatureModel

    init(model: ItemsFeatureModel) {
        self._model = State(initialValue: model)
    }

    var body: some View {
        ItemsContent(state: model.state)
            .task { await model.refresh() }
    }
}
```

## SwiftUI Rules

- Views render state; they do not decide business outcomes.
- Views read only the state needed by that view; smaller reads mean fewer updates.
- Use `@State` for view-local UI details and root ownership of `@Observable` models.
- Use `@Bindable` at the edit boundary, not across whole view trees.
- Prefer explicit initializer injection for feature-local models.
- Use `@Environment(Type.self)` for app-wide shared services, not as a default for every dependency.
- Keep previews supplied with deterministic fake data.

## Avoid

- New `ObservableObject` / `@Published` for iOS 17+ features.
- `@EnvironmentObject` as global service locator.
- Multiple booleans for mutually exclusive loading/sheet/navigation states.
- Network, persistence, or expensive work from SwiftUI `body`.
- Feature models that own business rules, JSON, SQL, URL construction, or SwiftData migration details.
- Third-party state libraries unless a documented product need beats built-in Observation.
