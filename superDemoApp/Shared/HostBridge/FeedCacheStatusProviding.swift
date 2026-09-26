//
//  FeedCacheStatusProviding.swift
//  superDemoApp
//
//  Reads Feed cache honesty for host-bridge `feed.cacheStatus`.
//

import Foundation

nonisolated protocol FeedCacheStatusProviding: Sendable {
    func cacheStatus(now: Date) -> FeedCacheStatusResult
}

/// App Group snapshot-backed status (JP-P0-B). Prefer this over inventing a
/// second repository read path on day-1.
nonisolated struct SnapshotFeedCacheStatusProvider: FeedCacheStatusProviding {
    /// Unit-test override; production leaves this `nil` (live App Group).
    var containerURLOverride: URL?

    init(containerURLOverride: URL? = nil) {
        self.containerURLOverride = containerURLOverride
    }

    func cacheStatus(now: Date = Date()) -> FeedCacheStatusResult {
        switch FeedWidgetSnapshotStore.loadState(
            now: now,
            containerURLOverride: self.containerURLOverride
        ) {
        case .unavailable, .absent, .corrupt:
            return FeedCacheStatusResult(
                postCount: 0,
                isStale: false,
                cacheAgeSeconds: nil,
                source: "unavailable"
            )
        case let .expired(snapshot):
            return Self.map(snapshot: snapshot, now: now, forceStale: true)
        case let .ok(snapshot):
            return Self.map(snapshot: snapshot, now: now, forceStale: snapshot.isStale)
        }
    }

    private static func map(
        snapshot: FeedWidgetSnapshot,
        now: Date,
        forceStale: Bool
    ) -> FeedCacheStatusResult {
        let age = Int(now.timeIntervalSince(snapshot.writtenAt).rounded(.down))
        return FeedCacheStatusResult(
            postCount: snapshot.postCount,
            isStale: forceStale,
            cacheAgeSeconds: max(0, age),
            source: "snapshot"
        )
    }
}
