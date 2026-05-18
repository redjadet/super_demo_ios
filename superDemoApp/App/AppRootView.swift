//
//  AppRootView.swift
//  superDemoApp
//

import SwiftUI

private enum AppTab: Hashable {
    case dashboard
    case items
    case feed
}

struct AppRootView: View {
    @State private var selection: AppTab = .dashboard

    var body: some View {
        TabView(selection: self.$selection) {
            ProductionReadinessRootView()
                .tabItem {
                    Label("Dashboard", systemImage: "checklist.checked")
                }
                .tag(AppTab.dashboard)
                .accessibilityIdentifier("dashboardTab")

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
