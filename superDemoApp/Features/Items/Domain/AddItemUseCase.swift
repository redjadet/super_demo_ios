//
//  AddItemUseCase.swift
//  superDemoApp
//

import Foundation

struct AddItemUseCase {
    private let repository: ItemRepository

    init(repository: ItemRepository) {
        self.repository = repository
    }

    @MainActor
    func callAsFunction(timestamp: Date = Date()) throws -> ItemEntity {
        try self.repository.addItem(timestamp: timestamp)
    }
}
