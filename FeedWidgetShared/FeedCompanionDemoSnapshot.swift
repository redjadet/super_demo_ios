//
//  FeedCompanionDemoSnapshot.swift
//  FeedWidgetShared
//
//  Seed payloads for watchOS / tvOS companion Simulator demos.
//  Shared so platform integration tests and UI stay in lockstep.
//

import Foundation

nonisolated enum FeedCompanionDemoSnapshot {
    /// Matches `FeedWatchSnapshotView.seedDemo` titles / TTL.
    static func watchSeed(writtenAt: Date = Date()) -> FeedWidgetSnapshot {
        FeedWidgetSnapshot(
            writtenAt: writtenAt,
            cacheTTLSeconds: 15 * 60,
            isStale: false,
            titles: [
                .init(id: 1, title: "Watch demo: Feed snapshot"),
                .init(id: 2, title: "Same DTO as Home Screen widget"),
                .init(id: 3, title: "Local App Group — not phone sync"),
            ]
        )
    }

    /// Matches `FeedTVSnapshotView.seedDemo` titles / TTL.
    static func tvSeed(writtenAt: Date = Date()) -> FeedWidgetSnapshot {
        FeedWidgetSnapshot(
            writtenAt: writtenAt,
            cacheTTLSeconds: 15 * 60,
            isStale: false,
            titles: [
                .init(id: 1, title: "tvOS demo: Feed snapshot"),
                .init(id: 2, title: "Same DTO as Home Screen widget"),
                .init(id: 3, title: "Same honesty contract as watchOS"),
                .init(id: 4, title: "Local App Group — not phone sync"),
            ]
        )
    }
}
