//
//  FeedFeatureModelTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@MainActor
private final class FeedModelRepositorySpy: FeedRepository {
    var posts: [FeedPost] = []
    var delayNanoseconds: UInt64 = 0

    func fetchPosts() async throws -> [FeedPost] {
        if self.delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: self.delayNanoseconds)
        } else {
            await Task.yield()
        }
        return self.posts
    }
}

@Suite("Feed feature model")
struct FeedFeatureModelTests {
    @Test
    @MainActor
    func refreshShowsEmptyForNoPosts() async {
        let repository = FeedModelRepositorySpy()
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository)
        )

        await model.refreshAndWait()

        #expect(model.state == .empty)
    }

    @Test
    @MainActor
    func refreshShowsContent() async {
        let repository = FeedModelRepositorySpy()
        repository.posts = [FeedPost(id: 1, userID: 1, title: "A", body: "B")]
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository)
        )

        await model.refreshAndWait()

        if case let .content(posts) = model.state {
            #expect(posts.count == 1)
        } else {
            Issue.record("Expected content state")
        }
    }

    @Test
    @MainActor
    func cancelRefreshRestoresPriorContent() async {
        let repository = FeedModelRepositorySpy()
        repository.posts = [FeedPost(id: 1, userID: 1, title: "A", body: "B")]
        repository.delayNanoseconds = 500_000_000
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository)
        )
        await model.refreshAndWait()

        model.refresh()
        try? await Task.sleep(nanoseconds: 50_000_000)
        model.cancelRefresh()

        if case let .content(posts) = model.state {
            #expect(posts.count == 1)
        } else {
            Issue.record("Expected restored content after cancel")
        }
    }
}
