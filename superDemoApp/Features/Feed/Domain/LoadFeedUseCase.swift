//
//  LoadFeedUseCase.swift
//  superDemoApp
//

import Foundation

struct LoadFeedUseCase {
    private let repository: any FeedRepository

    init(repository: any FeedRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> [FeedPost] {
        try await self.repository.fetchPosts()
    }
}
