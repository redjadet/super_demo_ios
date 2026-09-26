//
//  FeedView.swift
//  superDemoApp
//

import SwiftUI

struct FeedView: View {
    @Bindable private var model: FeedFeatureModel
    /// When `false`, list rows push onto an enclosing `NavigationStack`
    /// (e.g. Engineering "Stale Feed" demo). When `true`, owns a split view.
    private let embedsOwnNavigation: Bool

    @State private var selectedPost: FeedPost?
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar

    init(model: FeedFeatureModel, embedsOwnNavigation: Bool = true) {
        self.model = model
        self.embedsOwnNavigation = embedsOwnNavigation
    }

    var body: some View {
        Group {
            if self.embedsOwnNavigation {
                FeedNavigationShell(
                    selectedPost: self.$selectedPost,
                    preferredCompactColumn: self.$preferredCompactColumn
                ) {
                    self.content
                        .navigationTitle("Feed")
                        .iosInlineNavigationBarTitle()
                        .toolbar {
                            self.feedToolbar
                        }
                }
            } else {
                self.content
                    .toolbar {
                        self.feedToolbar
                    }
            }
        }
        .task {
            FeedRefreshCoordinator.register(self.model)
            await self.model.refreshAndWait()
        }
        .onDisappear {
            FeedRefreshCoordinator.unregister(self.model)
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
            .chromeGlassButtonStyle()
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
                .chromeGlassButtonStyle()
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
                .chromeGlassButtonStyle()
                .accessibilityIdentifier("refreshFeedEmpty")
            }
            .featureScreenFrame()
        case let .content(posts, isStale):
            self.postsList(posts, isStale: isStale)
        }
    }

    @ViewBuilder
    private func postsList(_ posts: [FeedPost], isStale: Bool) -> some View {
        // Split-owned Feed uses `List(selection:)` so taps update the detail column.
        // When pushed onto an outer `NavigationStack` (Stale Feed demo), a selection
        // binding swallows value links — use a plain `List` + `navigationDestination`.
        if self.embedsOwnNavigation {
            List(selection: self.$selectedPost) {
                self.postsListContent(posts, isStale: isStale)
            }
            .refreshable {
                await self.model.refreshAndWait()
            }
            .featureSidebarColumnWidth()
            .accessibilityIdentifier("feedList")
        } else {
            List {
                self.postsListContent(posts, isStale: isStale)
            }
            .refreshable {
                await self.model.refreshAndWait()
            }
            .accessibilityIdentifier("feedList")
        }
    }

    @ViewBuilder
    private func postsListContent(_ posts: [FeedPost], isStale: Bool) -> some View {
        if isStale {
            Section {
                Label("Showing offline cache. Pull to refresh when back online.", systemImage: "wifi.slash")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("feedStaleBanner")
            }
        }

        ForEach(posts) { post in
            Group {
                if self.embedsOwnNavigation {
                    NavigationLink(value: post) {
                        self.postRowLabel(post)
                    }
                } else {
                    NavigationLink {
                        FeedPostDetailView(post: post)
                    } label: {
                        self.postRowLabel(post)
                    }
                }
            }
            .accessibilityIdentifier("feedPostRow-\(post.id)")
            .tag(post)
        }
    }

    private func postRowLabel(_ post: FeedPost) -> some View {
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

#Preview("Feed — Stale", traits: UniversalPreviewLayouts.iPhonePortrait) {
    FeedPreviewFactory.staleView(seedPosts: FeedPreviewFactory.samplePosts)
}

@MainActor
private enum FeedPreviewFactory {
    static let samplePosts = [
        FeedPost(
            id: 1,
            userID: 1,
            title: String(localized: "Preview title"),
            body: String(localized: "Preview body text.")
        ),
    ]

    static func view(seedPosts: [FeedPost]) -> some View {
        let repository = PreviewFeedRepository(seedPosts: seedPosts, isStale: false)
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository)
        )
        return FeedView(model: model)
    }

    static func staleView(seedPosts: [FeedPost]) -> some View {
        let repository = PreviewFeedRepository(seedPosts: seedPosts, isStale: true)
        let model = FeedFeatureModel(
            refreshFeed: RefreshFeedUseCase(repository: repository)
        )
        return FeedView(model: model)
    }
}

@MainActor
private final class PreviewFeedRepository: FeedRepository {
    private var posts: [FeedPost]
    private let isStale: Bool

    init(seedPosts: [FeedPost], isStale: Bool) {
        self.posts = seedPosts
        self.isStale = isStale
    }

    func fetchPosts() async throws -> FeedLoadResult {
        await Task.yield()
        return FeedLoadResult(posts: self.posts, isStale: self.isStale)
    }
}
