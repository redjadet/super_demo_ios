//
//  TokenRefreshingTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("Token refreshing")
struct TokenRefreshingTests {
    @Test
    func emptyRefresherHasNoTokenAndFailsRefresh() async {
        let refresher = EmptyTokenRefresher()

        #expect(await refresher.currentAccessToken() == nil)

        await #expect(throws: APIError.unauthorizedAfterRefresh) {
            _ = try await refresher.refreshAccessToken()
        }
    }

    @Test
    func inMemoryDemoRefresherUpdatesAccessToken() async throws {
        let refresher = InMemoryDemoTokenRefresher(
            initialToken: "old",
            refreshedToken: "new"
        )

        #expect(await refresher.currentAccessToken() == "old")
        let refreshed = try await refresher.refreshAccessToken()
        #expect(refreshed == "new")
        #expect(await refresher.currentAccessToken() == "new")
        #expect(await refresher.refreshCount == 1)
    }
}
