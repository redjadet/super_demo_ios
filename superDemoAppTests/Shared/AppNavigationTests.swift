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
    func productionRisksDeepLinkRoutesColdStartToDashboard() throws {
        let url = try #require(URL(string: "superdemo://dashboard/risks"))
        var state = AppNavigationState()

        state.handle(url: url)

        #expect(state.selection == .dashboard)
        #expect(state.dashboardPath == [.productionRisks])
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
}
