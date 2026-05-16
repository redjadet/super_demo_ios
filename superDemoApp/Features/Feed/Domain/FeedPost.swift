//
//  FeedPost.swift
//  superDemoApp
//

import Foundation

struct FeedPost: Equatable, Identifiable {
    let id: Int
    let userID: Int
    let title: String
    let body: String
}
