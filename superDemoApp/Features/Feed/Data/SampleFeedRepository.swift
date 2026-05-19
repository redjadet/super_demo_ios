//
//  SampleFeedRepository.swift
//  superDemoApp
//

import Foundation

struct SampleFeedRepository: FeedRepository {
    func fetchPosts() async throws -> [FeedPost] {
        await Task.yield()
        return [
            FeedPost(
                id: 1,
                userID: 1,
                title: "UI Test Post",
                body: "Stable feed content for UI tests and simulator runs."
            ),
        ]
    }
}
