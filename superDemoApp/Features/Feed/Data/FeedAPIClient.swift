//
//  FeedAPIClient.swift
//  superDemoApp
//

import Foundation

protocol FeedAPIClient: Sendable {
    func fetchPostsData() async throws -> Data
}

struct LiveFeedAPIClient: FeedAPIClient {
    private let session: URLSession
    private let postsURL: URL

    init(session: URLSession = .shared, postsURL: URL? = nil) {
        self.session = session
        if let postsURL {
            self.postsURL = postsURL
        } else {
            self.postsURL = Self.defaultPostsURL
        }
    }

    private static var defaultPostsURL: URL {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
            preconditionFailure("Invalid default feed posts URL")
        }
        return url
    }

    func fetchPostsData() async throws -> Data {
        var request = URLRequest(url: self.postsURL)
        request.timeoutInterval = 30
        let (data, response) = try await self.session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw FeedError.invalidResponse
        }
        guard (200 ... 299).contains(http.statusCode) else {
            throw FeedError.httpStatus(http.statusCode)
        }
        return data
    }
}
