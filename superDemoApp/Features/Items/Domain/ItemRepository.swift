//
//  ItemRepository.swift
//  superDemoApp
//

import Foundation

@MainActor
protocol ItemRepository: AnyObject {
    func fetchItems() throws -> [ItemEntity]
    func addItem(timestamp: Date) throws -> ItemEntity
    func deleteItems(ids: [UUID]) throws
}
