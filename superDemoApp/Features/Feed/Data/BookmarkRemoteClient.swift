//
//  BookmarkRemoteClient.swift
//  superDemoApp
//

import Foundation

/// Remote transport for Feed bookmark mutations.
///
/// Live implementation maps to JSONPlaceholder `POST/DELETE /posts` — that API
/// fakes persistence (no real bookmarks resource). The protocol stays mockable
/// for tests; do not invent a `/bookmarks` path.
///
/// `nonisolated` so `OutboxSyncEngine` (and Sendable test closures) can call
/// under `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`.
nonisolated protocol BookmarkRemoteClient: Sendable {
    /// Sets a bookmark remotely. Returns a remote id when the server assigns one.
    func setBookmark(
        postID: Int,
        idempotencyKey: String
    ) async throws -> Int?

    /// Clears a bookmark remotely.
    func clearBookmark(
        postID: Int,
        remoteBookmarkID: Int?,
        idempotencyKey: String
    ) async throws
}

nonisolated enum BookmarkRemoteError: Error, Equatable, Sendable {
    case conflict
    case httpStatus(Int)
    case transport
    case decodingFailed
}
