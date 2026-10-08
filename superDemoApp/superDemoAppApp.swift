//
//  SuperDemoApp.swift (file: superDemoAppApp.swift)
//  superDemoApp
//
//  Created by İlker Sevim on 15.05.2026.
//

import SwiftData
import SwiftUI

@main
struct SuperDemoApp: App {
    var body: some Scene {
        #if os(macOS)
        // Navigation/App Intent coordination is app-scoped: expose one desktop
        // window instead of allowing multiple windows to share selection state.
        Window("superDemoApp", id: "main") {
            AppRootView()
                .frame(minWidth: 680, minHeight: 500)
        }
        .modelContainer(AppModelContainer.shared)
        .defaultSize(width: 1040, height: 720)
        .windowResizability(.contentMinSize)
        .commands { MacAppCommands() }
        #else
        WindowGroup {
            AppRootView()
        }
        .modelContainer(AppModelContainer.shared)
        #endif
    }
}
