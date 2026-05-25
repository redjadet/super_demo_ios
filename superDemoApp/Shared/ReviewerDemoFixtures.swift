//
//  ReviewerDemoFixtures.swift
//  superDemoApp
//

import Foundation
import SwiftData

enum ReviewerDemoFixtures {
    static let sampleItems: [ItemEntity] = [
        ItemEntity(
            id: UUID(uuid: (
                0x01,
                0xD5,
                0x3A,
                0x3F,
                0x9F,
                0x54,
                0x47,
                0x24,
                0x88,
                0xEA,
                0x8E,
                0x40,
                0xC5,
                0x36,
                0x90,
                0x71
            )),
            timestamp: Date(timeIntervalSince1970: 1_779_177_600)
        ),
        ItemEntity(
            id: UUID(uuid: (
                0x48,
                0x39,
                0xF6,
                0xF4,
                0x57,
                0x06,
                0x4F,
                0x7D,
                0xB8,
                0x22,
                0x89,
                0x84,
                0xD1,
                0xBF,
                0x09,
                0x62
            )),
            timestamp: Date(timeIntervalSince1970: 1_779_264_000)
        ),
    ]

    @MainActor
    static func seedItemsIfNeeded(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<Item>()
        guard try context.fetchCount(descriptor) == 0 else {
            return
        }

        for sample in self.sampleItems {
            context.insert(Item(timestamp: sample.timestamp, id: sample.id))
        }
        try context.save()
    }
}
