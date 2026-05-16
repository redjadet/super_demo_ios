//
//  FeedRepository.swift
//  superDemoApp
//

import Foundation

protocol FeedRepository: Sendable {
    func fetchPosts() async throws -> [FeedPost]
}
