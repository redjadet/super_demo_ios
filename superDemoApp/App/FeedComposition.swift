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
        let repository = CachingFeedRepository(remote: remote, context: context)
        return FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository)
        )
    }

    /// Seeds a fresh cache and wires `FailingSampleFeedRepository` through
    /// `CachingFeedRepository` so the real stale banner path runs.
    @MainActor
    static func makeStaleDemoFeatureModel(context: ModelContext) -> FeedFeatureModel {
        do {
            try ReviewerDemoFixtures.seedFeedCache(in: context)
        } catch {
            assertionFailure("Failed to seed stale Feed cache: \(error)")
        }
        let repository = CachingFeedRepository(
            remote: FailingSampleFeedRepository(),
            context: context
        )
        return FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository)
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

    init(session: FeedComposition.StaleDemoSession = FeedComposition.makeStaleDemoSession()) {
        self.session = session
    }

    var body: some View {
        FeedView(model: self.session.model)
            .navigationTitle("Stale Feed")
            .accessibilityIdentifier("staleFeedDemoScreen")
    }
}
