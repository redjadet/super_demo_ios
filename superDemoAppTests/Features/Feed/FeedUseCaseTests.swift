//
//  FeedUseCaseTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@MainActor
private final class FeedRepositorySpy: FeedRepository {
    var posts: [FeedPost] = []
    var isStale = false
    var fetchCount = 0

    func fetchPosts() async throws -> FeedLoadResult {
        self.fetchCount += 1
        await Task.yield()
        return FeedLoadResult(posts: self.posts, isStale: self.isStale)
    }
}

@Suite("Feed use cases")
struct FeedUseCaseTests {
    @Test
    @MainActor
    func refreshFeedReturnsRepositoryPosts() async throws {
        let repository = FeedRepositorySpy()
        repository.posts = [
            FeedPost(id: 1, userID: 2, title: "T", body: "B"),
        ]

        let result = try await RefreshFeedUseCase(repository: repository)()

        #expect(result.posts == repository.posts)
        #expect(result.isStale == false)
        #expect(repository.fetchCount == 1)
    }

    @Test
    @MainActor
    func refreshFeedReturnsEmptyArray() async throws {
        let repository = FeedRepositorySpy()
        repository.posts = []

        let result = try await RefreshFeedUseCase(repository: repository)()

        #expect(result.posts.isEmpty)
        #expect(repository.fetchCount == 1)
    }
}
