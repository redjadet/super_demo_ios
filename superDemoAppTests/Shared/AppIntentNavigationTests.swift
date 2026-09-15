//
//  AppIntentNavigationTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("App intent navigation")
struct AppIntentNavigationTests {
    @Test
    func customSchemeURLsRoundTripThroughDeepLinkParser() {
        let links: [AppDeepLink] = [.dashboard, .productionRisks, .items, .feed]

        for link in links {
            #expect(AppDeepLink(url: link.customSchemeURL) == link)
        }
    }

    @Test
    func applyDeepLinkRoutesProductionRisks() {
        var state = AppNavigationState(selection: .feed)

        state.apply(.productionRisks)

        #expect(state.selection == .dashboard)
        #expect(state.dashboardPath == [.productionRisks])
        #expect(state.invalidDeepLinkMessage == nil)
    }

    @Test
    @MainActor
    func openFeedIntentPostsNavigableURL() async throws {
        let url = try await Self.urlPosted {
            _ = try await OpenFeedIntent().perform()
        }
        #expect(AppDeepLink(url: url) == .feed)
    }

    @Test
    @MainActor
    func openItemsIntentPostsNavigableURL() async throws {
        let url = try await Self.urlPosted {
            _ = try await OpenItemsIntent().perform()
        }
        #expect(AppDeepLink(url: url) == .items)
    }

    @Test
    @MainActor
    func openProductionRisksIntentPostsNavigableURL() async throws {
        let url = try await Self.urlPosted {
            _ = try await OpenProductionRisksIntent().perform()
        }
        #expect(AppDeepLink(url: url) == .productionRisks)
    }

    @MainActor
    private static func urlPosted(by action: () async throws -> Void) async throws -> URL {
        var received: URL?
        let token = NotificationCenter.default.addObserver(
            forName: .appIntentNavigation,
            object: nil,
            queue: .main
        ) { note in
            received = note.userInfo?[AppIntentNavigationRouter.urlUserInfoKey] as? URL
        }
        defer { NotificationCenter.default.removeObserver(token) }

        try await action()
        return try #require(received)
    }
}
