//
//  OutboxModels.swift
//  superDemoApp
//

import Foundation

/// Wire / persistence operation kinds for the offline mutation outbox.
nonisolated enum OutboxOperationKind: String, Codable, Equatable, Sendable {
    case bookmarkSet = "bookmark.set"
    case bookmarkClear = "bookmark.clear"

    var desiredBookmarked: Bool {
        switch self {
        case .bookmarkSet: true
        case .bookmarkClear: false
        }
    }

    static func bookmark(desiredBookmarked: Bool) -> Self {
        desiredBookmarked ? .bookmarkSet : .bookmarkClear
    }
}

nonisolated enum OutboxEntryStatus: String, Codable, Equatable, Sendable {
    case pending
    case inFlight
    case failed
    case completed
}

nonisolated struct BookmarkOutboxPayload: Codable, Equatable, Sendable {
    let postID: Int
    let desiredBookmarked: Bool

    var entityKey: String {
        Self.entityKey(postID: self.postID)
    }

    static func entityKey(postID: Int) -> String {
        "feedPost:\(postID)"
    }
}

/// Sendable snapshot of a persisted outbox row (Domain / actor safe).
nonisolated struct OutboxEntrySnapshot: Equatable, Identifiable, Sendable {
    let id: UUID
    let idempotencyKey: String
    let operationKind: OutboxOperationKind
    let entityKey: String
    let payload: Data
    let createdAt: Date
    let attemptCount: Int
    let nextAttemptAt: Date
    let status: OutboxEntryStatus
    let lastError: String?

    var bookmarkPayload: BookmarkOutboxPayload? {
        try? JSONDecoder().decode(BookmarkOutboxPayload.self, from: self.payload)
    }
}
