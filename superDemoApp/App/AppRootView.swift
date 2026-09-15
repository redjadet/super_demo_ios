//
//  AppRootView.swift
//  superDemoApp
//

import SwiftUI

struct AppRootView: View {
    @State private var navigation = AppNavigationStore.shared

    var body: some View {
        @Bindable var navigation = self.navigation

        TabView(selection: $navigation.state.selection) {
            Tab("Dashboard", systemImage: "checklist.checked", value: AppTab.dashboard) {
                ProductionReadinessRootView(path: $navigation.state.dashboardPath)
            }
            .accessibilityIdentifier("dashboardTab")

            Tab("Items", systemImage: "list.bullet", value: AppTab.items) {
                ItemsRootView()
            }
            .accessibilityIdentifier("itemsTab")

            Tab("Feed", systemImage: "text.bubble", value: AppTab.feed) {
                FeedRootView()
            }
            .accessibilityIdentifier("feedTab")
        }
        .tabBarMinimizeBehavior(.automatic)
        .onOpenURL { url in
            self.navigation.handle(url: url)
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            guard let url = activity.webpageURL else { return }
            self.navigation.handle(url: url)
        }
        .alert("Link Not Available", isPresented: self.invalidDeepLinkPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(self.navigation.state.invalidDeepLinkMessage ?? "")
        }
    }

    private var invalidDeepLinkPresented: Binding<Bool> {
        Binding {
            self.navigation.state.invalidDeepLinkMessage != nil
        } set: { isPresented in
            if !isPresented {
                self.navigation.state.invalidDeepLinkMessage = nil
            }
        }
    }
}
