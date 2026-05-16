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
        for row in existing {
            self.context.delete(row)
        }
        for post in posts {
            self.context.insert(CachedFeedPost(post: post))
        }
        try self.context.save()
    }

    private func loadCachedPosts() throws -> [FeedPost] {
        var descriptor = FetchDescriptor<CachedFeedPost>()
        descriptor.sortBy = [SortDescriptor(\.postID)]
        return try self.context.fetch(descriptor).map(\.toDomain)
    }
}
