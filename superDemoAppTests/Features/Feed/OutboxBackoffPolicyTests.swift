//
//  OutboxBackoffPolicyTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("Outbox backoff policy")
struct OutboxBackoffPolicyTests {
    @Test
    func delayGrowsExponentiallyWithInjectableJitter() {
        let policy = OutboxBackoffPolicy(
            maxAttempts: 5,
            baseDelay: 1,
            maxDelay: 100,
            jitterRatio: 0.5,
            randomUnitInterval: { 0 } // no jitter
        )
        #expect(policy.delay(afterAttemptCount: 1) == 1)
        #expect(policy.delay(afterAttemptCount: 2) == 2)
        #expect(policy.delay(afterAttemptCount: 3) == 4)
    }

    @Test
    func delayRespectsMaxCap() {
        let policy = OutboxBackoffPolicy(
            maxAttempts: 10,
            baseDelay: 10,
            maxDelay: 15,
            jitterRatio: 0,
            randomUnitInterval: { 0 }
        )
        #expect(policy.delay(afterAttemptCount: 5) == 15)
    }

    @Test
    func maxAttemptsExhaustion() {
        let policy = OutboxBackoffPolicy(maxAttempts: 3)
        #expect(!policy.hasExhaustedAttempts(2))
        #expect(policy.hasExhaustedAttempts(3))
    }
}
