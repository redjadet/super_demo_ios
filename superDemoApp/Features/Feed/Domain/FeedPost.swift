//
//  FeedPost.swift
//  superDemoApp
//

import Foundation

nonisolated struct FeedPost: Equatable, Hashable, Identifiable, Sendable {
    let id: Int
    let userID: Int
    let title: String
    let body: String
}
