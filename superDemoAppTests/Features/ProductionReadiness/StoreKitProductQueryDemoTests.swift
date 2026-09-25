//
//  StoreKitProductQueryDemoTests.swift
//  superDemoAppTests
//
//  Spy-based coverage for JP-P1-D. StoreKitTest (SKTestSession) needs a Mac +
//  Xcode host with Config/Products.storekit on the Test scheme — not available
//  on Linux agents; see docs/changes/2026-09-25_storekit-product-query-demo.md.
//

import Foundation
import Testing
@testable import superDemoApp

@MainActor
private final class StoreKitProductQuerierSpy: StoreKitProductQuerying {
    enum Behavior {
        case products([StoreKitDemoProduct])
        case empty
        case unavailable(String)
        case cancelled
    }

    var behavior: Behavior = .empty
    var lastRequestedIDs: [String] = []
    var callCount = 0

    func products(for ids: [String]) async throws -> [StoreKitDemoProduct] {
        await Task.yield()
        self.callCount += 1
        self.lastRequestedIDs = ids
        switch self.behavior {
        case let .products(list):
            return list
        case .empty:
            return []
        case let .unavailable(reason):
            throw StoreKitProductQueryFailure.unavailable(reason: reason)
        case .cancelled:
            throw CancellationError()
        }
    }
}

@Suite("StoreKit product query demo")
struct StoreKitProductQueryDemoTests {
    @Test
    @MainActor
    func loadProductsShowsLoadedState() async {
        let spy = StoreKitProductQuerierSpy()
        let sample = StoreKitDemoProduct(
            id: StoreKitDemoProductIDs.tipJar,
            displayName: "Portfolio Tip Jar (Demo)",
            description: "Demo",
            displayPrice: "$0.99"
        )
        spy.behavior = .products([sample])
        let model = StoreKitProductQueryDemoModel(querier: spy)

        await model.loadProducts()

        #expect(spy.callCount == 1)
        #expect(spy.lastRequestedIDs == StoreKitDemoProductIDs.allKnown)
        #expect(model.state == .loaded([sample]))
        #expect(model.isBusy == false)
    }

    @Test
    @MainActor
    func loadProductsShowsHonestEmptyState() async {
        let spy = StoreKitProductQuerierSpy()
        spy.behavior = .empty
        let model = StoreKitProductQueryDemoModel(querier: spy)

        await model.loadProducts()

        #expect(model.state == .empty)
    }

    @Test
    @MainActor
    func loadProductsShowsUnavailableState() async {
        let spy = StoreKitProductQuerierSpy()
        spy.behavior = .unavailable("testing config missing")
        let model = StoreKitProductQueryDemoModel(querier: spy)

        await model.loadProducts()

        #expect(model.state == .unavailable("testing config missing"))
    }

    @Test
    @MainActor
    func cancellationRestoresIdle() async {
        let spy = StoreKitProductQuerierSpy()
        spy.behavior = .cancelled
        let model = StoreKitProductQueryDemoModel(querier: spy)

        await model.loadProducts()

        #expect(model.state == .idle)
    }

    @Test
    func demoProductIDsMatchStoreKitConfigConvention() {
        #expect(StoreKitDemoProductIDs.tipJar == "com.ilkersevim.superDemoApp.demo.tip")
        #expect(StoreKitDemoProductIDs.allKnown == [StoreKitDemoProductIDs.tipJar])
    }
}
