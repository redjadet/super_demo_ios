//
//  JSONPlaceholderBookmarkRemoteClientTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("JSONPlaceholder bookmark remote client")
struct JSONPlaceholderBookmarkRemoteClientTests {
    @Test
    func setBookmarkSendsIdempotencyKeyHeader() async throws {
        try await StubURLProtocolGate.shared.withSession(
            stubs: [
                .response(
                    statusCode: 201,
                    data: Data(#"{"id":101,"title":"bookmark:1","body":"x","userId":1}"#.utf8)
                ),
            ]
        ) { session, _ in
            let api = URLSessionAPIClient(
                session: session,
                retryPolicy: RetryPolicy(maxAttempts: 1)
            )
            let client = JSONPlaceholderBookmarkRemoteClient(client: api)
            let remoteID = try await client.setBookmark(postID: 1, idempotencyKey: "idem-42")
            #expect(remoteID == 101)
        }
    }

    @Test
    func setBookmarkMaps409ToConflict() async throws {
        try await StubURLProtocolGate.shared.withSession(
            stubs: [.response(statusCode: 409)]
        ) { session, _ in
            let api = URLSessionAPIClient(
                session: session,
                retryPolicy: RetryPolicy(maxAttempts: 1)
            )
            let client = JSONPlaceholderBookmarkRemoteClient(client: api)
            await #expect(throws: BookmarkRemoteError.conflict) {
                _ = try await client.setBookmark(postID: 1, idempotencyKey: "idem-conflict")
            }
        }
    }
}
