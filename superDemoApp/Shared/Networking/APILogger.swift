//
//  APILogger.swift
//  superDemoApp
//

import Foundation
import os

protocol APILogging: Sendable {
    func requestStarted(_ request: APIRequest, attempt: Int)
    func requestFinished(url: URL, statusCode: Int, attempt: Int)
    func requestFailed(url: URL, error: APIError, attempt: Int)
}

struct RedactedAPILogger: APILogging {
    private let logger = Logger(subsystem: "com.ilkersevim.superDemoApp", category: "networking")

    func requestStarted(_ request: APIRequest, attempt: Int) {
        self.logger
            .info(
                "request started method=\(request.method.rawValue, privacy: .public) host=\(request.url.host() ?? "unknown", privacy: .public) attempt=\(attempt, privacy: .public)"
            )
    }

    func requestFinished(url: URL, statusCode: Int, attempt: Int) {
        self.logger
            .info(
                "request finished host=\(url.host() ?? "unknown", privacy: .public) status=\(statusCode, privacy: .public) attempt=\(attempt, privacy: .public)"
            )
    }

    func requestFailed(url: URL, error: APIError, attempt: Int) {
        self.logger
            .error(
                "request failed host=\(url.host() ?? "unknown", privacy: .public) error=\(String(describing: error), privacy: .public) attempt=\(attempt, privacy: .public)"
            )
    }
}
