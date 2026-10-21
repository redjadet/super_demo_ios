//
//  AppRootView.swift
//  superDemoApp
//

import SwiftUI

struct AppRootView: View {
    @State private var navigation = AppNavigationStore.shared
    #if os(macOS)
    @AppStorage("macAppearance")
    private var appearance = MacAppearance.system.rawValue
    #endif

    var body: some View {
        @Bindable var navigation = self.navigation

        TabView(selection: $navigation.state.selection) {
            Tab("Dashboard", systemImage: "checklist.checked", value: AppTab.dashboard) {
                ProductionReadinessRootView(path: $navigation.state.dashboardPath)
            }
            .accessibilityIdentifier("dashboardTab")
            .accessibilityLabel("Dashboard")

            Tab("Items", systemImage: "list.bullet", value: AppTab.items) {
                ItemsRootView()
            }
            .accessibilityIdentifier("itemsTab")
            .accessibilityLabel("Items")

            Tab("Feed", systemImage: "text.bubble", value: AppTab.feed) {
                FeedRootView()
            }
            .accessibilityIdentifier("feedTab")
            .accessibilityLabel("Feed")
        }
        .tabBarMinimizeBehavior(.automatic)
        #if os(macOS)
        .focusedSceneValue(\.macSelectedTab, $navigation.state.selection)
        .preferredColorScheme(MacAppearance(rawValue: self.appearance)?.colorScheme)
        #endif
        .onOpenURL { url in
            self.navigation.handle(url: url)
        }
        .task {
            // After the root scene exists. `TabView` can still write the first
            // tab back into `selection` in that same turn, so correct again
            // on the next turn and whenever selection drifts.
            self.applyUITestLaunchDeepLinkIfNeeded()
            Task { @MainActor in
                self.applyUITestLaunchDeepLinkIfNeeded()
            }
        }
        .onChange(of: navigation.state.selection) { _, _ in
            self.applyUITestLaunchDeepLinkIfNeeded()
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            guard let url = activity.webpageURL else { return }
            self.navigation.handle(url: url)
        }
        .alert("Link Not Available", isPresented: self.invalidDeepLinkPresented) {
            Button("OK", role: .cancel) { /* dismiss */ }
        } message: {
            Text(self.navigation.state.invalidDeepLinkMessage ?? "")
        }
    }

    /// Re-applies `-UITestOpenURL` until the tab matches.
    ///
    /// A launch-time write is not enough: `TabView` can reset `selection` to
    /// Dashboard after the first frame. Local probe 2 of
    /// `testDeepLinkOpensFeedPostDetail` stayed on `productionReadinessDashboard`
    /// for the full 30s wait (`row=false list=false loading=false`).
    private func applyUITestLaunchDeepLinkIfNeeded() {
        guard AppLaunchConfiguration.isUITesting,
              let url = AppLaunchConfiguration.uiTestOpenURL,
              let link = AppDeepLink(url: url)
        else {
            return
        }
        guard self.navigation.state.selection != link.tab else {
            if case let .feedPost(id) = link, self.navigation.state.feedOpenPostID != id {
                self.navigation.requestOpenFeedPost(id: id)
            }
            return
        }
        self.navigation.handle(url: url)
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
