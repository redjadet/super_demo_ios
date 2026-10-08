//
//  FeedCompanionDemoSnapshot.swift
//  FeedWidgetShared
//
//  Seed payloads for watchOS / tvOS companion Simulator demos.
//  Shared so platform integration tests and UI stay in lockstep.
//

import Foundation

nonisolated enum FeedCompanionDemoSnapshot {
    /// Small-screen sample; shown in memory by the Watch companion.
    static func watchSeed(writtenAt: Date = Date()) -> FeedWidgetSnapshot {
        FeedWidgetSnapshot(
            writtenAt: writtenAt,
            cacheTTLSeconds: 15 * 60,
            isStale: false,
            titles: [
                .init(id: 1, title: "A quiet morning on the Bosphorus"),
                .init(id: 2, title: "A new walking route along the waterfront"),
                .init(id: 3, title: "Small habits that make room for creative work"),
            ]
        )
    }

    /// Living-room sample; shown in memory by the Apple TV companion.
    static func tvSeed(writtenAt: Date = Date()) -> FeedWidgetSnapshot {
        FeedWidgetSnapshot(
            writtenAt: writtenAt,
            cacheTTLSeconds: 15 * 60,
            isStale: false,
            titles: [
                .init(id: 1, title: "A quiet morning on the Bosphorus"),
                .init(id: 2, title: "A new walking route along the waterfront"),
                .init(id: 3, title: "Designing a calmer daily reading routine"),
                .init(id: 4, title: "Small habits that make room for creative work"),
            ]
        )
    }
}
