//
//  FeedNavigationShell.swift
//  superDemoApp
//

import SwiftUI

struct FeedNavigationShell<Sidebar: View, Detail: View>: View {
    @Binding private var selectedPost: FeedPost?
    @Binding private var preferredCompactColumn: NavigationSplitViewColumn
    @ViewBuilder private var sidebar: () -> Sidebar
    @ViewBuilder private var detail: (FeedPost) -> Detail

    init(
        selectedPost: Binding<FeedPost?>,
        preferredCompactColumn: Binding<NavigationSplitViewColumn>,
        @ViewBuilder detail: @escaping (FeedPost) -> Detail,
        @ViewBuilder sidebar: @escaping () -> Sidebar
    ) {
        self._selectedPost = selectedPost
        self._preferredCompactColumn = preferredCompactColumn
        self.detail = detail
        self.sidebar = sidebar
    }

    var body: some View {
        AdaptiveNavigationShell(preferredCompactColumn: self.$preferredCompactColumn) {
            self.sidebar()
        } detail: {
            if let selectedPost {
                self.detail(selectedPost)
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
