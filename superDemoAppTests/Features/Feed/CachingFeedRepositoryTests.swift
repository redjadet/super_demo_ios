//
//  CachingFeedRepositoryTests.swift
//  superDemoAppTests
//

import Foundation
import SwiftData
import Testing
@testable import superDemoApp

@MainActor
private final class RemoteFeedRepositorySpy: FeedRepository {
    var posts: [FeedPost]
    var error: FeedError?
    private(set) var fetchCount = 0

    init(posts: [FeedPost] = [], error: FeedError? = nil) {
        self.posts = posts
        self.error = error
    }

    func fetchPosts() async throws -> [FeedPost] {
        self.fetchCount += 1
        await Task.yield()
        if let error {
            throw error
        }
        return self.posts
    }
}

@Suite("Caching feed repository")
struct CachingFeedRepositoryTests {
    @Test
    @MainActor
    func fetchPostsPersistsRemotePosts() async throws {
        let context = try Self.makeContext()
        let posts = [
            FeedPost(id: 1, userID: 10, title: "First", body: "Body"),
            FeedPost(id: 2, userID: 20, title: "Second", body: "More"),
        ]
        let remote = RemoteFeedRepositorySpy(posts: posts)
        let repository = CachingFeedRepository(remote: remote, context: context)

        let fetched = try await repository.fetchPosts()

        #expect(fetched == posts)
        #expect(remote.fetchCount == 1)
        #expect(try Self.cachedPosts(in: context) == posts)
    }

    @Test
    @MainActor
    func fetchPostsReturnsCachedPostsWhenRemoteFails() async throws {
        let context = try Self.makeContext()
        let cachedPosts = [
            FeedPost(id: 1, userID: 10, title: "Cached", body: "Offline"),
        ]
        try Self.seed(cachedPosts, in: context)
        let remote = RemoteFeedRepositorySpy(error: .invalidResponse)
        let repository = CachingFeedRepository(remote: remote, context: context)

        let fetched = try await repository.fetchPosts()

        #expect(fetched == cachedPosts)
        #expect(remote.fetchCount == 1)
    }

    @Test
    @MainActor
    func fetchPostsReplacesStaleCacheWithRemotePosts() async throws {
        let context = try Self.makeContext()
        try Self.seed([
            FeedPost(id: 1, userID: 10, title: "Old", body: "Old body"),
            FeedPost(id: 99, userID: 99, title: "Stale", body: "Remove me"),
        ], in: context)
        let remotePosts = [
            FeedPost(id: 1, userID: 11, title: "Updated", body: "Fresh body"),
            FeedPost(id: 2, userID: 20, title: "New", body: "New body"),
        ]
        let remote = RemoteFeedRepositorySpy(posts: remotePosts)
        let repository = CachingFeedRepository(remote: remote, context: context)

        let fetched = try await repository.fetchPosts()

        #expect(fetched == remotePosts)
        #expect(try Self.cachedPosts(in: context) == remotePosts)
    }

    @MainActor
    private static func makeContext() throws -> ModelContext {
        let schema = Schema([CachedFeedPost.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @MainActor
    private static func seed(_ posts: [FeedPost], in context: ModelContext) throws {
        for post in posts {
            context.insert(CachedFeedPost(post: post))
        }
        try context.save()
    }

    @MainActor
    private static func cachedPosts(in context: ModelContext) throws -> [FeedPost] {
        var descriptor = FetchDescriptor<CachedFeedPost>()
        descriptor.sortBy = [SortDescriptor(\.postID)]
        return try context.fetch(descriptor).map(\.toDomain)
    }
}
