//
//  IdempotentPostDemoTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("Idempotent POST demo transport")
struct IdempotentPostDemoTests {
    @Test
    func buildsIdempotencyKeyHeaderAndMarksPostRetrySafe() throws {
        let url = try #require(URL(string: "https://example.com/events"))
        let request = APIRequest(
            url: url,
            method: .post,
            body: Data(#"{"demo":true}"#.utf8),
            idempotencyKey: "event-1"
        )

        #expect(request.isRetrySafe)
        #expect(request.urlRequest().value(forHTTPHeaderField: "Idempotency-Key") == "event-1")
    }

    @Test
    func simulatedTransportReturnsDuplicateSafeOnRepeatedKey() throws {
        let transport = SimulatedIdempotentPostTransport()
        let first = try transport.submit(
            idempotencyKey: "demo-1",
            payload: Data(#"{"n":1}"#.utf8)
        )
        let second = try transport.submit(
            idempotencyKey: "demo-1",
            payload: Data(#"{"n":1}"#.utf8)
        )

        guard case .accepted = first else {
            Issue.record("expected first accept")
            return
        }
        guard case .duplicateSafeSimulated = second else {
            Issue.record("expected simulated duplicate-safe replay")
            return
        }
        #expect(transport.recordedSubmissionCount() == 2)
    }

    @Test
    func useCaseSurfacesSimulatedDuplicateSafeLabel() {
        let transport = SimulatedIdempotentPostTransport()
        let useCase = SubmitIdempotentPostDemoUseCase(transport: transport)

        let first = useCase(idempotencyKey: "k-1")
        let second = useCase(idempotencyKey: "k-1")

        guard case .accepted = first else {
            Issue.record("expected accepted")
            return
        }
        guard case let .duplicateSafeSimulated(message) = second else {
            Issue.record("expected duplicate-safe")
            return
        }
        #expect(message.localizedCaseInsensitiveContains("simulated"))
    }
}

@Suite("Idempotent POST retry policy")
struct IdempotentPostRetryPolicyDemoTests {
    @Test
    func postRetriesOnlyWhenIdempotencyKeyPresent() throws {
        let url = try #require(URL(string: "https://example.com/events"))
        let policy = RetryPolicy(maxAttempts: 3) { _ in 0 }
        let unsafePost = APIRequest(url: url, method: .post, body: Data("{}".utf8))
        let safePost = APIRequest(
            url: url,
            method: .post,
            body: Data("{}".utf8),
            idempotencyKey: "event-1"
        )

        #expect(policy.shouldRetry(error: .httpStatus(503), request: unsafePost, attempt: 1) == false)
        #expect(policy.shouldRetry(error: .httpStatus(503), request: safePost, attempt: 1))
        #expect(policy.shouldRetry(error: .httpStatus(503), request: safePost, attempt: 2))
        #expect(policy.shouldRetry(error: .httpStatus(503), request: safePost, attempt: 3) == false)
    }
}
