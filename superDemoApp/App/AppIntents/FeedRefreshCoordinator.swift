//
//  FeedRefreshCoordinator.swift
//  superDemoApp
//

import Foundation

/// App-owned Feed refresh handoff for App Intents (JP-P1-B).
/// Survives Feed tab remount: bumps typed navigation request ID and, when a
/// live `FeedFeatureModel` is registered, starts refresh immediately.
/// When the model is unmounted, the pending `feedRefreshRequestID` is consumed
/// on the next `register` so `openFeedTab: false` refreshes are not dropped.
///
/// Only the live Feed tab registers (`FeedView` with `embedsOwnNavigation`).
/// Engineering Stale Feed embeds a separate model and must **not** register —
/// otherwise `RefreshFeedIntent(openFeedTab: false)` refreshes the demo and
/// consumes the request while the real Feed tab misses it.
///
/// Registration is cleared in `FeedView.onDisappear` (no `weak static` —
/// SwiftFormat and SwiftLint disagree on that modifier order).
@MainActor
enum FeedRefreshCoordinator {
    private static var activeModel: FeedFeatureModel?
    /// Last `feedRefreshRequestID` consumed by a live model (register or request).
    private static var lastConsumedRefreshRequestID: UInt = 0

    static func register(_ model: FeedFeatureModel) {
        self.activeModel = model
        self.consumePendingRefreshIfNeeded(using: model)
    }

    static func unregister(_ model: FeedFeatureModel) {
        if self.activeModel === model {
            self.activeModel = nil
        }
    }

    /// Opens Feed (optional) via `AppNavigationStore`, then refreshes through
    /// the registered model when present. Pending request ID covers cold start
    /// / unmounted Feed when the model is not yet registered.
    static func requestRefresh(openFeedTab: Bool = true) {
        AppNavigationStore.current.requestFeedRefresh(openFeedTab: openFeedTab)
        if let model = self.activeModel {
            model.refresh()
            self.lastConsumedRefreshRequestID = AppNavigationStore.current.state.feedRefreshRequestID
        }
        // else: leave pending ID for `register` / `FeedView` to consume.
    }

    /// Applies a queued refresh that arrived while Feed was unmounted.
    static func consumePendingRefreshIfNeeded(using model: FeedFeatureModel) {
        let pendingID = AppNavigationStore.current.state.feedRefreshRequestID
        guard pendingID > self.lastConsumedRefreshRequestID else { return }
        self.lastConsumedRefreshRequestID = pendingID
        model.refresh()
    }

    /// Test seam — resets consumed ID tracking between cases.
    static func resetForTesting() {
        self.activeModel = nil
        self.lastConsumedRefreshRequestID = 0
    }
}
