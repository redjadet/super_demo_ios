//
//  AppIntentNavigationTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("App intent navigation", .serialized)
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
    func openFeedIntentAppliesFeedOnNavigationStore() async throws {
        let store = AppNavigationStore()
        AppNavigationStore.testingOverride = store
        defer { AppNavigationStore.testingOverride = nil }

        store.state.selection = .dashboard
        _ = try await OpenFeedIntent().perform()

        #expect(store.state.selection == .feed)
    }

    @Test
    @MainActor
    func openItemsIntentAppliesItemsOnNavigationStore() async throws {
        let store = AppNavigationStore()
        AppNavigationStore.testingOverride = store
        defer { AppNavigationStore.testingOverride = nil }

        store.state.selection = .dashboard
        _ = try await OpenItemsIntent().perform()

        #expect(store.state.selection == .items)
    }

    @Test
    @MainActor
    func openProductionRisksIntentAppliesDashboardAndPathOnNavigationStore() async throws {
        let store = AppNavigationStore()
        AppNavigationStore.testingOverride = store
        defer { AppNavigationStore.testingOverride = nil }

        store.state.selection = .feed
        _ = try await OpenProductionRisksIntent().perform()

        #expect(store.state.selection == .dashboard)
        #expect(store.state.dashboardPath == [.productionRisks])
    }
}
