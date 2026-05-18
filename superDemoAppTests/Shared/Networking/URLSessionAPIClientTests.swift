//
//  URLSessionAPIClientTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@MainActor
@Suite("URLSession API client")
struct URLSessionAPIClientTests {
    @Test
    func exercisesRetryAuthAndFailureMapping() async throws {
        try await self.refreshesTokenOnceThenRetriesOriginalRequest()
        try await self.respectsRetryAfterForRateLimit()
        try await self.mapsTransportAndHTTPFailures()
    }

    private func refreshesTokenOnceThenRetriesOriginalRequest() async throws {
        let url = try #require(URL(string: "https://example.com/secure"))
        try await StubURLProtocolGate.shared.withSession(stubs: [
            .response(statusCode: 401),
            .response(statusCode: 200, data: Data("ok".utf8)),
        ]) { session, sessionID in
            let refresher = TestTokenRefresher(token: "old", refreshedToken: "new")
            let client = URLSessionAPIClient(
                session: session,
                retryPolicy: RetryPolicy(maxAttempts: 1),
                tokenRefresher: refresher,
                logger: NoopAPILogger(),
                sleeper: TestRetrySleeper()
            )

            let response = try await client.send(APIRequest(url: url))

            #expect(response.statusCode == 200)
            #expect(await refresher.refreshCount == 1)
            #expect(StubSessionRegistry.shared.requestCount(sessionID: sessionID) == 2)
        }
    }

    private func respectsRetryAfterForRateLimit() async throws {
        let url = try #require(URL(string: "https://example.com/rate-limited"))
        try await StubURLProtocolGate.shared.withSession(stubs: [
            .response(statusCode: 429, headers: ["Retry-After": "1"]),
            .response(statusCode: 200),
        ]) { session, _ in
            let sleeper = TestRetrySleeper()
            let client = URLSessionAPIClient(
                session: session,
                retryPolicy: RetryPolicy(maxAttempts: 2) { _ in 0 },
                logger: NoopAPILogger(),
                sleeper: sleeper
            )

            let response = try await client.send(APIRequest(url: url))

            #expect(response.statusCode == 200)
            #expect(await sleeper.delays == [1_000_000_000])
        }
    }

    private func mapsTransportAndHTTPFailures() async throws {
        let url = try #require(URL(string: "https://example.com/failing"))
        try await self.withStubSession(stubs: [.error(URLError(.timedOut))]) { session in
            let client = URLSessionAPIClient(
                session: session,
                retryPolicy: RetryPolicy(maxAttempts: 1),
                logger: NoopAPILogger(),
                sleeper: TestRetrySleeper()
            )

            await #expect(throws: APIError.transport(.timedOut)) {
                _ = try await client.send(APIRequest(url: url))
            }
        }

        try await self.withStubSession(stubs: [.response(statusCode: 400)]) { session in
            let client = URLSessionAPIClient(
                session: session,
                retryPolicy: RetryPolicy(maxAttempts: 1),
                logger: NoopAPILogger(),
                sleeper: TestRetrySleeper()
            )

            await #expect(throws: APIError.httpStatus(400)) {
                _ = try await client.send(APIRequest(url: url))
            }
        }
    }

    private func withStubSession(
        stubs: [StubURLProtocol.Stub],
        _ body: @escaping (URLSession) async throws -> Void
    ) async throws {
        try await StubURLProtocolGate.shared.withSession(stubs: stubs) { session, _ in
            try await body(session)
        }
    }
}

private struct NoopAPILogger: APILogging {
    func requestStarted(_: APIRequest, attempt _: Int) {}
    func requestFinished(url _: URL, statusCode _: Int, attempt _: Int) {}
    func requestFailed(url _: URL, error _: APIError, attempt _: Int) {}
}

private actor TestRetrySleeper: RetrySleeping {
    private(set) var delays: [UInt64] = []

    func sleep(nanoseconds: UInt64) async throws {
        await Task.yield()
        self.delays.append(nanoseconds)
    }
}

private actor TestTokenRefresher: TokenRefreshing {
    private let token: String
    private let refreshedToken: String
    private(set) var refreshCount = 0

    init(token: String, refreshedToken: String) {
        self.token = token
        self.refreshedToken = refreshedToken
    }

    func currentAccessToken() async -> String? {
        await Task.yield()
        return self.token
    }

    func refreshAccessToken() async throws -> String {
        await Task.yield()
        self.refreshCount += 1
        return self.refreshedToken
    }
}
