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

    init(postID: Int, userID: Int, title: String, body: String) {
        self.postID = postID
        self.userID = userID
        self.title = title
        self.body = body
    }

    convenience init(post: FeedPost) {
        self.init(
            postID: post.id,
            userID: post.userID,
            title: post.title,
            body: post.body
        )
    }

    func update(with post: FeedPost) {
        self.userID = post.userID
        self.title = post.title
        self.body = post.body
    }

    var toDomain: FeedPost {
        FeedPost(id: self.postID, userID: self.userID, title: self.title, body: self.body)
    }
}
