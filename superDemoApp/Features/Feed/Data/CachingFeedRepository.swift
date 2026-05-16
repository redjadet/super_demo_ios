//
//  CachingFeedRepository.swift
//  superDemoApp
//

import Foundation
import SwiftData

@MainActor
final class CachingFeedRepository: FeedRepository {
    private let remote: any FeedRepository
    private let context: ModelContext

    init(remote: any FeedRepository, context: ModelContext) {
        self.remote = remote
        self.context = context
    }

    func fetchPosts() async throws -> [FeedPost] {
        do {
            let posts = try await self.remote.fetchPosts()
            try self.replaceCache(with: posts)
            return posts
        } catch {
            let cached = try self.loadCachedPosts()
            if cached.isEmpty {
                throw error
            }
            return cached
        }
    }

    private func replaceCache(with posts: [FeedPost]) throws {
        let descriptor = FetchDescriptor<CachedFeedPost>()
        let existing = try self.context.fetch(descriptor)
        let rowsByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.postID, $0) })
        let incomingIDs = Set(posts.map(\.id))

        for post in posts {
            if let existingRow = rowsByID[post.id] {
                existingRow.update(with: post)
            } else {
                self.context.insert(CachedFeedPost(post: post))
            }
        }
        for row in existing where !incomingIDs.contains(row.postID) {
            self.context.delete(row)
        }
        if self.context.hasChanges {
            try self.context.save()
        }
    }

    private func loadCachedPosts() throws -> [FeedPost] {
        var descriptor = FetchDescriptor<CachedFeedPost>()
        descriptor.sortBy = [SortDescriptor(\.postID)]
        return try self.context.fetch(descriptor).map(\.toDomain)
    }
}
