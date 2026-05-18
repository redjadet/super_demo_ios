//
//  TokenRefreshing.swift
//  superDemoApp
//

import Foundation

protocol TokenRefreshing: Sendable {
    func currentAccessToken() async -> String?
    func refreshAccessToken() async throws -> String
}

struct EmptyTokenRefresher: TokenRefreshing {
    func currentAccessToken() async -> String? {
        await Task.yield()
        return nil
    }

    func refreshAccessToken() async throws -> String {
        await Task.yield()
        throw APIError.unauthorizedAfterRefresh
    }
}
