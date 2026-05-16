//
//  AppModelContainer.swift
//  superDemoApp
//

import SwiftData

enum AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            Item.self,
            CachedFeedPost.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
