//
//  ReviewerDemoFixturesTests.swift
//  superDemoAppTests
//

import SwiftData
import Testing
@testable import superDemoApp

@MainActor
@Suite("Reviewer demo fixtures")
struct ReviewerDemoFixturesTests {
    @Test
    func seedItemsAddsDeterministicItemsOnce() throws {
        let context = try Self.makeContext()

        try ReviewerDemoFixtures.seedItemsIfNeeded(in: context)
        try ReviewerDemoFixtures.seedItemsIfNeeded(in: context)

        let items = try context.fetch(FetchDescriptor<Item>(sortBy: [SortDescriptor(\.timestamp)]))
            .map { $0.toEntity() }
        #expect(items == ReviewerDemoFixtures.sampleItems)
    }

    @Test
    func seedFeedCacheReplacesExistingRows() throws {
        let context = try Self.makeFeedContext()
        try ReviewerDemoFixtures.seedFeedCache(
            in: context,
            posts: [FeedPost(id: 99, userID: 1, title: "Old", body: "Remove")]
        )
        try ReviewerDemoFixtures.seedFeedCache(in: context)

        var descriptor = FetchDescriptor<CachedFeedPost>()
        descriptor.sortBy = [SortDescriptor(\.postID)]
        let cached = try context.fetch(descriptor).map(\.toDomain)
        #expect(cached == ReviewerDemoFixtures.sampleFeedPosts)
    }

    @Test
    func staleDemoSessionReturnsStaleCachedPosts() async {
        let session = FeedComposition.makeStaleDemoSession()

        await session.model.refreshAndWait()

        if case let .content(posts, isStale) = session.model.state {
            #expect(isStale)
            #expect(posts == ReviewerDemoFixtures.sampleFeedPosts)
        } else {
            Issue.record("Expected stale content state from demo session")
        }
    }

    private static func makeContext() throws -> ModelContext {
        let schema = Schema([Item.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private static func makeFeedContext() throws -> ModelContext {
        let schema = Schema([CachedFeedPost.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }
}
