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

    private static func makeContext() throws -> ModelContext {
        let schema = Schema([Item.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }
}
