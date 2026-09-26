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

    @Test
    func requestFeedRefreshOpensFeedAndBumpsRequestID() {
        var state = AppNavigationState(selection: .dashboard)

        state.requestFeedRefresh(openFeedTab: true)

        #expect(state.selection == .feed)
        #expect(state.dashboardPath.isEmpty)
        #expect(state.feedRefreshRequestID == 1)
        #expect(state.invalidDeepLinkMessage == nil)
    }

    @Test
    func requestFeedRefreshCanSkipTabSwitch() {
        var state = AppNavigationState(selection: .items)
        state.feedRefreshRequestID = 3

        state.requestFeedRefresh(openFeedTab: false)

        #expect(state.selection == .items)
        #expect(state.feedRefreshRequestID == 4)
    }

    @Test
    @MainActor
    func refreshFeedIntentRequestsRefreshAndOpensFeed() async throws {
        let store = AppNavigationStore()
        AppNavigationStore.testingOverride = store
        defer { AppNavigationStore.testingOverride = nil }

        store.state.selection = .items
        let intent = RefreshFeedIntent()
        intent.openFeedTab = true
        _ = try await intent.perform()

        #expect(store.state.selection == .feed)
        #expect(store.state.feedRefreshRequestID == 1)
    }

    @Test
    @MainActor
    func refreshFeedIntentCanSkipOpeningFeedTab() async throws {
        let store = AppNavigationStore()
        AppNavigationStore.testingOverride = store
        defer { AppNavigationStore.testingOverride = nil }

        store.state.selection = .dashboard
        let intent = RefreshFeedIntent()
        intent.openFeedTab = false
        _ = try await intent.perform()

        #expect(store.state.selection == .dashboard)
        #expect(store.state.feedRefreshRequestID == 1)
    }

    @Test
    @MainActor
    func feedRefreshCoordinatorRefreshesRegisteredModel() async {
        let repository = CoordinatorFeedRepositorySpy()
        repository.posts = [FeedPost(id: 1, userID: 1, title: "A", body: "B")]
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository)
        )
        FeedRefreshCoordinator.register(model)
        defer { FeedRefreshCoordinator.unregister(model) }

        FeedRefreshCoordinator.requestRefresh(openFeedTab: false)

        for _ in 0 ..< 100 where model.state == .loading {
            await Task.yield()
        }

        #expect(repository.fetchCount >= 1)
        guard case let .content(posts, _) = model.state else {
            Issue.record("Expected content after coordinator refresh, got \(model.state)")
            return
        }
        #expect(posts.count == 1)
    }
}

@MainActor
private final class CoordinatorFeedRepositorySpy: FeedRepository {
    var posts: [FeedPost] = []
    private(set) var fetchCount = 0

    func fetchPosts() async throws -> FeedLoadResult {
        self.fetchCount += 1
        await Task.yield()
        return FeedLoadResult(posts: self.posts, isStale: false)
    }
}
