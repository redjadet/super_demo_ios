//
//  ItemsFeatureModelTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@MainActor
private final class ItemsFeatureModelRepositorySpy: ItemRepository {
    var storedItems: [ItemEntity] = []
    var fetchError: Error?

    func fetchItems() throws -> [ItemEntity] {
        if let fetchError {
            throw fetchError
        }
        return self.storedItems
    }

    func addItem(timestamp: Date) throws -> ItemEntity {
        let item = ItemEntity(id: UUID(), title: "New note", note: "", timestamp: timestamp)
        self.storedItems.append(item)
        return item
    }

    func updateItem(_ item: ItemEntity) throws {
        guard let index = self.storedItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        self.storedItems[index] = item
    }

    func deleteItems(ids: [UUID]) throws {
        self.storedItems.removeAll { ids.contains($0.id) }
    }
}

private final class ItemsRecordingDiagnostics: ReleaseDiagnosticsReporting, @unchecked Sendable {
    private let lock = NSLock()
    private var recordedFailedNames: [String] = []

    var failedNames: [String] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.recordedFailedNames
    }

    func releaseCheckPassed(_: ReleaseDiagnosticCheck) {}

    func releaseCheckFailed(_ check: ReleaseDiagnosticCheck, reason _: String) {
        self.lock.lock()
        self.recordedFailedNames.append(check.name)
        self.lock.unlock()
    }

    func deviceOnlyFailure(_: DeviceOnlyFailure) {}
}

@Suite("Items feature model")
struct ItemsFeatureModelTests {
    @Test
    @MainActor
    func refreshKeepsExistingContentVisible() async {
        let repository = ItemsFeatureModelRepositorySpy()
        repository.storedItems = [ItemEntity(id: UUID(), title: "Note", note: "", timestamp: Date())]
        let model = ItemsFeatureModel(
            loadItems: LoadItemsUseCase(repository: repository),
            addItem: AddItemUseCase(repository: repository),
            deleteItems: DeleteItemsUseCase(repository: repository)
        )
        await model.refreshAndWait()

        repository.storedItems.append(ItemEntity(id: UUID(), title: "Note", note: "", timestamp: Date()))
        model.refresh()
        await Task.yield()

        if case .loading = model.state {
            Issue.record("Expected existing content to remain visible during refresh")
        }

        model.cancelRefresh()
    }

    @Test
    @MainActor
    func cancelRefreshRestoresPriorLoadingState() async {
        let repository = ItemsFeatureModelRepositorySpy()
        let model = ItemsFeatureModel(
            loadItems: LoadItemsUseCase(repository: repository),
            addItem: AddItemUseCase(repository: repository),
            deleteItems: DeleteItemsUseCase(repository: repository)
        )

        #expect(model.state == .loading)

        model.refresh()
        await Task.yield()
        model.cancelRefresh()

        #expect(model.state == .loading)
    }

    @Test
    @MainActor
    func refreshAndWaitShowsContent() async {
        let repository = ItemsFeatureModelRepositorySpy()
        repository.storedItems = [ItemEntity(id: UUID(), title: "Note", note: "", timestamp: Date())]
        let model = ItemsFeatureModel(
            loadItems: LoadItemsUseCase(repository: repository),
            addItem: AddItemUseCase(repository: repository),
            deleteItems: DeleteItemsUseCase(repository: repository)
        )

        await model.refreshAndWait()

        if case let .content(items) = model.state {
            #expect(items.count == 1)
        } else {
            Issue.record("Expected content state")
        }
    }

    @Test
    @MainActor
    func refreshFailureRecordsDiagnostic() async {
        let repository = ItemsFeatureModelRepositorySpy()
        repository.fetchError = NSError(domain: "test", code: 1)
        let diagnostics = ItemsRecordingDiagnostics()
        let model = ItemsFeatureModel(
            loadItems: LoadItemsUseCase(repository: repository),
            addItem: AddItemUseCase(repository: repository),
            deleteItems: DeleteItemsUseCase(repository: repository),
            diagnostics: diagnostics
        )

        await model.refreshAndWait()

        if case .failed = model.state {
            #expect(diagnostics.failedNames == ["items-refresh"])
        } else {
            Issue.record("Expected failed state")
        }
    }
}
