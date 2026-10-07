//
//  BookmarkedPost.swift
//  superDemoApp
//

import Foundation
import SwiftData

/// Local optimistic bookmark for a Feed post.
@Model
final class BookmarkedPost {
    @Attribute(.unique)
    var postID: Int
    var isBookmarked: Bool
    /// Last value confirmed by a successful remote sync (coalesce baseline).
    var lastSyncedIsBookmarked: Bool
    var syncStatusRaw: String
    var lastError: String?
    /// Remote id returned by JSONPlaceholder POST when the bookmark was set.
    var remoteBookmarkID: Int?
    var updatedAt: Date

    init(
        postID: Int,
        isBookmarked: Bool,
        lastSyncedIsBookmarked: Bool = false,
        syncStatus: BookmarkSyncStatus = .pending,
        lastError: String? = nil,
        remoteBookmarkID: Int? = nil,
        updatedAt: Date = Date()
    ) {
        self.postID = postID
        self.isBookmarked = isBookmarked
        self.lastSyncedIsBookmarked = lastSyncedIsBookmarked
        self.syncStatusRaw = syncStatus.rawValue
        self.lastError = lastError
        self.remoteBookmarkID = remoteBookmarkID
        self.updatedAt = updatedAt
    }

    var syncStatus: BookmarkSyncStatus {
        get { BookmarkSyncStatus(rawValue: self.syncStatusRaw) ?? .synced }
        set { self.syncStatusRaw = newValue.rawValue }
    }

    func toEntity() -> PostBookmark {
        PostBookmark(
            postID: self.postID,
            isBookmarked: self.isBookmarked,
            syncStatus: self.syncStatus,
            lastError: self.lastError
        )
    }
}
