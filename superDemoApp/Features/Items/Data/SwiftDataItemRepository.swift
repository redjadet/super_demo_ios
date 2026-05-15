//
//  SwiftDataItemRepository.swift
//  superDemoApp
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataItemRepository: ItemRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchItems() throws -> [ItemEntity] {
        let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.timestamp)])
        return try self.context.fetch(descriptor).map { $0.toEntity() }
    }

    func addItem(timestamp: Date) throws -> ItemEntity {
        let record = Item(timestamp: timestamp)
        self.context.insert(record)
        try self.context.save()
        return record.toEntity()
    }

    func deleteItems(ids: [UUID]) throws {
        let idSet = Set(ids)
        let records = try self.context.fetch(FetchDescriptor<Item>())
            .filter { idSet.contains($0.id) }
        for record in records {
            self.context.delete(record)
        }
        try self.context.save()
    }
}
