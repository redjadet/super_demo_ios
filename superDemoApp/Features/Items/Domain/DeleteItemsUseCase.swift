//
//  DeleteItemsUseCase.swift
//  superDemoApp
//

import Foundation

struct DeleteItemsUseCase {
    private let repository: ItemRepository

    init(repository: ItemRepository) {
        self.repository = repository
    }

    @MainActor
    func callAsFunction(ids: [UUID]) throws {
        guard !ids.isEmpty else { return }
        try self.repository.deleteItems(ids: ids)
    }
}
