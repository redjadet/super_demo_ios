//
//  FeedComposition.swift
//  superDemoApp
//

import SwiftData
import SwiftUI

enum FeedComposition {
    @MainActor
    static func makeFeatureModel(context: ModelContext) -> FeedFeatureModel {
        let client = LiveFeedAPIClient()
        let remote = RemoteFeedRepository(client: client)
        let repository = CachingFeedRepository(remote: remote, context: context)
        return FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository)
        )
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
