//
//  Item.swift
//  superDemoApp
//

import Foundation
import SwiftData

@Model
final class Item {
    @Attribute(.unique)
    var id: UUID
    var timestamp: Date

    init(timestamp: Date, id: UUID = UUID()) {
        self.id = id
        self.timestamp = timestamp
    }
}

extension Item {
    func toEntity() -> ItemEntity {
        ItemEntity(id: self.id, timestamp: self.timestamp)
    }
}
