//
//  FeedRepository.swift
//  superDemoApp
//

import Foundation

nonisolated struct FeedLoadResult: Equatable {
    let posts: [FeedPost]
    let isStale: Bool

    init(posts: [FeedPost], isStale: Bool = false) {
        self.posts = posts
        self.isStale = isStale
    }
}

protocol FeedRepository: Sendable {
    func fetchPosts() async throws -> FeedLoadResult
}
