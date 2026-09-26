//
//  FeedNavigationShell.swift
//  superDemoApp
//

import SwiftUI

struct FeedNavigationShell<Sidebar: View>: View {
    @Binding private var selectedPost: FeedPost?
    @Binding private var preferredCompactColumn: NavigationSplitViewColumn
    @ViewBuilder private var sidebar: () -> Sidebar

    init(
        selectedPost: Binding<FeedPost?>,
        preferredCompactColumn: Binding<NavigationSplitViewColumn>,
        @ViewBuilder sidebar: @escaping () -> Sidebar
    ) {
        self._selectedPost = selectedPost
        self._preferredCompactColumn = preferredCompactColumn
        self.sidebar = sidebar
    }

    var body: some View {
        AdaptiveNavigationShell(preferredCompactColumn: self.$preferredCompactColumn) {
            self.sidebar()
        } detail: {
            if let selectedPost {
                FeedPostDetailView(post: selectedPost)
            } else {
                Text("Select a post")
                    .foregroundStyle(.secondary)
                    .featureScreenFrame()
            }
        }
        .onChange(of: self.selectedPost) { _, newValue in
            if newValue != nil {
                self.preferredCompactColumn = .detail
            }
        }
    }
}
