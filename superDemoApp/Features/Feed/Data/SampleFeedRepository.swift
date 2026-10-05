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
                    title: String(localized: "Architecture snapshot"),
                    body: String(
                        localized: "Deterministic Feed row for reviewer mode, UI tests, and simulator walks."
                    )
                ),
            ]
        )
    }
}

struct FailingSampleFeedRepository: FeedRepository {
    /// Brief pause so UITests can observe `feedLoading` after Retry (yield-only
    /// often completes before XCTest polls). Stale-demo / unit spies unchanged.
    private static let uiObservableFailureDelayNanoseconds: UInt64 = 200_000_000

    func fetchPosts() async throws -> FeedLoadResult {
        try await Task.sleep(nanoseconds: Self.uiObservableFailureDelayNanoseconds)
        throw FeedError.invalidResponse
    }
}
