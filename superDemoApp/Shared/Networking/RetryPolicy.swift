//
//  RetryPolicy.swift
//  superDemoApp
//

import Foundation

struct RetryPolicy {
    let maxAttempts: Int
    let baseDelayNanoseconds: UInt64
    let maxDelayNanoseconds: UInt64
    let jitterNanoseconds: @Sendable (UInt64) -> UInt64

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
            return retryAfterDelay
        }

        let multiplier = UInt64(1 << max(0, attempt - 1))
        let exponential = min(self.baseDelayNanoseconds * multiplier, self.maxDelayNanoseconds)
        return min(exponential + self.jitterNanoseconds(exponential), self.maxDelayNanoseconds)
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

    private static func retryAfterNanoseconds(_ value: String?) -> UInt64? {
        guard let value else { return nil }
        if let seconds = TimeInterval(value.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return UInt64(max(0, seconds) * 1_000_000_000)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"
        guard let date = formatter.date(from: value) else { return nil }
        return UInt64(max(0, date.timeIntervalSinceNow) * 1_000_000_000)
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
