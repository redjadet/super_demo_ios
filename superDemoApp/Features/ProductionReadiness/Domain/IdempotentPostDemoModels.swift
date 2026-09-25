//
//  IdempotentPostDemoModels.swift
//  superDemoApp
//

import Foundation

enum IdempotentPostDemoOutcome: Equatable, Sendable {
    case accepted(message: String)
    /// Same Idempotency-Key replayed; transport returned the prior result (simulated server dedupe).
    case duplicateSafeSimulated(message: String)
    case failed(message: String)
}

protocol IdempotentPostDemoTransporting: Sendable {
    func submit(idempotencyKey: String, payload: Data) throws -> IdempotentPostDemoOutcome
}

struct SubmitIdempotentPostDemoUseCase: Sendable {
    private let transport: any IdempotentPostDemoTransporting

    init(transport: any IdempotentPostDemoTransporting) {
        self.transport = transport
    }

    func callAsFunction(
        idempotencyKey: String,
        bodyJSON: String = #"{"demo":true}"#
    ) -> IdempotentPostDemoOutcome {
        do {
            return try self.transport.submit(
                idempotencyKey: idempotencyKey,
                payload: Data(bodyJSON.utf8)
            )
        } catch {
            return .failed(message: error.localizedDescription)
        }
    }
}
