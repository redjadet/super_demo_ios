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
                Self.applyOnMain(deepLink)
            }
        } else {
            DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    Self.applyOnMain(deepLink)
                }
            }
        }
    }

    @MainActor
    private static func applyOnMain(_ deepLink: AppDeepLink) {
        AppNavigationStore.current.apply(deepLink)
    }
}
