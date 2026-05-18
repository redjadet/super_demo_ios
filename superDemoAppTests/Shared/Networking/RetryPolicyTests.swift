//
//  RetryPolicyTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("Retry policy")
struct RetryPolicyTests {
    @Test
    func classifiesRetryableAndNonRetryableFailures() throws {
        let url = try #require(URL(string: "https://example.com/health"))
        let request = APIRequest(url: url)
        let policy = RetryPolicy(maxAttempts: 3) { _ in 0 }

        #expect(policy.shouldRetry(error: .transport(.timedOut), request: request, attempt: 1))
        #expect(policy.shouldRetry(error: .httpStatus(503), request: request, attempt: 1))
        #expect(!policy.shouldRetry(error: .httpStatus(404), request: request, attempt: 1))
        #expect(!policy.shouldRetry(error: .httpStatus(503), request: request, attempt: 3))
    }

    @Test
    func postRetriesOnlyWithIdempotencyKey() throws {
        let url = try #require(URL(string: "https://example.com/events"))
        let policy = RetryPolicy(maxAttempts: 3) { _ in 0 }
        let unsafePost = APIRequest(url: url, method: .post, body: Data("{}".utf8))
        let safePost = APIRequest(url: url, method: .post, body: Data("{}".utf8), idempotencyKey: "event-1")

        #expect(!policy.shouldRetry(error: .httpStatus(503), request: unsafePost, attempt: 1))
        #expect(policy.shouldRetry(error: .httpStatus(503), request: safePost, attempt: 1))
    }

    @Test
    func retryAfterHeaderBeatsExponentialBackoff() {
        let policy = RetryPolicy(baseDelayNanoseconds: 100) { _ in 0 }

        #expect(policy.delayNanoseconds(attempt: 1, retryAfter: "2") == 2_000_000_000)
        #expect(policy.delayNanoseconds(attempt: 2, retryAfter: nil) == 200)
    }
}
