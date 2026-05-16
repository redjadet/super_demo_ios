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
        FeedView(model: FeedComposition.makeFeatureModel(context: self.modelContext))
    }
}
