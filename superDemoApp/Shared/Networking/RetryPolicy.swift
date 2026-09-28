//
//  RetryPolicy.swift
//  superDemoApp
//

import Foundation

nonisolated struct RetryPolicy: Sendable {
    let maxAttempts: Int
    let baseDelayNanoseconds: UInt64
    let maxDelayNanoseconds: UInt64
    let jitterNanoseconds: @Sendable (UInt64) -> UInt64

    /// Upper bound for `Retry-After` / backoff conversion into nanoseconds.
    /// Keeps `UInt64` math finite and avoids multi-year sleep traps.
    nonisolated static let maxRetryAfterNanoseconds: UInt64 = 3_600_000_000_000 // 1 hour

    init(
        maxAttempts: Int = 3,
        baseDelayNanoseconds: UInt64 = 200_000_000,
        maxDelayNanoseconds: UInt64 = 2_000_000_000,
        jitterNanoseconds: @escaping @Sendable (UInt64) -> UInt64 = { delay in delay / 5 }
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelayNanoseconds = baseDelayNanoseconds
        self.maxDelayNanoseconds = maxDelayNanoseconds
        self.jitterNanoseconds = jitterNanoseconds
    }

    func shouldRetry(
        error: APIError,
        request: APIRequest,
        attempt: Int
    ) -> Bool {
        guard attempt < self.maxAttempts, request.isRetrySafe else { return false }
        return switch error {
        case let .transport(code):
            Self.retryableTransportCodes.contains(code)
        case let .httpStatus(status):
            Self.retryableStatusCodes.contains(status)
        case .invalidResponse, .unauthorizedAfterRefresh, .decodingFailed, .cancelled:
            false
        }
    }

    func delayNanoseconds(
        attempt: Int,
        retryAfter: String? = nil
    ) -> UInt64 {
        if let retryAfterDelay = Self.retryAfterNanoseconds(retryAfter) {
            return min(retryAfterDelay, self.maxDelayNanoseconds)
        }

        let cappedAttempt = max(0, min(attempt - 1, 62))
        let multiplier = cappedAttempt == 0 ? UInt64(1) : (UInt64(1) &<< cappedAttempt)
        let exponential = Self.saturatingMultiply(
            self.baseDelayNanoseconds,
            multiplier,
            cap: self.maxDelayNanoseconds
        )
        let withJitter = Self.saturatingAdd(
            exponential,
            self.jitterNanoseconds(exponential),
            cap: self.maxDelayNanoseconds
        )
        return min(withJitter, self.maxDelayNanoseconds)
    }

    private static let retryableStatusCodes = Set([429, 500, 502, 503, 504])

    private static let retryableTransportCodes: Set<URLError.Code> = [
        .timedOut,
        .cannotFindHost,
        .cannotConnectToHost,
        .networkConnectionLost,
        .dnsLookupFailed,
        .notConnectedToInternet,
        .internationalRoamingOff,
        .callIsActive,
        .dataNotAllowed,
    ]

    /// Parses `Retry-After` as delta-seconds or HTTP-date.
    /// Rejects non-finite / oversized numeric values that would trap on `UInt64`.
    private static func retryAfterNanoseconds(_ value: String?) -> UInt64? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if let seconds = TimeInterval(trimmed) {
            guard seconds.isFinite, seconds >= 0 else { return nil }
            return Self.secondsToNanoseconds(seconds)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"
        guard let date = formatter.date(from: trimmed) else { return nil }
        let seconds = date.timeIntervalSinceNow
        guard seconds.isFinite else { return nil }
        return Self.secondsToNanoseconds(max(0, seconds))
    }

    private static func secondsToNanoseconds(_ seconds: TimeInterval) -> UInt64? {
        let maxSeconds = TimeInterval(Self.maxRetryAfterNanoseconds) / 1_000_000_000
        guard seconds <= maxSeconds else {
            return Self.maxRetryAfterNanoseconds
        }
        let nanos = seconds * 1_000_000_000
        guard nanos.isFinite, nanos >= 0, nanos <= Double(Self.maxRetryAfterNanoseconds) else {
            return Self.maxRetryAfterNanoseconds
        }
        return UInt64(nanos)
    }

    private static func saturatingMultiply(_ lhs: UInt64, _ rhs: UInt64, cap: UInt64) -> UInt64 {
        let (product, overflow) = lhs.multipliedReportingOverflow(by: rhs)
        if overflow {
            return cap
        }
        return min(product, cap)
    }

    private static func saturatingAdd(_ lhs: UInt64, _ rhs: UInt64, cap: UInt64) -> UInt64 {
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        if overflow {
            return cap
        }
        return min(sum, cap)
    }
}

nonisolated protocol RetrySleeping: Sendable {
    func sleep(nanoseconds: UInt64) async throws
}

nonisolated struct TaskRetrySleeper: RetrySleeping {
    func sleep(nanoseconds: UInt64) async throws {
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}
