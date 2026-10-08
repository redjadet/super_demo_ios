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
    @State private var navigation = AppNavigationStore.shared
    @Environment(\.scenePhase)
    private var scenePhase

    init(model: FeedFeatureModel, embedsOwnNavigation: Bool = true) {
        self.model = model
        self.embedsOwnNavigation = embedsOwnNavigation
    }

    var body: some View {
        @Bindable var navigation = self.navigation

        Group {
            if self.embedsOwnNavigation {
                FeedNavigationShell(
                    selectedPost: self.$selectedPost,
                    preferredCompactColumn: self.$preferredCompactColumn,
                    detail: { post in
                        FeedPostDetailView(post: post, model: self.model)
                    },
                    sidebar: {
                        self.content
                            .navigationTitle("Feed")
                            .iosInlineNavigationBarTitle()
                            #if !os(macOS)
                            .toolbar { self.feedToolbar }
                            #endif
                    }
                )
            } else {
                self.content
                    #if !os(macOS)
                    .toolbar { self.feedToolbar }
                    #endif
            }
        }
        #if os(macOS)
        .toolbar { self.feedToolbar }
        .focusedSceneValue(\.macRefresh) { self.model.refresh() }
        #endif
        .alert("Could Not Save Bookmark", isPresented: Binding(
            get: { self.model.bookmarkErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    self.model.dismissBookmarkError()
                }
            }
        )) {
            Button("OK") { self.model.dismissBookmarkError() }
        } message: {
            Text(self.model.bookmarkErrorMessage ?? "")
        }
        .task {
            // Engineering Stale Feed embeds `FeedView` with
            // `embedsOwnNavigation: false` — must not steal App Intent
            // registration from the live Feed tab model.
            if self.embedsOwnNavigation {
                FeedRefreshCoordinator.register(self.model)
            }
            self.model.startOutboxSync()
            await self.model.refreshAndWait()
            self.applyPendingFeedPostOpenIfPossible()
        }
        .onChange(of: self.scenePhase) { _, phase in
            if phase == .active {
                self.model.flushOutbox()
                self.model.reloadBookmarks()
            }
        }
        .onChange(of: navigation.state.feedOpenPostRequestID) { _, _ in
            self.applyPendingFeedPostOpenIfPossible()
        }
        .onChange(of: navigation.state.feedRefreshRequestID) { _, _ in
            guard self.embedsOwnNavigation else { return }
            FeedRefreshCoordinator.consumePendingRefreshIfNeeded(using: self.model)
        }
        .onChange(of: self.model.state) { _, newState in
            self.applyPendingFeedPostOpenIfPossible()
            self.clearUnresolvedFeedPostOpenIfNeeded(for: newState)
        }
        .onDisappear {
            if self.embedsOwnNavigation {
                FeedRefreshCoordinator.unregister(self.model)
            }
            self.model.cancelRefresh()
        }
    }

    /// Selects a pending post queued by App Intent / `superdemo://feed/<id>`.
    private func applyPendingFeedPostOpenIfPossible() {
        guard self.embedsOwnNavigation,
              let pendingID = AppNavigationStore.current.state.feedOpenPostID,
              case let .content(posts, _) = self.model.state,
              let post = posts.first(where: { $0.id == pendingID })
        else {
            return
        }
        self.selectedPost = post
        AppNavigationStore.current.clearPendingFeedPostOpen()
    }

    /// Drops a pending open once load is definitive and the id is missing
    /// (content without match, empty, or failed) so navigation cannot stall.
    private func clearUnresolvedFeedPostOpenIfNeeded(for state: FeedState) {
        guard self.embedsOwnNavigation else { return }
        switch state {
        case let .content(posts, _):
            AppNavigationStore.current.clearUnresolvedFeedPostOpenIfMissing(from: posts)
        case .empty, .failed:
            AppNavigationStore.current.clearUnresolvedFeedPostOpenOnDefinitiveMiss()
        case .loading:
            break
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
                .accessibilityIdentifier("feedLoading")
                .accessibilityLabel("Loading feed")
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
            // Contain children so `feedRetry` stays visible; count proves Retry
            // advanced a cycle (not a no-op tap on prior chrome).
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("feedFailed-\(self.model.completedRefreshCount)")
            .accessibilityLabel("Could not load feed")
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
                Label("Showing offline cache. Refresh when back online.", systemImage: "wifi.slash")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("feedStaleBanner")
            }
        }

        if self.model.failedOutboxCount > 0 {
            Section {
                Button {
                    self.model.retryFailedBookmarks()
                } label: {
                    Label(
                        "\(self.model.failedOutboxCount) bookmark sync failed. Tap to retry.",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("feedOutboxFailedBanner")
            }
        }

        ForEach(posts) { post in
            HStack(alignment: .top, spacing: 8) {
                Group {
                    if self.embedsOwnNavigation {
                        NavigationLink(value: post) {
                            self.postTextLabel(post)
                        }
                    } else {
                        NavigationLink {
                            FeedPostDetailView(post: post, model: self.model)
                        } label: {
                            self.postTextLabel(post)
                        }
                    }
                }
                .accessibilityIdentifier("feedPostRow-\(post.id)")

                FeedBookmarkButton(
                    bookmark: self.model.bookmark(for: post.id),
                    action: { self.model.toggleBookmark(for: post.id) },
                    onRetry: { self.model.retryFailedBookmarks(postID: post.id) }
                )
            }
            .tag(post)
        }
    }

    private func postTextLabel(_ post: FeedPost) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(post.title)
                .font(.headline)
                #if os(macOS)
                .foregroundStyle(self.selectedPost?.id == post
                    .id ? Color(nsColor: .alternateSelectedControlTextColor) : .primary)
                #endif
                .lineLimit(2)
            Text(post.body)
                .font(.subheadline)
                #if os(macOS)
                .foregroundStyle(self.selectedPost?.id == post
                    .id ? Color(nsColor: .alternateSelectedControlTextColor) : .secondary)
                #else
                .foregroundStyle(.secondary)
                #endif
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

#Preview("Feed — Mac", traits: UniversalPreviewLayouts.macWindow) {
    FeedPreviewFactory.view(seedPosts: FeedPreviewFactory.samplePosts)
}

#Preview("Feed — Mac (Dark)", traits: UniversalPreviewLayouts.macWindow) {
    FeedPreviewFactory.view(seedPosts: FeedPreviewFactory.samplePosts)
        .previewDarkAppearance()
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
