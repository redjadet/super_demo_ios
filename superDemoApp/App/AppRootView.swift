//
//  AppRootView.swift
//  superDemoApp
//

import SwiftUI

struct AppRootView: View {
    @State private var navigation = AppNavigationState()

    var body: some View {
        TabView(selection: self.$navigation.selection) {
            ProductionReadinessRootView(path: self.$navigation.dashboardPath)
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
        .onOpenURL { url in
            self.navigation.handle(url: url)
        }
        .alert("Link Not Available", isPresented: self.invalidDeepLinkPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(self.navigation.invalidDeepLinkMessage ?? "")
        }
    }

    private var invalidDeepLinkPresented: Binding<Bool> {
        Binding {
            self.navigation.invalidDeepLinkMessage != nil
        } set: { isPresented in
            if !isPresented {
                self.navigation.invalidDeepLinkMessage = nil
            }
        }
    }
}
