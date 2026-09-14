//
//  RefreshFeedUseCase.swift
//  superDemoApp
//

import Foundation

struct RefreshFeedUseCase {
    private let repository: any FeedRepository

    init(repository: any FeedRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> FeedLoadResult {
        try await self.repository.fetchPosts()
    }
}
