//
//  OutboxBackoffPolicy.swift
//  superDemoApp
//

import Foundation

/// Exponential backoff with injectable jitter for outbox retry scheduling.
nonisolated struct OutboxBackoffPolicy: Sendable {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let jitterRatio: Double
    let randomUnitInterval: @Sendable () -> Double

    init(
        maxAttempts: Int = 5,
        baseDelay: TimeInterval = 1,
        maxDelay: TimeInterval = 60,
        jitterRatio: Double = 0.2,
        randomUnitInterval: @escaping @Sendable () -> Double = { Double.random(in: 0 ... 1) }
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.jitterRatio = jitterRatio
        self.randomUnitInterval = randomUnitInterval
    }

    /// Delay after `attemptCount` failed attempts (1-based after increment).
    func delay(afterAttemptCount attemptCount: Int) -> TimeInterval {
        let capped = max(0, min(attemptCount - 1, 16))
        let exponential = self.baseDelay * pow(2, Double(capped))
        let clamped = min(exponential, self.maxDelay)
        let jitter = clamped * self.jitterRatio * self.randomUnitInterval()
        return min(clamped + jitter, self.maxDelay)
    }

    func hasExhaustedAttempts(_ attemptCount: Int) -> Bool {
        attemptCount >= self.maxAttempts
    }
}

/// Injectable clock for outbox scheduling tests.
nonisolated protocol OutboxClock: Sendable {
    func now() -> Date
}

nonisolated struct SystemOutboxClock: OutboxClock {
    init() {}

    func now() -> Date {
        Date()
    }
}

nonisolated struct FixedOutboxClock: OutboxClock {
    private let date: @Sendable () -> Date

    init(_ date: @escaping @Sendable () -> Date) {
        self.date = date
    }

    func now() -> Date {
        self.date()
    }
}
