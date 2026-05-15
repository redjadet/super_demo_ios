//
//  LoadItemsUseCase.swift
//  superDemoApp
//

import Foundation

struct LoadItemsUseCase {
    private let repository: ItemRepository

    init(repository: ItemRepository) {
        self.repository = repository
    }

    @MainActor
    func callAsFunction() throws -> [ItemEntity] {
        try self.repository.fetchItems()
    }
}
