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
    var fetchCount = 0

    func fetchPosts() async throws -> [FeedPost] {
        self.fetchCount += 1
        await Task.yield()
        return self.posts
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

        let posts = try await RefreshFeedUseCase(repository: repository)()

        #expect(posts == repository.posts)
        #expect(repository.fetchCount == 1)
    }

    @Test
    @MainActor
    func loadFeedMatchesRefresh() async throws {
        let repository = FeedRepositorySpy()
        repository.posts = []

        let loadPosts = try await LoadFeedUseCase(repository: repository)()
        let refreshPosts = try await RefreshFeedUseCase(repository: repository)()

        #expect(loadPosts == refreshPosts)
        #expect(repository.fetchCount == 2)
    }
}
