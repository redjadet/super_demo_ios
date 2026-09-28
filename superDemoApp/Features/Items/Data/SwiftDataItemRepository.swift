//
//  SwiftDataItemRepository.swift
//  superDemoApp
//

import Foundation
import SwiftData

enum ItemRepositoryError: Error {
    case itemNotFound(UUID)
}

@MainActor
final class SwiftDataItemRepository: ItemRepository {
    private let context: ModelContext
    private let saveContext: @MainActor (ModelContext) throws -> Void

    init(
        context: ModelContext,
        saveContext: @escaping @MainActor (ModelContext) throws -> Void = { try $0.save() }
    ) {
        self.context = context
        self.saveContext = saveContext
    }

    func fetchItems() throws -> [ItemEntity] {
        let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.timestamp)])
        return try self.context.fetch(descriptor).map { $0.toEntity() }
    }

    func addItem(timestamp: Date) throws -> ItemEntity {
        let record = Item(timestamp: timestamp)
        self.context.insert(record)
        do {
            try self.saveContext(self.context)
            return record.toEntity()
        } catch {
            self.context.rollback()
            throw error
        }
    }

    func updateItem(_ item: ItemEntity) throws {
        let itemID = item.id
        let descriptor = FetchDescriptor<Item>(predicate: #Predicate { $0.id == itemID })
        guard let record = try self.context.fetch(descriptor).first else {
            throw ItemRepositoryError.itemNotFound(item.id)
        }
        let previousTitle = record.title
        let previousNote = record.note
        record.title = item.title
        record.note = item.note
        do {
            try self.saveContext(self.context)
        } catch {
            // Roll back in-memory mutations so a failed save cannot leave
            // pending dirty values that later succeed without the caller knowing.
            record.title = previousTitle
            record.note = previousNote
            self.context.rollback()
            throw error
        }
    }

    func deleteItems(ids: [UUID]) throws {
        let idSet = Set(ids)
        let records = try self.context.fetch(FetchDescriptor<Item>())
            .filter { idSet.contains($0.id) }
        for record in records {
            self.context.delete(record)
        }
        do {
            try self.saveContext(self.context)
        } catch {
            self.context.rollback()
            throw error
        }
    }
}
