//
//  AppIntentNavigationRouter.swift
//  superDemoApp
//

import Foundation

/// Single handoff path from App Intents into `AppNavigationStore`.
enum AppIntentNavigationRouter {
    nonisolated static func open(_ deepLink: AppDeepLink) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                AppNavigationStore.current.apply(deepLink)
            }
        } else {
            DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    AppNavigationStore.current.apply(deepLink)
                }
            }
        }
    }

    /// Typed Feed refresh request (JP-P1-B). Optionally switches to the Feed tab.
    nonisolated static func requestFeedRefresh(openFeedTab: Bool = true) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                FeedRefreshCoordinator.requestRefresh(openFeedTab: openFeedTab)
            }
        } else {
            DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    FeedRefreshCoordinator.requestRefresh(openFeedTab: openFeedTab)
                }
            }
        }
    }
}
