//
//  SimulatedIdempotentPostTransport.swift
//  superDemoApp
//

import Foundation

/// App-local demo transport: records Idempotency-Key values and returns the same
/// accepted result on replay. Deduplication is **simulated** — not a live server.
final class SimulatedIdempotentPostTransport: IdempotentPostDemoTransporting, @unchecked Sendable {
    private let lock = NSLock()
    private var resultsByKey: [String: IdempotentPostDemoOutcome] = [:]
    private var submissionCount = 0

    /// Optional hook so unit tests can assert the wire-shaped request without Presentation.
    private let requestBuilder: @Sendable (String, Data) -> APIRequest

    init(
        endpoint: URL? = nil,
        requestBuilder: (@Sendable (String, Data) -> APIRequest)? = nil
    ) {
        let resolvedEndpoint: URL = {
            if let endpoint {
                return endpoint
            }
            guard let url = URL(string: "https://example.invalid/demo/idempotent-post") else {
                preconditionFailure("Invalid demo idempotent POST URL")
            }
            return url
        }()
        let defaultBuilder: @Sendable (String, Data) -> APIRequest = { key, body in
            APIRequest(
                url: resolvedEndpoint,
                method: .post,
                headers: ["Content-Type": "application/json"],
                body: body,
                idempotencyKey: key
            )
        }
        self.requestBuilder = requestBuilder ?? defaultBuilder
    }

    func submit(idempotencyKey: String, payload: Data) throws -> IdempotentPostDemoOutcome {
        // Build the same APIRequest shape production code would send (header + retry-safe POST).
        let request = self.requestBuilder(idempotencyKey, payload)
        precondition(request.isRetrySafe)
        precondition(
            request.urlRequest().value(forHTTPHeaderField: "Idempotency-Key") == idempotencyKey
        )

        self.lock.lock()
        defer { self.lock.unlock() }

        self.submissionCount += 1
        if let existing = self.resultsByKey[idempotencyKey] {
            switch existing {
            case let .accepted(message):
                return .duplicateSafeSimulated(
                    message: "Simulated duplicate-safe replay — \(message)"
                )
            case let .duplicateSafeSimulated(message):
                return .duplicateSafeSimulated(message: message)
            case let .failed(message):
                return .failed(message: message)
            }
        }

        let outcome = IdempotentPostDemoOutcome.accepted(
            message: "Accepted with Idempotency-Key \(idempotencyKey)"
        )
        self.resultsByKey[idempotencyKey] = outcome
        return outcome
    }

    func recordedSubmissionCount() -> Int {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.submissionCount
    }
}
