//
//  TokenRefreshing.swift
//  superDemoApp
//

import Foundation

nonisolated protocol TokenRefreshing: Sendable {
    func currentAccessToken() async -> String?
    func refreshAccessToken() async throws -> String
}

/// Production default until a real auth/session refresher is injected.
/// Returns no access token and fails refresh so callers surface unauthorized clearly.
nonisolated struct EmptyTokenRefresher: TokenRefreshing {
    func currentAccessToken() async -> String? {
        await Task.yield()
        return nil
    }

    func refreshAccessToken() async throws -> String {
        await Task.yield()
        throw APIError.unauthorizedAfterRefresh
    }
}

/// Demo/in-memory auth path for unit tests and reviewer demos.
/// Not Keychain-backed — swap for a Keychain-backed store before shipping real auth.
actor InMemoryDemoTokenRefresher: TokenRefreshing {
    private var accessToken: String?
    private let refreshedToken: String
    private(set) var refreshCount = 0

    init(initialToken: String? = "demo-access", refreshedToken: String = "demo-refreshed") {
        self.accessToken = initialToken
        self.refreshedToken = refreshedToken
    }

    func currentAccessToken() async -> String? {
        await Task.yield()
        return self.accessToken
    }

    func refreshAccessToken() async throws -> String {
        await Task.yield()
        self.refreshCount += 1
        self.accessToken = self.refreshedToken
        return self.refreshedToken
    }
}
