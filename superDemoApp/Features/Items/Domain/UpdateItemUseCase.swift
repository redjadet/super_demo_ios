//
//  UpdateItemUseCase.swift
//  superDemoApp
//

import Foundation

struct UpdateItemUseCase {
    private let repository: ItemRepository

    init(repository: ItemRepository) {
        self.repository = repository
    }

    @MainActor
    func callAsFunction(_ item: ItemEntity) throws {
        try self.repository.updateItem(item)
    }
}
