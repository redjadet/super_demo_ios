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
            "The server response was invalid."
        case let .httpStatus(code):
            "The server returned status code \(code)."
        case .decodingFailed:
            "Could not read posts from the response."
        }
    }
}
