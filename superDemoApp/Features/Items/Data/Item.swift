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

extension Item {
    func toEntity() -> ItemEntity {
        ItemEntity(
            id: self.id,
            title: self.title,
            note: self.note,
            timestamp: self.timestamp
        )
    }
}
