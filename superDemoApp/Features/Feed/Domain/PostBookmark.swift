//
//  PostBookmark.swift
//  superDemoApp
//

import Foundation

/// Optimistic bookmark state for a Feed post (local SwiftData + outbox).
nonisolated struct PostBookmark: Equatable, Identifiable, Sendable {
    var id: Int {
        self.postID
    }

    let postID: Int
    let isBookmarked: Bool
    let syncStatus: BookmarkSyncStatus
    let lastError: String?

    init(
        postID: Int,
        isBookmarked: Bool,
        syncStatus: BookmarkSyncStatus = .synced,
        lastError: String? = nil
    ) {
        self.postID = postID
        self.isBookmarked = isBookmarked
        self.syncStatus = syncStatus
        self.lastError = lastError
    }
}
