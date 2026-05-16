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
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(AppModelContainer.shared)
    }
}
