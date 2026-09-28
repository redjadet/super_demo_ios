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
    private let snapshotPublisher: any FeedWidgetSnapshotPublishing

    /// - Parameters:
    ///   - cacheTTL: Max age for offline fallback. `nil` keeps cache forever (prior behavior).
    ///   - snapshotPublisher: Publishes App Group widget snapshot after cache updates.
    ///     Defaults to no-op (unit tests / in-memory demos stay isolated from live App Group).
    ///     Optional avoids MainActor default-arg evaluation under
    ///     `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`.
    init(
        remote: any FeedRepository,
        context: ModelContext,
        cacheTTL: TimeInterval? = CachingFeedRepository.defaultCacheTTL,
        signposter: OSSignposter = AppPerformanceSignposts.feed,
        snapshotPublisher: (any FeedWidgetSnapshotPublishing)? = nil,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.remote = remote
        self.context = context
        self.cacheTTL = cacheTTL
        self.now = now
        self.signposter = signposter
        self.snapshotPublisher = snapshotPublisher ?? NoOpFeedWidgetSnapshotPublisher()
    }

    func fetchPosts() async throws -> FeedLoadResult {
        let signpostID = self.signposter.makeSignpostID()
        let interval = self.signposter.beginInterval("fetchPosts", id: signpostID)
        defer { self.signposter.endInterval("fetchPosts", interval) }

        do {
            let result = try await self.remote.fetchPosts()
            // Cancel / supersede after remote returns must not commit cache or widget.
            try Task.checkCancellation()
            try self.replaceCache(with: result.posts)
            self.publishSnapshot(
                posts: result.posts,
                isStale: false,
                writtenAt: self.now()
            )
            self.signposter.emitEvent("remoteSuccess", id: signpostID)
            return FeedLoadResult(posts: result.posts, isStale: false)
        } catch is CancellationError {
            self.signposter.emitEvent("cancelled", id: signpostID)
            throw CancellationError()
        } catch let urlError as URLError where urlError.code == .cancelled {
            self.signposter.emitEvent("cancelled", id: signpostID)
            throw CancellationError()
        } catch {
            if Task.isCancelled {
                self.signposter.emitEvent("cancelled", id: signpostID)
                throw CancellationError()
            }
            let cached = try self.loadValidCachedPosts()
            if cached.isEmpty {
                // Drop prior App Group snapshot so widget / host-bridge match OI cache miss.
                self.snapshotPublisher.clearPublishedSnapshot()
                self.signposter.emitEvent("cacheMiss", id: signpostID)
                throw error
            }
            // Keep snapshot TTL aligned with SwiftData `cachedAt`, not wall-clock now.
            let writtenAt = cached.map(\.cachedAt).max() ?? self.now()
            self.publishSnapshot(
                posts: cached.map(\.post),
                isStale: true,
                writtenAt: writtenAt
            )
            self.signposter.emitEvent("cacheFallback", id: signpostID)
            return FeedLoadResult(posts: cached.map(\.post), isStale: true)
        }
    }

    private func publishSnapshot(posts: [FeedPost], isStale: Bool, writtenAt: Date) {
        let titles = posts.prefix(5).map { post in
            FeedWidgetSnapshot.FeedWidgetSnapshotTitle(id: post.id, title: post.title)
        }
        let snapshot = FeedWidgetSnapshot(
            writtenAt: writtenAt,
            cacheTTLSeconds: self.cacheTTL,
            isStale: isStale,
            titles: Array(titles),
            postCount: posts.count
        )
        self.snapshotPublisher.publish(snapshot)
    }

    private func replaceCache(with posts: [FeedPost]) throws {
        let timestamp = self.now()
        let descriptor = FetchDescriptor<CachedFeedPost>()
        let existing = try self.context.fetch(descriptor)
        // uniquingKeysWith: corrupt duplicate postIDs must not trap the process.
        let rowsByID = Dictionary(existing.map { ($0.postID, $0) }) { first, _ in first }
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

    /// Valid rows for offline fallback. Mixed-age caches filter per-row by TTL;
    /// migrated / missing `cachedAt` (`distantPast`) are treated as expired.
    private func loadValidCachedPosts() throws -> [(post: FeedPost, cachedAt: Date)] {
        var descriptor = FetchDescriptor<CachedFeedPost>()
        descriptor.sortBy = [SortDescriptor(\.postID)]
        let rows = try self.context.fetch(descriptor)
        guard rows.isEmpty == false else { return [] }

        let mapped = rows.map { row in
            (post: row.toDomain, cachedAt: row.effectiveCachedAt)
        }

        guard let cacheTTL else {
            return mapped
        }

        let cutoff = self.now().addingTimeInterval(-cacheTTL)
        return mapped.filter { $0.cachedAt >= cutoff }
    }
}
