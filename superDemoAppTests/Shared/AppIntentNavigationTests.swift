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
        let links: [AppDeepLink] = [
            .dashboard,
            .productionRisks,
            .items,
            .feed,
            .feedPost(id: 1),
        ]

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
    func openFeedPostIntentQueuesPostIDAndOpensFeed() async throws {
        let store = AppNavigationStore()
        AppNavigationStore.testingOverride = store
        defer { AppNavigationStore.testingOverride = nil }

        store.state.selection = .items
        let intent = OpenFeedPostIntent()
        intent.postID = 1
        _ = try await intent.perform()

        #expect(store.state.selection == .feed)
        #expect(store.state.feedOpenPostID == 1)
        #expect(store.state.feedOpenPostRequestID == 1)
    }

    @Test
    func requestOpenFeedPostSetsPendingID() {
        var state = AppNavigationState(selection: .dashboard)

        state.requestOpenFeedPost(id: 42)

        #expect(state.selection == .feed)
        #expect(state.feedOpenPostID == 42)
        #expect(state.feedOpenPostRequestID == 1)
    }

    @Test
    @MainActor
    func feedRefreshCoordinatorRefreshesRegisteredModel() async {
        FeedRefreshCoordinator.resetForTesting()
        defer { FeedRefreshCoordinator.resetForTesting() }

        let store = AppNavigationStore()
        AppNavigationStore.testingOverride = store
        defer { AppNavigationStore.testingOverride = nil }

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

        #expect(store.state.selection != .feed || store.state.feedRefreshRequestID >= 1)
        #expect(repository.fetchCount >= 1)
        guard case let .content(posts, _) = model.state else {
            Issue.record("Expected content after coordinator refresh, got \(model.state)")
            return
        }
        #expect(posts.count == 1)
    }

    @Test
    @MainActor
    func feedRefreshCoordinatorConsumesPendingWhenModelRemounts() async {
        FeedRefreshCoordinator.resetForTesting()
        defer { FeedRefreshCoordinator.resetForTesting() }

        let store = AppNavigationStore()
        AppNavigationStore.testingOverride = store
        defer { AppNavigationStore.testingOverride = nil }

        // Unmounted Feed: request with openFeedTab=false must queue, not drop.
        FeedRefreshCoordinator.requestRefresh(openFeedTab: false)
        #expect(store.state.selection != .feed)
        #expect(store.state.feedRefreshRequestID == 1)

        let repository = CoordinatorFeedRepositorySpy()
        repository.posts = [FeedPost(id: 7, userID: 1, title: "Queued", body: "B")]
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository)
        )
        FeedRefreshCoordinator.register(model)
        defer { FeedRefreshCoordinator.unregister(model) }

        for _ in 0 ..< 100 where repository.fetchCount == 0 {
            await Task.yield()
        }
        #expect(repository.fetchCount >= 1)
    }

    /// Stale Feed Engineering demo must not register — an unregistered demo
    /// model must not receive App Intent refresh while the live tab is active.
    @Test
    @MainActor
    func feedRefreshCoordinatorIgnoresUnregisteredDemoModel() async {
        FeedRefreshCoordinator.resetForTesting()
        defer { FeedRefreshCoordinator.resetForTesting() }

        let store = AppNavigationStore()
        AppNavigationStore.testingOverride = store
        defer { AppNavigationStore.testingOverride = nil }

        let liveRepository = CoordinatorFeedRepositorySpy()
        liveRepository.posts = [FeedPost(id: 1, userID: 1, title: "Live", body: "B")]
        let liveModel = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: liveRepository)
        )
        FeedRefreshCoordinator.register(liveModel)
        defer { FeedRefreshCoordinator.unregister(liveModel) }

        let demoRepository = CoordinatorFeedRepositorySpy()
        demoRepository.posts = [FeedPost(id: 99, userID: 1, title: "Demo", body: "B")]
        let demoModel = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: demoRepository)
        )
        // Intentionally do **not** register demoModel (StaleFeedDemoView contract).

        let liveBefore = liveRepository.fetchCount
        FeedRefreshCoordinator.requestRefresh(openFeedTab: false)

        for _ in 0 ..< 100 where liveRepository.fetchCount == liveBefore {
            await Task.yield()
        }

        #expect(liveRepository.fetchCount > liveBefore)
        #expect(demoRepository.fetchCount == 0)
        // Demo model must not receive App Intent refresh content.
        if case .content = demoModel.state {
            Issue.record("Unregistered Stale Feed demo model was refreshed by App Intent")
        }
    }

    @Test
    func clearPendingFeedPostOpenClearsID() {
        var state = AppNavigationState()
        state.requestOpenFeedPost(id: 99)
        state.clearPendingFeedPostOpen()
        #expect(state.feedOpenPostID == nil)
    }

    @Test
    func clearUnresolvedFeedPostOpenDropsMissingIDAfterDefinitiveLoad() {
        var state = AppNavigationState()
        state.requestOpenFeedPost(id: 42)

        state.clearUnresolvedFeedPostOpenIfMissing(
            from: [FeedPost(id: 1, userID: 1, title: "A", body: "B")]
        )
        #expect(state.feedOpenPostID == nil)

        state.requestOpenFeedPost(id: 1)
        state.clearUnresolvedFeedPostOpenIfMissing(
            from: [FeedPost(id: 1, userID: 1, title: "A", body: "B")]
        )
        #expect(state.feedOpenPostID == 1)

        state.requestOpenFeedPost(id: 7)
        state.clearUnresolvedFeedPostOpenOnDefinitiveMiss()
        #expect(state.feedOpenPostID == nil)
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
