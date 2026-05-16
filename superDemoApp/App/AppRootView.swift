//
//  AppRootView.swift
//  superDemoApp
//

import SwiftUI

private enum AppTab: Hashable {
    case items
    case feed
}

struct AppRootView: View {
    @State private var selection: AppTab = .items

    var body: some View {
        TabView(selection: self.$selection) {
            ItemsRootView()
                .tabItem {
                    Label("Items", systemImage: "list.bullet")
                }
                .tag(AppTab.items)
                .accessibilityIdentifier("itemsTab")

            FeedRootView()
                .tabItem {
                    Label("Feed", systemImage: "text.bubble")
                }
                .tag(AppTab.feed)
                .accessibilityIdentifier("feedTab")
        }
    }
}
