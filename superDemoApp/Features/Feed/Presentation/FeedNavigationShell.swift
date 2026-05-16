//
//  FeedNavigationShell.swift
//  superDemoApp
//

import SwiftUI

struct FeedNavigationShell<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        AdaptiveNavigationShell(sidebar: self.content) {
            Text("Select a post")
                .foregroundStyle(.secondary)
                .featureScreenFrame()
        }
    }
}
