//
//  FeedRefreshActivityAttributes.swift
//  FeedWidgetShared
//
//  ActivityKit attributes for Feed refresh Live Activity (JP-P1-A).
//  Shared by the main app (start/update/end) and the widget extension (UI).
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit

/// Live Activity attributes for a single Feed refresh cycle (gate A: refresh
/// + short post-complete hold, then end).
struct FeedRefreshActivityAttributes: ActivityAttributes {
    /// Fixed per activity instance (when the refresh began).
    var startedAt: Date

    struct ContentState: Codable, Hashable, Sendable {
        var phase: Phase
        var postCount: Int?
        var isStale: Bool
        var detail: String

        enum Phase: String, Codable, Hashable, Sendable {
            case refreshing
            case completed
            case failed
            case cancelled
        }

        static func refreshing() -> ContentState {
            ContentState(
                phase: .refreshing,
                postCount: nil,
                isStale: false,
                detail: "Refreshing Feed…"
            )
        }

        static func completed(postCount: Int, isStale: Bool) -> ContentState {
            let detail: String
            if postCount == 0 {
                detail = "Feed empty"
            } else if isStale {
                detail = "\(postCount) posts (stale cache)"
            } else {
                detail = "\(postCount) posts"
            }
            return ContentState(
                phase: .completed,
                postCount: postCount,
                isStale: isStale,
                detail: detail
            )
        }

        static func failed() -> ContentState {
            ContentState(
                phase: .failed,
                postCount: nil,
                isStale: false,
                detail: "Feed refresh failed"
            )
        }

        static func cancelled() -> ContentState {
            ContentState(
                phase: .cancelled,
                postCount: nil,
                isStale: false,
                detail: "Refresh cancelled"
            )
        }
    }
}
#endif
