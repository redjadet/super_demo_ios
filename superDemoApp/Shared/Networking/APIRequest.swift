//
//  APIRequest.swift
//  superDemoApp
//

import Foundation

/// Wire method — value type used from Sendable / nonisolated networking paths.
nonisolated enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Immutable HTTP request model — must stay nonisolated under
/// `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor` so `@Sendable` transports and
/// retry policies can construct it without hopping to the main actor.
nonisolated struct APIRequest: Sendable {
    let url: URL
    let method: HTTPMethod
    let headers: [String: String]
    let body: Data?
    let idempotencyKey: String?

    init(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil,
        idempotencyKey: String? = nil
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.idempotencyKey = idempotencyKey
    }

    var isRetrySafe: Bool {
        switch self.method {
        case .get, .put, .delete:
            true
        case .post:
            self.idempotencyKey?.isEmpty == false
        }
    }

    func urlRequest(bearerToken: String? = nil) -> URLRequest {
        var request = URLRequest(url: self.url)
        request.httpMethod = self.method.rawValue
        request.httpBody = self.body
        request.timeoutInterval = 30
        for (key, value) in self.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        if let idempotencyKey, !idempotencyKey.isEmpty {
            request.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
        }
        if let bearerToken, !bearerToken.isEmpty {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}
