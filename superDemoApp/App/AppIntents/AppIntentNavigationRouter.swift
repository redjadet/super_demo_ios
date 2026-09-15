//
//  AppIntentNavigationRouter.swift
//  superDemoApp
//

import Foundation

extension Notification.Name {
    /// Posted when an App Intent asks the UI to open a typed destination.
    static let appIntentNavigation = Notification.Name("com.ilkersevim.superDemoApp.appIntentNavigation")
}

/// Single handoff path from App Intents into `AppNavigationState`.
@MainActor
enum AppIntentNavigationRouter {
    static let urlUserInfoKey = "url"

    static func open(_ deepLink: AppDeepLink) {
        NotificationCenter.default.post(
            name: .appIntentNavigation,
            object: nil,
            userInfo: [urlUserInfoKey: deepLink.customSchemeURL]
        )
    }
}
