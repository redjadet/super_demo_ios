# Senior Quality Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement
> this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Raise the app to hybrid senior quality — product-grade Dashboard/Items/Feed, polished engineering demos, shared load/navigation infra, no
meta theater.

**Architecture:** Thin `@MainActor` `AsyncLoadController` for cancel/restore; `@Observable` `AppNavigationStore` for Intent + URL routing; trim
Production Readiness snapshot/UI to ops framing; evolve Items into local notes; extract Feed detail; rename `@main` type; tighten diagnostics.

**Tech Stack:** SwiftUI, Observation, SwiftData, App Intents, Swift Testing, XCUITest, Xcode MCP tools (`XcodeWrite`, `BuildProject`, `RunSomeTests`).

**Spec:** `docs/superpowers/specs/2026-09-15-senior-quality-pass-design.md`

## Global Constraints

- Preserve UI test accessibility IDs: `productionReadinessDashboard`, `productionRisksLink`, `uikitShowcaseLink`, `addItem`, `addItemEmpty`,

  `refreshFeed`, `feedList`, `dashboardTab`, `itemsTab`, `feedTab`.

- Domain layer: no SwiftUI / SwiftData / UIKit / Combine imports.
- Presentation layer: no SwiftData / URLSession imports.
- Prefer Xcode MCP (`XcodeWrite`, `XcodeUpdate`, `BuildProject`, `RunSomeTests`) over raw `xcodebuild` when possible.
- Do not rename the Xcode target `superDemoApp`.
- No NotificationCenter Intent handoff after Task 2.
- Commit after each task with focused message.

## File Structure (create / modify)

| Path | Role |
| --- | --- |
| `Shared/Presentation/AsyncLoadController.swift` | Cancelable load session |
| `superDemoAppTests/Shared/Presentation/AsyncLoadControllerTests.swift` | Unit tests |
| `App/AppNavigation.swift` | Safe URLs + `AppNavigationStore` |
| `App/AppIntents/AppIntentNavigationRouter.swift` | Call store, drop NC |
| `App/AppRootView.swift` | Bind store; drop `onReceive` |
| `Features/*/Presentation/*FeatureModel.swift` | Use controller; diag polish |
| `Features/ProductionReadiness/Domain/ProductionReadinessModels.swift` | Drop dead fields |
| `Features/ProductionReadiness/Data/SampleProductionReadinessRepository.swift` | Ops copy; drop token/AI makers |
| `Features/ProductionReadiness/Presentation/ProductionReadinessView.swift` | Release health UI |
| `Features/Items/Domain/*` + Data + Presentation | Notes model + update + detail |
| `Features/Feed/Presentation/FeedPostDetailView.swift` | Dedicated detail |
| `Features/Feed/Presentation/FeedView.swift` | Use detail; a11y fix |
| `superDemoAppApp.swift` | Rename `@main` to `SuperDemoApp` |
| Matching `*Tests.swift` / UI tests as needed | Update as contracts change |

---

### Task 1: AsyncLoadController + feature model refactor

**Files:**

- Create: `superDemoApp/superDemoApp/Shared/Presentation/AsyncLoadController.swift`
- Create: `superDemoApp/superDemoAppTests/Shared/Presentation/AsyncLoadControllerTests.swift`
- Modify: `Features/Feed/Presentation/FeedFeatureModel.swift`
- Modify: `Features/Items/Presentation/ItemsFeatureModel.swift`
- Modify: `Features/ProductionReadiness/Presentation/ProductionReadinessFeatureModel.swift`

**Interfaces:**

- Produces: `@MainActor final class AsyncLoadController` with `start`, `startAndWait`, `cancel`
- Consumes: none (foundation only)

- [ ] **Step 1: Write failing controller tests**

```swift
import Foundation
import Testing
@testable import superDemoApp

@Suite("Async load controller")
@MainActor
struct AsyncLoadControllerTests {
    @Test
    func cancelRestoresPriorStateWhenLoading() async {
        enum State: Equatable { case idle, loading, done }
        var state: State = .idle
        let controller = AsyncLoadController()

        controller.start(
            currentState: state,
            isContent: { _ in false },
            applyLoading: { state = .loading },
            restore: { previous in state = previous }
        ) {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            state = .done
        }

        await Task.yield()
        #expect(state == .loading)
        controller.cancel()
        #expect(state == .idle)
    }

    @Test
    func startAndWaitCompletesOperation() async {
        enum State: Equatable { case loading, done }
        var state: State = .loading
        let controller = AsyncLoadController()

        await controller.startAndWait(
            currentState: state,
            isContent: { _ in false },
            applyLoading: { state = .loading },
            restore: { _ in }
        ) {
            await Task.yield()
            state = .done
        }

        #expect(state == .done)
    }
}
```

- [ ] **Step 2: Run tests — expect FAIL (type missing)**

Run via Xcode MCP `RunSomeTests` with identifier matching `AsyncLoadControllerTests`, or:

```bash
xcodebuild test -scheme superDemoApp -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:superDemoAppTests/AsyncLoadControllerTests
```

Expected: compile failure — `AsyncLoadController` not found.

- [ ] **Step 3: Implement controller**

```swift
import Foundation

@MainActor
final class AsyncLoadController {
    private var task: Task<Void, Never>?
    private var stateBeforeLoad: Any?

    func start<State>(
        currentState: State,
        isContent: (State) -> Bool,
        applyLoading: () -> Void,
        restore: (State) -> Void,
        operation: @escaping @MainActor () async -> Void
    ) {
        self.task?.cancel()
        self.stateBeforeLoad = currentState
        if !isContent(currentState) {
            applyLoading()
        }
        self.task = Task { [weak self] in
            await operation()
            guard let self, !Task.isCancelled else { return }
            if self.task != nil {
                self.stateBeforeLoad = nil
            }
        }
    }

    func startAndWait<State>(
        currentState: State,
        isContent: (State) -> Bool,
        applyLoading: () -> Void,
        restore: (State) -> Void,
        operation: @escaping @MainActor () async -> Void
    ) async {
        self.task?.cancel()
        self.stateBeforeLoad = currentState
        if !isContent(currentState) {
            applyLoading()
        }
        let operationTask = Task { [weak self] in
            await operation()
            _ = self
        }
        self.task = operationTask
        await operationTask.value
        if self.task == operationTask {
            self.task = nil
            self.stateBeforeLoad = nil
        }
    }

    func cancel<State>(
        currentState: State,
        isLoading: (State) -> Bool,
        restore: (State) -> Void
    ) {
        self.task?.cancel()
        self.task = nil
        if isLoading(currentState), let previous = self.stateBeforeLoad as? State {
            restore(previous)
        }
        self.stateBeforeLoad = nil
    }
}
```

Refine API during implementation so Feed/Items/ProductionReadiness can call it without `Any` boxing if a cleaner typed design fits (e.g. store
`stateBeforeLoad` inside each model and only use controller for `Task` lifecycle). **Preferred final shape if `Any` feels fragile:**

```swift
@MainActor
final class AsyncLoadController {
    private var task: Task<Void, Never>?

    func run(_ body: @escaping @MainActor () async -> Void) {
        self.task?.cancel()
        self.task = Task { await body() }
    }

    func runAndWait(_ body: @escaping @MainActor () async -> Void) async {
        self.task?.cancel()
        let operation = Task { await body() }
        self.task = operation
        await operation.value
        if self.task == operation { self.task = nil }
    }

    func cancel() {
        self.task?.cancel()
        self.task = nil
    }

    var isRunning: Bool { self.task != nil }
}
```

Keep **stateBeforeLoad / showLoading / restore** in each feature model (already there). Controller only owns Task cancel identity. Update tests to
match this thinner API (cancel mid-flight; startAndWait completes). This matches YAGNI and still removes the triple `Task` boilerplate.

- [ ] **Step 4: Refactor three feature models to use `AsyncLoadController`**

Replace `refreshTask` property with `private let loadController = AsyncLoadController()` (or owned instance). Keep `stateBeforeRefresh`,
`showLoadingStateIfNeeded`, `restorePriorStateAfterCancelledRefresh` in each model.

Example Feed:

```swift
func refresh() {
    self.stateBeforeRefresh = self.state
    self.showLoadingStateIfNeeded()
    self.loadController.run { [weak self] in
        guard let self else { return }
        await self.performRefresh()
    }
}

func refreshAndWait() async {
    self.stateBeforeRefresh = self.state
    self.showLoadingStateIfNeeded()
    await self.loadController.runAndWait { [weak self] in
        guard let self else { return }
        await self.performRefresh()
    }
}

func cancelRefresh() {
    self.loadController.cancel()
    self.restorePriorStateAfterCancelledRefresh()
}
```

Mirror for Items and ProductionReadiness.

- [ ] **Step 5: Run controller + existing feature model tests — expect PASS**

```text
RunSomeTests: AsyncLoadControllerTests, FeedFeatureModelTests, ItemsFeatureModelTests, ProductionReadinessTests
```

- [ ] **Step 6: Commit**

```bash
git add superDemoApp/superDemoApp/Shared/Presentation/AsyncLoadController.swift \
  superDemoApp/superDemoAppTests/Shared/Presentation/AsyncLoadControllerTests.swift \
  superDemoApp/superDemoApp/Features/Feed/Presentation/FeedFeatureModel.swift \
  superDemoApp/superDemoApp/Features/Items/Presentation/ItemsFeatureModel.swift \
  superDemoApp/superDemoApp/Features/ProductionReadiness/Presentation/ProductionReadinessFeatureModel.swift
git commit -m "$(cat <<'EOF'
Extract AsyncLoadController for shared feature refresh cancellation.

EOF
)"
```

---

### Task 2: AppNavigationStore — drop NotificationCenter Intent path

**Files:**

- Modify: `App/AppNavigation.swift`
- Modify: `App/AppIntents/AppIntentNavigationRouter.swift`
- Modify: `App/AppRootView.swift`
- Modify: `superDemoAppTests/Shared/AppIntentNavigationTests.swift`
- Modify: `superDemoAppTests/Shared/AppNavigationTests.swift` (if needed)

**Interfaces:**

- Produces: `@MainActor @Observable final class AppNavigationStore` with `state`, `handle(url:)`, `apply(_:)`, `resetForTesting()`
- Consumes: `AppNavigationState`, `AppDeepLink`

- [ ] **Step 1: Rewrite Intent navigation tests to assert store mutation**

Replace `urlPosted` / NotificationCenter observer with:

```swift
@Test
@MainActor
func openFeedIntentAppliesFeedOnNavigationStore() async throws {
    let store = AppNavigationStore()
    AppNavigationStore.testingOverride = store
    defer { AppNavigationStore.testingOverride = nil }

    store.state.selection = .dashboard
    _ = try await OpenFeedIntent().perform()

    #expect(store.state.selection == .feed)
}
```

Same pattern for Items and Production Risks (expect `.items` / dashboard + `[.productionRisks]`).

- [ ] **Step 2: Run Intent tests — expect FAIL**

Expected: `AppNavigationStore` / `testingOverride` missing.

- [ ] **Step 3: Implement store + router + root**

In `AppNavigation.swift` (or new `AppNavigationStore.swift` next to it):

```swift
@MainActor
@Observable
final class AppNavigationStore {
    static let shared = AppNavigationStore()
    static var testingOverride: AppNavigationStore?

    static var current: AppNavigationStore {
        testingOverride ?? shared
    }

    var state = AppNavigationState()

    func handle(url: URL) {
        self.state.handle(url: url)
    }

    func apply(_ deepLink: AppDeepLink) {
        self.state.apply(deepLink)
    }

    func resetForTesting() {
        self.state = AppNavigationState()
    }
}
```

`AppIntentNavigationRouter`:

```swift
enum AppIntentNavigationRouter {
    @MainActor
    static func open(_ deepLink: AppDeepLink) {
        AppNavigationStore.current.apply(deepLink)
    }
}
```

Delete `Notification.Name.appIntentNavigation` and `urlUserInfoKey`.

`AppRootView`:

```swift
@State private var navigation = AppNavigationStore.shared

// TabView(selection: $navigation.state.selection) ...
// path: $navigation.state.dashboardPath
// onOpenURL / onContinueUserActivity → navigation.handle(url:)
// REMOVE .onReceive(NotificationCenter...)
```

Because `AppNavigationState` is a struct inside an `@Observable` class, ensure bindings work (`$navigation.state.selection`). If Observation does not
project nested bindings cleanly, store `selection` / `dashboardPath` as direct properties on `AppNavigationStore` instead of nesting the struct —
prefer whatever compiles and keeps tests green.

- [ ] **Step 4: Run AppIntentNavigationTests + AppNavigationTests + BuildProject — expect PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "$(cat <<'EOF'
Route App Intents through AppNavigationStore instead of notifications.

EOF
)"
```

---

### Task 3: Safe deep-link URLs + rename `@main`

**Files:**

- Modify: `App/AppNavigation.swift` (`customSchemeURL`)
- Modify: `superDemoApp/superDemoAppApp.swift`
- Modify: `superDemoAppTests/Shared/AppNavigationTests.swift` / Intent round-trip tests (still must pass)

- [ ] **Step 1: Replace force-unwrapped URLs**

```swift
extension AppDeepLink {
    var customSchemeURL: URL {
        switch self {
        case .dashboard:
            Self.dashboardURL
        case .productionRisks:
            Self.productionRisksURL
        case .items:
            Self.itemsURL
        case .feed:
            Self.feedURL
        }
    }

    private static let dashboardURL = URL(string: "superdemo://dashboard")!
    // Keep static lets: evaluated once; add unit test that all are non-nil via round-trip.
    // Better: build via URLComponents without force unwrap:
}
```

Preferred non-force approach:

```swift
private static func customURL(host: String, path: String = "") -> URL {
    var components = URLComponents()
    components.scheme = "superdemo"
    components.host = host
    if !path.isEmpty {
        components.path = path.hasPrefix("/") ? path : "/" + path
    }
    guard let url = components.url else {
        preconditionFailure("Invalid deep link components for host \(host)")
    }
    return url
}
```

Use `preconditionFailure` only for programmer error on static known hosts — never `URL(string:)!` in computed property body called at runtime from
many sites without tests. Round-trip tests already cover all cases.

- [ ] **Step 2: Rename `@main`**

```swift
@main
struct SuperDemoApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(AppModelContainer.shared)
    }
}
```

File may stay `superDemoAppApp.swift` (no mandatory rename).

- [ ] **Step 3: BuildProject + navigation tests — expect PASS**

- [ ] **Step 4: Commit**

```bash
git commit -m "$(cat <<'EOF'
Rename app entry type and build deep-link URLs without string force-unwraps.

EOF
)"
```

---

### Task 4: Dashboard reframing + snapshot trim

**Files:**

- Modify: `Features/ProductionReadiness/Domain/ProductionReadinessModels.swift`
- Modify: `Features/ProductionReadiness/Data/SampleProductionReadinessRepository.swift`
- Modify: `Features/ProductionReadiness/Presentation/ProductionReadinessView.swift`
- Modify: `Features/ProductionReadiness/Presentation/ProductionReadinessFeatureModel.swift` (inject score use case)
- Modify: `superDemoAppTests/Features/ProductionReadiness/ProductionReadinessTests.swift`
- Modify: `CompositeProductionReadinessRepositoryTests.swift` if it constructs snapshots with removed fields
- Grep for `designTokens` / `aiFeedbackNotes` / `DesignTokenSample` / `Senior iOS` and clear all call sites

- [ ] **Step 1: Update domain model**

Remove `DesignTokenSample`, `designTokens`, `aiFeedbackNotes` from snapshot:

```swift
nonisolated struct ProductionReadinessSnapshot: Equatable {
    let modules: [FeatureModule]
    let apiHealth: [APIHealthCheck]
    let checklist: [ReleaseChecklistItem]
    let risks: [ProductionRisk]
}
```

Update `ProductionReadinessTests.scoreReflectsModulesRisksAndChecklist` initializer accordingly (drop trailing empty arrays). Score must remain `66`
for same inputs.

- [ ] **Step 2: Sample repository ops copy**

- Delete `makeDesignTokens` / `makeAIFeedbackNotes`.
- Rewrite hero-facing module summaries to ops language (no “architecture brag”).
- Keep checklist id `observability` and OSLogCrashMonitor claim (tests assert it).

- [ ] **Step 3: View changes**

- `ReadinessHero`: title `"Release health"` (not `"Senior iOS Demo"`); keep score badge; shorten summary to product ops one-liner; drop redraw-note

  brag or reword neutrally.

- Remove Design Consistency + AI Feedback Loop sections.
- Keep Feature Modules, API Health, Release Checklist.
- Section **"Engineering demos"** containing:

  - Production Risks link (`productionRisksLink`)
  - UIKit Showcase link (`uikitShowcaseLink`)

- Keep `productionReadinessDashboard` on the List.

Inject score use case:

```swift
init(
    loadSnapshot: LoadProductionReadinessSnapshotUseCase,
    scoreSnapshot: ScoreProductionReadinessUseCase = ScoreProductionReadinessUseCase()
) {
    self.loadSnapshot = loadSnapshot
    self.scoreSnapshot = scoreSnapshot
}
```

- [ ] **Step 4: Run ProductionReadinessTests + BuildProject — expect PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "$(cat <<'EOF'
Reframe production readiness dashboard as release health and drop meta sections.

EOF
)"
```

---

### Task 5: Items → local notes (domain + data)

**Files:**

- Modify: `Features/Items/Domain/ItemEntity.swift`
- Modify: `Features/Items/Domain/ItemRepository.swift`
- Modify: `Features/Items/Domain/AddItemUseCase.swift`
- Create: `Features/Items/Domain/UpdateItemUseCase.swift`
- Modify: `Features/Items/Data/Item.swift`
- Modify: `Features/Items/Data/SwiftDataItemRepository.swift`
- Modify: `superDemoAppTests/Features/Items/ItemsUseCaseTests.swift`
- Modify: `superDemoAppTests/Features/Items/SwiftDataItemRepositoryTests.swift`

**Interfaces:**

- Produces: `ItemEntity(id:title:note:timestamp:)`, `updateItem(_:)` on repository, `UpdateItemUseCase`

- [ ] **Step 1: Failing use case / repository tests for title+note+update**

```swift
@Test
@MainActor
func addItemCreatesDefaultTitledNote() throws {
    // repository spy / in-memory SwiftData
    let item = try AddItemUseCase(repository: repository)()
    #expect(item.title == "New note")
    #expect(item.note.isEmpty)
}

@Test
@MainActor
func updateItemPersistsTitleAndNote() throws {
    var item = try AddItemUseCase(repository: repository)()
    item.title = "Ship checklist"
    item.note = "Verify deep links"
    try UpdateItemUseCase(repository: repository)(item)
    let loaded = try LoadItemsUseCase(repository: repository)()
    #expect(loaded.first?.title == "Ship checklist")
    #expect(loaded.first?.note == "Verify deep links")
}
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement domain + data**

```swift
struct ItemEntity: Equatable, Identifiable {
    let id: UUID
    var title: String
    var note: String
    let timestamp: Date
}

@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var title: String
    var note: String
    var timestamp: Date

    init(
        timestamp: Date,
        title: String = "New note",
        note: String = "",
        id: UUID = UUID()
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.timestamp = timestamp
    }
}

// Repository
func addItem(timestamp: Date) throws -> ItemEntity // creates default title/note
func updateItem(_ item: ItemEntity) throws
```

Schema drift: existing recovery in `AppModelContainer` will recreate store if lightweight migration fails — acceptable per spec; document in commit
body if needed.

- [ ] **Step 4: Run Items use case + SwiftData tests — expect PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "$(cat <<'EOF'
Evolve Items into local notes with title, body, and update use case.

EOF
)"
```

---

### Task 6: Items presentation (list + detail)

**Files:**

- Modify: `Features/Items/Presentation/ItemsFeatureModel.swift`
- Modify: `Features/Items/Presentation/ItemsView.swift`
- Create: `Features/Items/Presentation/ItemDetailView.swift`
- Modify: `App/ItemsComposition.swift` (wire UpdateItemUseCase)
- Modify: `superDemoAppTests/Features/Items/ItemsFeatureModelTests.swift`
- Previews in ItemsView

- [ ] **Step 1: Extend feature model**

```swift
private let updateItem: UpdateItemUseCase

func updateItemNow(_ item: ItemEntity) async {
    do {
        try self.updateItem(item)
        await self.refreshAndWait()
    } catch {
        self.recordFailure(name: "items-update", error: error)
        self.state = .failed(DisplayError(error))
    }
}
```

Use `ErrorDiagnostics.reason(for:)` helper from Task 7 if already landed; otherwise temporary `error.localizedDescription` and polish in Task 7.

- [ ] **Step 2: List + detail UI**

List row:

```swift
VStack(alignment: .leading, spacing: 4) {
    Text(item.title).font(.headline)
    Text(item.timestamp, format: .dateTime.month().day().hour().minute())
        .font(.subheadline)
        .foregroundStyle(.secondary)
}
```

`ItemDetailView`: `@State` title/note bound to fields; `.onDisappear` or toolbar Save calling `model.updateItemNow`. Keep NavigationLink from list.

Preserve `addItem` / `addItemEmpty` identifiers.

- [ ] **Step 3: Fix all test spies implementing `ItemRepository`**

Every spy needs `updateItem` + `ItemEntity` title/note in initializers.

- [ ] **Step 4: Run ItemsFeatureModelTests + BuildProject — expect PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "$(cat <<'EOF'
Add editable item note detail and wire update through the feature model.

EOF
)"
```

---

### Task 7: Feed detail + a11y + diagnostics polish

**Files:**

- Create: `Features/Feed/Presentation/FeedPostDetailView.swift`
- Modify: `Features/Feed/Presentation/FeedView.swift`
- Create (optional): `Shared/Diagnostics/ErrorDiagnostics.swift`
- Modify: Feed/Items feature models to use shared reason formatter
- Modify: `ProductionReadinessFeatureModel` if not already injecting score (done in Task 4)

- [ ] **Step 1: Extract detail view**

```swift
struct FeedPostDetailView: View {
    let post: FeedPost

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(post.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(post.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Post")
        .iosInlineNavigationBarTitle()
        .accessibilityIdentifier("feedPostDetail-\(post.id)")
    }
}
```

List row: single `.accessibilityElement(children: .combine)` + one `.accessibilityLabel` — remove duplicate on `NavigationLink`.

- [ ] **Step 2: Diagnostics helper**

```swift
enum ErrorDiagnostics {
    static func reason(for error: Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.isEmpty {
            return description
        }
        return String(describing: type(of: error))
    }
}
```

Replace `String(describing: error)` in Feed/Items feature models (and optionally AppModelContainer — out of scope unless touched).

- [ ] **Step 3: Build + FeedFeatureModelTests — expect PASS**

- [ ] **Step 4: Commit**

```bash
git commit -m "$(cat <<'EOF'
Extract feed post detail view and stabilize error diagnostic reasons.

EOF
)"
```

---

### Task 8: Docs sync + full verification

**Files:**

- Modify if claims false: `docs/architecture.md`, `docs/portfolio.md` (remove “Senior iOS Demo” / AI feedback marketing if present)
- Update spec status line to Implemented (optional)

- [ ] **Step 1: Grep residual amateur strings**

```bash
rg -n "Senior iOS Demo|AI Feedback|aiFeedbackNotes|designTokens|appIntentNavigation|superDemoAppApp|String\\(describing: error\\)" \
  superDemoApp docs
```

Expected: no production UI hits; tests/docs only if intentional.

- [ ] **Step 2: Run lint + unit tests**

```bash
./bin/lint.sh
# Xcode: RunAllTests for unit target, or BuildProject + RunSomeTests suites touched
```

- [ ] **Step 3: Smoke UI tests locally (critical paths)**

```text
testDashboardShowsProductionRisks
testUIKitShowcaseCollectionIsReachable
testLaunchShowsAddItemControl
testDeepLinkOpensFeedTab
testFeedTabIsReachable
```

If Engineering demos section changes scroll position, ensure `scrollToElement` still finds `uikitShowcaseLink`.

- [ ] **Step 4: Commit docs / leftover fixes**

```bash
git commit -m "$(cat <<'EOF'
Align docs with release-health framing after senior quality pass.

EOF
)"
```

---

## Self-Review (plan vs spec)

| Spec section | Task |
| --- | --- |
| A Shared async load controller | Task 1 |
| B Navigation store / no NC | Task 2 |
| Deep-link URL safety | Task 3 |
| F App entry rename | Task 3 |
| C Dashboard reframing + trim | Task 4 |
| D Items notes | Tasks 5–6 |
| E Feed polish | Task 7 |
| G Diagnostics + score DI | Tasks 4 + 7 |
| Testing / gates | Each task + Task 8 |

No TBD placeholders. Nested bindings risk called out in Task 2 with fallback. Thinner `AsyncLoadController` preferred to avoid `Any` boxing while
still deleting Task boilerplate.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-09-15-senior-quality-pass.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks  
2. **Inline Execution** — execute tasks in this session with checkpoints  

Which approach?
