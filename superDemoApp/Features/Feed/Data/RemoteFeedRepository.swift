//
//  RemoteFeedRepository.swift
//  superDemoApp
//

import Foundation

struct RemoteFeedRepository: FeedRepository {
    private let client: any FeedAPIClient

    init(client: any FeedAPIClient) {
        self.client = client
    }

    func fetchPosts() async throws -> FeedLoadResult {
        let data = try await self.client.fetchPostsData()
        let decoder = JSONDecoder()
        do {
            let dtos = try decoder.decode([PostDTO].self, from: data)
            return FeedLoadResult(posts: dtos.map(\.toDomain))
        } catch {
            throw FeedError.decodingFailed
        }
    }
}
