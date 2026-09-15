//
//  AppIntentNavigationRouter.swift
//  superDemoApp
//

import Foundation

extension Notification.Name {
    /// Posted when an App Intent asks the UI to open a typed destination.
    nonisolated static let appIntentNavigation = Notification.Name("com.ilkersevim.superDemoApp.appIntentNavigation")
}

/// Single handoff path from App Intents into `AppNavigationState`.
enum AppIntentNavigationRouter {
    /// Notification userInfo key for the destination URL (safe from any queue).
    nonisolated static let urlUserInfoKey = "url"

    @MainActor
    static func open(_ deepLink: AppDeepLink) {
        NotificationCenter.default.post(
            name: .appIntentNavigation,
            object: nil,
            userInfo: [urlUserInfoKey: deepLink.customSchemeURL]
        )
    }
}
