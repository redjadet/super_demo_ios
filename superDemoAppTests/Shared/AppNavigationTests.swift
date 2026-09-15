//
//  AppNavigationTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("App navigation")
struct AppNavigationTests {
    @Test
    func productionRisksDeepLinkParsesAsTypedRoute() throws {
        let url = try #require(URL(string: "superdemo://dashboard/risks"))

        #expect(AppDeepLink(url: url) == .productionRisks)
    }

    @Test
    func dashboardDeepLinkParsesAsTypedRoute() throws {
        let url = try #require(URL(string: "superdemo://dashboard"))

        #expect(AppDeepLink(url: url) == .dashboard)
    }

    @Test
    func itemsDeepLinkParsesAsTypedRoute() throws {
        let url = try #require(URL(string: "superdemo://items"))

        #expect(AppDeepLink(url: url) == .items)
    }

    @Test
    func feedDeepLinkParsesAsTypedRoute() throws {
        let url = try #require(URL(string: "superdemo://feed"))

        #expect(AppDeepLink(url: url) == .feed)
    }

    @Test
    func httpsUniversalLinksParseMatchingPaths() throws {
        let risks = try #require(URL(string: "https://superdemo.app/dashboard/risks"))
        let feed = try #require(URL(string: "https://www.superdemo.app/feed"))
        let items = try #require(URL(string: "https://superdemo.app/items"))
        let dashboard = try #require(URL(string: "https://superdemo.app/dashboard"))

        #expect(AppDeepLink(url: risks) == .productionRisks)
        #expect(AppDeepLink(url: feed) == .feed)
        #expect(AppDeepLink(url: items) == .items)
        #expect(AppDeepLink(url: dashboard) == .dashboard)
    }

    @Test
    func httpsLinkOnUnknownHostIsRejected() throws {
        let url = try #require(URL(string: "https://example.com/feed"))

        #expect(AppDeepLink(url: url) == nil)
    }

    @Test
    func httpSchemeIsRejectedEvenOnAssociatedHost() throws {
        let url = try #require(URL(string: "http://superdemo.app/feed"))

        #expect(AppDeepLink(url: url) == nil)
    }

    @Test
    func httpsUniversalLinkRoutesToFeedTab() throws {
        let url = try #require(URL(string: "https://superdemo.app/feed"))
        var state = AppNavigationState(selection: .items)

        state.handle(url: url)

        #expect(state.selection == .feed)
        #expect(state.dashboardPath.isEmpty)
        #expect(state.invalidDeepLinkMessage == nil)
    }

    @Test
    func productionRisksDeepLinkRoutesColdStartToDashboard() throws {
        let url = try #require(URL(string: "superdemo://dashboard/risks"))
        var state = AppNavigationState()

        state.handle(url: url)

        #expect(state.selection == .dashboard)
        #expect(state.dashboardPath == [.productionRisks])
        #expect(state.invalidDeepLinkMessage == nil)
    }

    @Test
    func itemsDeepLinkRoutesToItemsTabAndClearsDashboardPath() throws {
        let url = try #require(URL(string: "superdemo://items"))
        var state = AppNavigationState(selection: .dashboard, dashboardPath: [.productionRisks])

        state.handle(url: url)

        #expect(state.selection == .items)
        #expect(state.dashboardPath.isEmpty)
        #expect(state.invalidDeepLinkMessage == nil)
    }

    @Test
    func feedDeepLinkRoutesToFeedTab() throws {
        let url = try #require(URL(string: "superdemo://feed"))
        var state = AppNavigationState(selection: .items)

        state.handle(url: url)

        #expect(state.selection == .feed)
        #expect(state.dashboardPath.isEmpty)
        #expect(state.invalidDeepLinkMessage == nil)
    }

    @Test
    func productionRisksDeepLinkReplacesWarmNavigationState() throws {
        let url = try #require(URL(string: "superdemo://dashboard/risks"))
        var state = AppNavigationState(selection: .feed, dashboardPath: [.productionRisks])

        state.handle(url: url)

        #expect(state.selection == .dashboard)
        #expect(state.dashboardPath == [.productionRisks])
    }

    @Test
    func unsupportedDeepLinkFallsBackToDashboardWithMessage() throws {
        let url = try #require(URL(string: "superdemo://dashboard/unknown"))
        var state = AppNavigationState(selection: .feed, dashboardPath: [.productionRisks])

        state.handle(url: url)

        #expect(state.selection == .dashboard)
        #expect(state.dashboardPath.isEmpty)
        #expect(state.invalidDeepLinkMessage != nil)
    }

    @Test
    func unsupportedHttpsPathFallsBackToDashboardWithMessage() throws {
        let url = try #require(URL(string: "https://superdemo.app/unknown"))
        var state = AppNavigationState(selection: .feed)

        state.handle(url: url)

        #expect(state.selection == .dashboard)
        #expect(state.dashboardPath.isEmpty)
        #expect(state.invalidDeepLinkMessage != nil)
    }
}
