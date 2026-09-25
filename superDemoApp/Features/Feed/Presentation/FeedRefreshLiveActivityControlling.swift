//
//  FeedRefreshLiveActivityControlling.swift
//  superDemoApp
//
//  Presentation-facing Live Activity lifecycle for Feed refresh (JP-P1-A).
//  ActivityKit stays in App composition — this protocol keeps Feature models
//  free of ActivityKit imports (Mac / visionOS / tests).
//

import Foundation

/// Controls the Feed-refresh Live Activity surface. Implementations may no-op
/// when ActivityKit is unavailable (Mac, Simulator limits, entitlement gaps).
@MainActor
protocol FeedRefreshLiveActivityControlling: AnyObject {
    func refreshDidStart()
    func refreshDidSucceed(postCount: Int, isStale: Bool)
    func refreshDidFail()
    func refreshDidCancel()
}

/// Default for unit tests and platforms without ActivityKit.
@MainActor
final class NoOpFeedRefreshLiveActivityController: FeedRefreshLiveActivityControlling {
    func refreshDidStart() {
        // Intentionally empty — tests / platforms without ActivityKit.
    }

    func refreshDidSucceed(postCount _: Int, isStale _: Bool) {
        // Intentionally empty — tests / platforms without ActivityKit.
    }

    func refreshDidFail() {
        // Intentionally empty — tests / platforms without ActivityKit.
    }

    func refreshDidCancel() {
        // Intentionally empty — tests / platforms without ActivityKit.
    }
}
