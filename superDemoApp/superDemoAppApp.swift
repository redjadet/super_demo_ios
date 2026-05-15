//
//  superDemoAppApp.swift
//  superDemoApp
//
//  Created by İlker Sevim on 15.05.2026.
//

import SwiftData
import SwiftUI

@main
struct superDemoAppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ItemsRootView()
        }
        .modelContainer(self.sharedModelContainer)
    }
}
