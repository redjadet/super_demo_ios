//
//  FeedView.swift
//  superDemoApp
//

import SwiftUI

struct FeedView: View {
    @Bindable private var model: FeedFeatureModel

    init(model: FeedFeatureModel) {
        self.model = model
    }

    var body: some View {
        FeedNavigationShell {
            self.content
        }
        .toolbar {
            self.feedToolbar
        }
        .task {
            await self.model.refreshAndWait()
        }
        .onDisappear {
            self.model.cancelRefresh()
        }
    }

    @ToolbarContentBuilder private var feedToolbar: some ToolbarContent {
        ToolbarItem {
            Button {
                self.model.refresh()
            } label: {
                Label("Refresh Feed", systemImage: "arrow.clockwise")
            }
            .accessibilityIdentifier("refreshFeed")
        }
    }

    @ViewBuilder private var content: some View {
        switch self.model.state {
        case .loading:
            ProgressView()
                .featureScreenFrame()
        case let .failed(error):
            ContentUnavailableView {
                Label("Could Not Load Feed", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.message)
            } actions: {
                Button("Retry") {
                    self.model.refresh()
                }
                .accessibilityIdentifier("feedRetry")
            }
            .featureScreenFrame()
        case .empty:
            ContentUnavailableView {
                Label("No Posts", systemImage: "text.bubble")
            } actions: {
                Button("Refresh") {
                    self.model.refresh()
                }
                .accessibilityIdentifier("refreshFeed")
            }
            .featureScreenFrame()
        case let .content(posts):
            self.postsList(posts)
        }
    }

    private func postsList(_ posts: [FeedPost]) -> some View {
        List(posts) { post in
            NavigationLink {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(post.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(post.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .navigationTitle("Post")
                #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                #endif
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(post.body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(post.title). \(post.body)")
            }
        }
        .featureSidebarColumnWidth()
        .accessibilityIdentifier("feedList")
    }
}

#Preview("Feed — iPhone", traits: UniversalPreviewLayouts.iPhonePortrait) {
    FeedPreviewFactory.view(seedPosts: FeedPreviewFactory.samplePosts)
}

#Preview("Feed — iPhone (Dark)", traits: UniversalPreviewLayouts.iPhonePortrait) {
    FeedPreviewFactory.view(seedPosts: FeedPreviewFactory.samplePosts)
        .previewDarkAppearance()
}

#Preview("Feed — Empty", traits: UniversalPreviewLayouts.iPhonePortrait) {
    FeedPreviewFactory.view(seedPosts: [])
}

@MainActor
private enum FeedPreviewFactory {
    static let samplePosts = [
        FeedPost(id: 1, userID: 1, title: "Preview title", body: "Preview body text."),
    ]

    static func view(seedPosts: [FeedPost]) -> some View {
        let repository = PreviewFeedRepository(seedPosts: seedPosts)
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository)
        )
        return FeedView(model: model)
            .task {
                await model.refreshAndWait()
            }
    }
}

@MainActor
private final class PreviewFeedRepository: FeedRepository {
    private var posts: [FeedPost]

    init(seedPosts: [FeedPost]) {
        self.posts = seedPosts
    }

    func fetchPosts() async throws -> [FeedPost] {
        await Task.yield()
        return self.posts
    }
}
