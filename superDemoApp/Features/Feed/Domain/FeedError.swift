//
//  FeedError.swift
//  superDemoApp
//

import Foundation

enum FeedError: LocalizedError, Equatable {
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            String(localized: "The server response was invalid.")
        case let .httpStatus(code):
            String(localized: "The server returned status code \(code).")
        case .decodingFailed:
            String(localized: "Could not read posts from the response.")
        }
    }
}
