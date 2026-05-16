//
//  PostDTO.swift
//  superDemoApp
//

import Foundation

struct PostDTO: Decodable {
    let userId: Int
    let id: Int
    let title: String
    let body: String

    var toDomain: FeedPost {
        FeedPost(id: self.id, userID: self.userId, title: self.title, body: self.body)
    }
}
