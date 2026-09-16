//
//  FeedFeatureModelTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@MainActor
private final class FeedModelRepositorySpy: FeedRepository {
    var posts: [FeedPost] = []
    var isStale = false
    var delayNanoseconds: UInt64 = 0
    var error: Error?

    func fetchPosts() async throws -> FeedLoadResult {
        if self.delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: self.delayNanoseconds)
        } else {
            await Task.yield()
        }
        if let error {
            throw error
        }
        return FeedLoadResult(posts: self.posts, isStale: self.isStale)
    }
}

private final class RecordingDiagnostics: ReleaseDiagnosticsReporting, @unchecked Sendable {
    private let lock = NSLock()
    private var recordedFailedChecks: [(name: String, reason: String)] = []

    var failedChecks: [(name: String, reason: String)] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.recordedFailedChecks
    }

    func releaseCheckPassed(_: ReleaseDiagnosticCheck) { /* no-op */ }

    func releaseCheckFailed(_ check: ReleaseDiagnosticCheck, reason: String) {
        self.lock.lock()
        self.recordedFailedChecks.append((check.name, reason))
        self.lock.unlock()
    }

    func deviceOnlyFailure(_: DeviceOnlyFailure) { /* no-op */ }
}

@Suite("Feed feature model")
struct FeedFeatureModelTests {
    @Test
    @MainActor
    func refreshShowsEmptyForNoPosts() async {
        let repository = FeedModelRepositorySpy()
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository)
        )

        await model.refreshAndWait()

        #expect(model.state == .empty)
    }

    @Test
    @MainActor
    func refreshShowsContent() async {
        let repository = FeedModelRepositorySpy()
        repository.posts = [FeedPost(id: 1, userID: 1, title: "A", body: "B")]
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository)
        )

        await model.refreshAndWait()

        if case let .content(posts, isStale) = model.state {
            #expect(posts.count == 1)
            #expect(isStale == false)
        } else {
            Issue.record("Expected content state")
        }
    }

    @Test
    @MainActor
    func refreshShowsStaleContentAndRecordsDiagnostic() async {
        let repository = FeedModelRepositorySpy()
        repository.posts = [FeedPost(id: 1, userID: 1, title: "A", body: "B")]
        repository.isStale = true
        let diagnostics = RecordingDiagnostics()
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository),
            diagnostics: diagnostics
        )

        await model.refreshAndWait()

        if case let .content(posts, isStale) = model.state {
            #expect(posts.count == 1)
            #expect(isStale)
        } else {
            Issue.record("Expected stale content state")
        }
        #expect(diagnostics.failedChecks.map(\.name) == ["feed-cache-fallback"])
    }

    @Test
    @MainActor
    func refreshFailureRecordsDiagnostic() async {
        let repository = FeedModelRepositorySpy()
        repository.error = FeedError.invalidResponse
        let diagnostics = RecordingDiagnostics()
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository),
            diagnostics: diagnostics
        )

        await model.refreshAndWait()

        if case .failed = model.state {
            #expect(diagnostics.failedChecks.map(\.name) == ["feed-refresh"])
        } else {
            Issue.record("Expected failed state")
        }
    }

    @Test
    @MainActor
    func cancelRefreshRestoresPriorContent() async {
        let repository = FeedModelRepositorySpy()
        repository.posts = [FeedPost(id: 1, userID: 1, title: "A", body: "B")]
        repository.delayNanoseconds = 500_000_000
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository)
        )
        await model.refreshAndWait()

        model.refresh()
        try? await Task.sleep(nanoseconds: 50_000_000)
        model.cancelRefresh()

        if case let .content(posts, _) = model.state {
            #expect(posts.count == 1)
        } else {
            Issue.record("Expected restored content after cancel")
        }
    }

    @Test
    @MainActor
    func refreshKeepsExistingContentVisible() async {
        let repository = FeedModelRepositorySpy()
        repository.posts = [FeedPost(id: 1, userID: 1, title: "A", body: "B")]
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository)
        )
        await model.refreshAndWait()

        repository.delayNanoseconds = 500_000_000
        model.refresh()
        try? await Task.sleep(nanoseconds: 50_000_000)

        if case let .content(posts, _) = model.state {
            #expect(posts.count == 1)
        } else {
            Issue.record("Expected existing content to remain visible during refresh")
        }

        model.cancelRefresh()
    }
}
