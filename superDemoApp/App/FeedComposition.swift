//
//  FeedComposition.swift
//  superDemoApp
//

import SwiftData
import SwiftUI

enum FeedComposition {
    /// Holds an in-memory SwiftData stack so Engineering-demo stale UI
    /// does not mutate the live Feed tab cache.
    @MainActor
    final class StaleDemoSession {
        let container: ModelContainer
        let model: FeedFeatureModel

        init(container: ModelContainer, model: FeedFeatureModel) {
            self.container = container
            self.model = model
        }
    }

    @MainActor
    static func makeFeatureModel(context: ModelContext) -> FeedFeatureModel {
        if AppLaunchConfiguration.usesStaleFeedFixture {
            return self.makeStaleDemoFeatureModel(context: context)
        }

        let remote: any FeedRepository
        if AppLaunchConfiguration.usesFailingFeedFixture {
            remote = FailingSampleFeedRepository()
        } else if AppLaunchConfiguration.usesSeededSampleState {
            remote = SampleFeedRepository()
        } else {
            let client = LiveFeedAPIClient(session: AppURLSession.makeDefault())
            remote = RemoteFeedRepository(client: client)
        }
        // Live / review Feed path publishes App Group widget snapshot.
        // StaleFeedDemo / in-memory fixtures keep NoOp publisher (isolated).
        let repository = CachingFeedRepository(
            remote: remote,
            context: context,
            snapshotPublisher: WidgetKitFeedSnapshotPublisher()
        )
        return FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository),
            liveActivity: ActivityKitFeedRefreshLiveActivityController()
        )
    }

    /// Seeds a fresh cache and wires `FailingSampleFeedRepository` through
    /// `CachingFeedRepository` so the real stale banner path runs.
    /// Intentionally does **not** publish to the live App Group widget snapshot.
    /// Live Activity uses NoOp so Engineering demos do not start Island sessions.
    @MainActor
    static func makeStaleDemoFeatureModel(context: ModelContext) -> FeedFeatureModel {
        do {
            try ReviewerDemoFixtures.seedFeedCache(in: context)
        } catch {
            assertionFailure("Failed to seed stale Feed cache: \(error)")
        }
        let repository = CachingFeedRepository(
            remote: FailingSampleFeedRepository(),
            context: context,
            snapshotPublisher: NoOpFeedWidgetSnapshotPublisher()
        )
        return FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository),
            liveActivity: NoOpFeedRefreshLiveActivityController()
        )
    }

    @MainActor
    static func makeStaleDemoSession() -> StaleDemoSession {
        do {
            let schema = Schema([CachedFeedPost.self])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            let model = self.makeStaleDemoFeatureModel(context: context)
            return StaleDemoSession(container: container, model: model)
        } catch {
            preconditionFailure("Unable to create stale Feed demo session: \(error)")
        }
    }
}

struct FeedRootView: View {
    @Environment(\.modelContext)
    private var modelContext

    var body: some View {
        FeedRootContent(context: self.modelContext)
    }
}

private struct FeedRootContent: View {
    @State private var model: FeedFeatureModel

    init(context: ModelContext) {
        self._model = State(initialValue: FeedComposition.makeFeatureModel(context: context))
    }

    var body: some View {
        FeedView(model: self.model)
    }
}

/// Engineering-demo entry that shows the Feed stale banner without a relaunch.
struct StaleFeedDemoView: View {
    private let session: FeedComposition.StaleDemoSession

    init(session: FeedComposition.StaleDemoSession) {
        self.session = session
    }

    var body: some View {
        // Push onto Production Readiness's stack. Own `NavigationSplitView` /
        // nested `NavigationStack` here made list taps and a11y ids no-op.
        FeedView(model: self.session.model, embedsOwnNavigation: false)
            .navigationTitle("Stale Feed")
            .iosInlineNavigationBarTitle()
            .accessibilityIdentifier("staleFeedDemoScreen")
    }
}
