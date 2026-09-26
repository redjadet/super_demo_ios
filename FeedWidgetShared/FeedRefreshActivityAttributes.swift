//
//  FeedRefreshActivityAttributes.swift
//  FeedWidgetShared
//
//  ActivityKit attributes for Feed refresh Live Activity (JP-P1-A).
//  Shared by the main app (start/update/end) and the widget extension (UI).
//

import Foundation

#if canImport(ActivityKit) && os(iOS)
import ActivityKit

/// Live Activity attributes for a single Feed refresh cycle (gate A: refresh
/// + short post-complete hold, then end).
///
/// `nonisolated` — ActivityKit APIs call into these types from `@concurrent`
/// contexts; under `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor` an isolated
/// `ActivityAttributes` conformance fails on Xcode 27 / Swift 6.4
/// (`#IsolatedConformances`).
nonisolated struct FeedRefreshActivityAttributes: ActivityAttributes {
    /// Fixed per activity instance (when the refresh began).
    var startedAt: Date

    nonisolated struct ContentState: Codable, Hashable, Sendable {
        var phase: Phase
        var postCount: Int?
        var isStale: Bool
        var detail: String

        nonisolated enum Phase: String, Codable, Hashable, Sendable {
            case refreshing
            case completed
            case failed
            case cancelled
        }

        static func refreshing() -> Self {
            Self(
                phase: .refreshing,
                postCount: nil,
                isStale: false,
                detail: "Refreshing Feed…"
            )
        }

        static func completed(postCount: Int, isStale: Bool) -> Self {
            let summary: String
            if postCount == 0 {
                summary = "Feed empty"
            } else if isStale {
                summary = "\(postCount) posts (stale cache)"
            } else {
                summary = "\(postCount) posts"
            }
            return Self(
                phase: .completed,
                postCount: postCount,
                isStale: isStale,
                detail: summary
            )
        }

        static func failed() -> Self {
            Self(
                phase: .failed,
                postCount: nil,
                isStale: false,
                detail: "Feed refresh failed"
            )
        }

        static func cancelled() -> Self {
            Self(
                phase: .cancelled,
                postCount: nil,
                isStale: false,
                detail: "Refresh cancelled"
            )
        }
    }
}
#endif
