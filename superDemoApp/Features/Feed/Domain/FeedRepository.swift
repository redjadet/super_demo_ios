//
//  FeedRepository.swift
//  superDemoApp
//

import Foundation

nonisolated struct FeedLoadResult: Equatable {
    let posts: [FeedPost]
    let isStale: Bool
    /// Newest successful local cache stamp when known (sync observability).
    let lastSyncedAt: Date?

    init(posts: [FeedPost], isStale: Bool = false, lastSyncedAt: Date? = nil) {
        self.posts = posts
        self.isStale = isStale
        self.lastSyncedAt = lastSyncedAt
    }
}

protocol FeedRepository: Sendable {
    func fetchPosts() async throws -> FeedLoadResult
    /// Immediate local serve when a TTL-valid cache exists. Default: no cache.
    /// Does not publish widget snapshots or hit the network.
    func peekCachedPosts() throws -> FeedLoadResult?
}

extension FeedRepository {
    func peekCachedPosts() throws -> FeedLoadResult? {
        nil
    }
}
