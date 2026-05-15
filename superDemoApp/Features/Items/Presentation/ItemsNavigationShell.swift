//
//  ItemsNavigationShell.swift
//  superDemoApp
//

import SwiftUI

/// Items feature navigation — delegates to shared adaptive split view.
struct ItemsNavigationShell<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        AdaptiveNavigationShell(sidebar: self.content) {
            Text("Select an item")
                .foregroundStyle(.secondary)
                .featureScreenFrame()
        }
    }
}
