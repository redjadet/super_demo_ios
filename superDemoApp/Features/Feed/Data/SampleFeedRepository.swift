//
//  SampleFeedRepository.swift
//  superDemoApp
//

import Foundation

struct SampleFeedRepository: FeedRepository {
    func fetchPosts() async throws -> FeedLoadResult {
        await Task.yield()
        return FeedLoadResult(
            posts: [
                FeedPost(
                    id: 1,
                    userID: 1,
                    title: "UI Test Post",
                    body: "Stable feed content for UI tests and simulator runs."
                ),
            ]
        )
    }
}

struct FailingSampleFeedRepository: FeedRepository {
    func fetchPosts() async throws -> FeedLoadResult {
        await Task.yield()
        throw FeedError.invalidResponse
    }
}
