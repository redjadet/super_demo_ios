//
//  CachingFeedRepository.swift
//  superDemoApp
//

import Foundation
import os
import SwiftData

@MainActor
final class CachingFeedRepository: FeedRepository {
    /// Default offline-cache lifetime before a remote failure refuses stale rows.
    nonisolated static let defaultCacheTTL: TimeInterval = 15 * 60

    private let remote: any FeedRepository
    private let context: ModelContext
    private let cacheTTL: TimeInterval?
    private let now: @Sendable () -> Date
    private let signposter: OSSignposter

    /// - Parameters:
    ///   - cacheTTL: Max age for offline fallback. `nil` keeps cache forever (prior behavior).
    init(
        remote: any FeedRepository,
        context: ModelContext,
        cacheTTL: TimeInterval? = CachingFeedRepository.defaultCacheTTL,
        signposter: OSSignposter = AppPerformanceSignposts.feed,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.remote = remote
        self.context = context
        self.cacheTTL = cacheTTL
        self.now = now
        self.signposter = signposter
    }

    func fetchPosts() async throws -> FeedLoadResult {
        let signpostID = self.signposter.makeSignpostID()
        let interval = self.signposter.beginInterval("fetchPosts", id: signpostID)
        defer { self.signposter.endInterval("fetchPosts", interval) }

        do {
            let result = try await self.remote.fetchPosts()
            try self.replaceCache(with: result.posts)
            self.signposter.emitEvent("remoteSuccess", id: signpostID)
            return FeedLoadResult(posts: result.posts, isStale: false)
        } catch {
            let cached = try self.loadValidCachedPosts()
            if cached.isEmpty {
                self.signposter.emitEvent("cacheMiss", id: signpostID)
                throw error
            }
            self.signposter.emitEvent("cacheFallback", id: signpostID)
            return FeedLoadResult(posts: cached, isStale: true)
        }
    }

    private func replaceCache(with posts: [FeedPost]) throws {
        let timestamp = self.now()
        let descriptor = FetchDescriptor<CachedFeedPost>()
        let existing = try self.context.fetch(descriptor)
        let rowsByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.postID, $0) })
        let incomingIDs = Set(posts.map(\.id))

        for post in posts {
            if let existingRow = rowsByID[post.id] {
                existingRow.update(with: post, cachedAt: timestamp)
            } else {
                self.context.insert(CachedFeedPost(post: post, cachedAt: timestamp))
            }
        }
        for row in existing where !incomingIDs.contains(row.postID) {
            self.context.delete(row)
        }
        if self.context.hasChanges {
            try self.context.save()
        }
    }

    private func loadValidCachedPosts() throws -> [FeedPost] {
        var descriptor = FetchDescriptor<CachedFeedPost>()
        descriptor.sortBy = [SortDescriptor(\.postID)]
        let rows = try self.context.fetch(descriptor)
        guard rows.isEmpty == false else { return [] }

        if let cacheTTL {
            let cutoff = self.now().addingTimeInterval(-cacheTTL)
            guard let newest = rows.map(\.cachedAt).max(), newest >= cutoff else {
                return []
            }
        }

        return rows.map(\.toDomain)
    }
}
