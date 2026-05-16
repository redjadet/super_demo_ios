//
//  RemoteFeedRepositoryTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

private struct StubFeedAPIClient: FeedAPIClient {
    let data: Data
    let error: Error?

    func fetchPostsData() async throws -> Data {
        if let error {
            throw error
        }
        await Task.yield()
        return self.data
    }
}

@Suite("Remote feed repository")
struct RemoteFeedRepositoryTests {
    @Test
    func decodeMapsPosts() async throws {
        let json = Data(
            "[{\"userId\":1,\"id\":42,\"title\":\"Hello\",\"body\":\"World\"}]".utf8
        )
        let repository = RemoteFeedRepository(
            client: StubFeedAPIClient(data: json, error: nil)
        )

        let posts = try await repository.fetchPosts()

        #expect(posts.count == 1)
        #expect(posts[0].id == 42)
        #expect(posts[0].userID == 1)
        #expect(posts[0].title == "Hello")
    }

    @Test
    func invalidJSONThrowsDecodingFailed() async {
        let repository = RemoteFeedRepository(
            client: StubFeedAPIClient(data: Data("{".utf8), error: nil)
        )

        await #expect(throws: FeedError.decodingFailed) {
            _ = try await repository.fetchPosts()
        }
    }
}
