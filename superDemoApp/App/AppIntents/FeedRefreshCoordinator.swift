//
//  FeedRefreshCoordinator.swift
//  superDemoApp
//

import Foundation

/// App-owned Feed refresh handoff for App Intents (JP-P1-B).
/// Survives Feed tab remount: bumps typed navigation request ID and, when a
/// live `FeedFeatureModel` is registered, starts refresh immediately.
///
/// Registration is cleared in `FeedView.onDisappear` (no `weak static` —
/// SwiftFormat and SwiftLint disagree on that modifier order).
@MainActor
enum FeedRefreshCoordinator {
    private static var activeModel: FeedFeatureModel?

    static func register(_ model: FeedFeatureModel) {
        self.activeModel = model
    }

    static func unregister(_ model: FeedFeatureModel) {
        if self.activeModel === model {
            self.activeModel = nil
        }
    }

    /// Opens Feed (optional) via `AppNavigationStore`, then refreshes through
    /// the registered model when present. Pending request ID covers cold start
    /// when the model is not yet mounted.
    static func requestRefresh(openFeedTab: Bool = true) {
        AppNavigationStore.current.requestFeedRefresh(openFeedTab: openFeedTab)
        self.activeModel?.refresh()
    }
}
