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
        // The Feed widget is embedded only in the iOS host. Native Mac Feed
        // must not coordinate writes into an unsupported widget App Group.
        let snapshotPublisher: any FeedWidgetSnapshotPublishing
        #if os(iOS)
        snapshotPublisher = WidgetKitFeedSnapshotPublisher()
        #else
        snapshotPublisher = NoOpFeedWidgetSnapshotPublisher()
        #endif
        let repository = CachingFeedRepository(
            remote: remote,
            context: context,
            snapshotPublisher: snapshotPublisher
        )

        let bookmarkStack = self.makeBookmarkStack(context: context)
        return FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository),
            toggleBookmark: ToggleBookmarkUseCase(repository: bookmarkStack.repository),
            retryBookmarkSync: RetryBookmarkSyncUseCase(repository: bookmarkStack.repository),
            bookmarkRepository: bookmarkStack.repository,
            syncEngine: bookmarkStack.engine,
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
        let bookmarkStack = self.makeBookmarkStack(context: context, forceOffline: true)
        return FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository),
            toggleBookmark: ToggleBookmarkUseCase(repository: bookmarkStack.repository),
            retryBookmarkSync: RetryBookmarkSyncUseCase(repository: bookmarkStack.repository),
            bookmarkRepository: bookmarkStack.repository,
            syncEngine: bookmarkStack.engine,
            liveActivity: NoOpFeedRefreshLiveActivityController()
        )
    }

    @MainActor
    static func makeStaleDemoSession() -> StaleDemoSession {
        do {
            let schema = Schema([
                CachedFeedPost.self,
                BookmarkedPost.self,
                OutboxEntry.self,
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            let model = self.makeStaleDemoFeatureModel(context: context)
            return StaleDemoSession(container: container, model: model)
        } catch {
            preconditionFailure("Unable to create stale Feed demo session: \(error)")
        }
    }

    @MainActor
    private struct BookmarkStack {
        let repository: SwiftDataBookmarkRepository
        let engine: OutboxSyncEngine
    }

    @MainActor
    private static func makeBookmarkStack(
        context: ModelContext,
        forceOffline: Bool = false
    ) -> BookmarkStack {
        let outbox = SwiftDataOutboxStore(context: context)
        let connectivity: ConnectivityMonitoring
        if AppLaunchConfiguration.usesOfflineBookmarkFixture || forceOffline {
            connectivity = ManualConnectivityMonitor(isConnected: false)
        } else if AppLaunchConfiguration.usesSeededSampleState {
            connectivity = ManualConnectivityMonitor(isConnected: true)
        } else {
            connectivity = NWPathConnectivityMonitor()
        }

        let remote: BookmarkRemoteClient
        if AppLaunchConfiguration.usesSeededSampleState || AppLaunchConfiguration.usesOfflineBookmarkFixture {
            remote = ImmediateSuccessBookmarkRemoteClient()
        } else {
            let apiClient = URLSessionAPIClient(
                session: AppURLSession.makeDefault(),
                retryPolicy: RetryPolicy(maxAttempts: 1),
                tokenRefresher: TokenRefreshingFactory.makeDefault()
            )
            remote = JSONPlaceholderBookmarkRemoteClient(client: apiClient)
        }

        let engineHolder = SyncEngineHolder()
        // Local binding (not trailing closure): Swift 6 TrailingClosureMatching
        // rejects unlabeled trailing match of optional `onEnqueued`, while
        // SwiftLint trailing_closure rejects a labeled trailing-form call.
        let onEnqueued: @Sendable () -> Void = {
            Task {
                if let engine = await engineHolder.engine {
                    await engine.requestFlush()
                }
            }
        }
        let repository = SwiftDataBookmarkRepository(
            context: context,
            outbox: outbox,
            onEnqueued: onEnqueued
        )
        let engine = OutboxSyncEngine(
            outbox: OutboxStoreBox(outbox),
            remote: remote,
            bookmarkMutator: BookmarkLocalMutatorBox(repository),
            connectivity: connectivity
        )
        Task { await engineHolder.setEngine(engine) }

        return BookmarkStack(repository: repository, engine: engine)
    }
}

/// Tiny holder so enqueue can flush after the engine exists.
private actor SyncEngineHolder {
    /// The model owns the engine; retaining it here would cycle through the
    /// repository enqueue callback back to this holder.
    weak var engine: OutboxSyncEngine?

    func setEngine(_ engine: OutboxSyncEngine) {
        self.engine = engine
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
        // `embedsOwnNavigation: false` also skips `FeedRefreshCoordinator`
        // registration so App Intents keep targeting the live Feed tab.
        FeedView(model: self.session.model, embedsOwnNavigation: false)
            .navigationTitle("Stale Feed")
            .iosInlineNavigationBarTitle()
            .accessibilityIdentifier("staleFeedDemoScreen")
    }
}
