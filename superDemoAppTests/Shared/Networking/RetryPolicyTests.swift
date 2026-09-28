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

    @Test
    func retryAfterRejectsNonFiniteAndOversizedValues() {
        let policy = RetryPolicy(
            baseDelayNanoseconds: 100,
            maxDelayNanoseconds: 500
        ) { _ in 0 }

        // Non-finite values must fall back to exponential backoff (no UInt64 trap).
        #expect(policy.delayNanoseconds(attempt: 1, retryAfter: "inf") == 100)
        #expect(policy.delayNanoseconds(attempt: 1, retryAfter: "-inf") == 100)
        #expect(policy.delayNanoseconds(attempt: 1, retryAfter: "nan") == 100)

        // Finite but huge values clamp safely (no UInt64 overflow trap).
        #expect(policy.delayNanoseconds(attempt: 1, retryAfter: "1e300") == 500)
        #expect(policy.delayNanoseconds(attempt: 1, retryAfter: "999999") == 500)
    }

    @Test
    func exponentialBackoffSaturatesWithoutOverflow() {
        let policy = RetryPolicy(
            baseDelayNanoseconds: UInt64.max / 2,
            maxDelayNanoseconds: 1000
        ) { _ in 0 }

        // Large attempt multipliers must not trap; result stays within maxDelay.
        #expect(policy.delayNanoseconds(attempt: 63, retryAfter: nil) == 1000)
        #expect(policy.delayNanoseconds(attempt: 100, retryAfter: nil) == 1000)
    }
}
