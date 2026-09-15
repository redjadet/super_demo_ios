//
//  CachedFeedPost.swift
//  superDemoApp
//

import Foundation
import SwiftData

@Model
final class CachedFeedPost {
    @Attribute(.unique)
    var postID: Int
    var userID: Int
    var title: String
    var body: String
    /// When this row was last written from a successful remote fetch.
    /// Optional so lightweight migration can add the column to older stores.
    var cachedAt: Date?

    init(postID: Int, userID: Int, title: String, body: String, cachedAt: Date = .now) {
        self.postID = postID
        self.userID = userID
        self.title = title
        self.body = body
        self.cachedAt = cachedAt
    }

    convenience init(post: FeedPost, cachedAt: Date = .now) {
        self.init(
            postID: post.id,
            userID: post.userID,
            title: post.title,
            body: post.body,
            cachedAt: cachedAt
        )
    }

    func update(with post: FeedPost, cachedAt: Date = .now) {
        self.userID = post.userID
        self.title = post.title
        self.body = post.body
        self.cachedAt = cachedAt
    }

    /// Treats missing timestamps as expired for TTL checks.
    var effectiveCachedAt: Date {
        self.cachedAt ?? Date.distantPast
    }

    var toDomain: FeedPost {
        FeedPost(id: self.postID, userID: self.userID, title: self.title, body: self.body)
    }
}
