//
//  APIError.swift
//  superDemoApp
//

import Foundation

enum APIError: Error, Equatable, LocalizedError {
    case invalidResponse
    case transport(URLError.Code)
    case httpStatus(Int)
    case unauthorizedAfterRefresh
    case decodingFailed
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The server response was invalid."
        case let .transport(code):
            "The network request failed: \(code)."
        case let .httpStatus(status):
            "The server returned HTTP \(status)."
        case .unauthorizedAfterRefresh:
            "The session could not be refreshed."
        case .decodingFailed:
            "The response could not be decoded."
        case .cancelled:
            "The request was cancelled."
        }
    }
}

struct APIResponse {
    let data: Data
    let statusCode: Int
    let headers: [String: String]

    func headerValue(for name: String) -> String? {
        let normalized = name.lowercased()
        return self.headers.first { $0.key.lowercased() == normalized }?.value
    }
}
