//
//  AdaptiveNavigationShell.swift
//  superDemoApp
//

import SwiftUI

/// Sidebar/detail navigation that adapts across iPhone, iPad, and Mac.
/// Uses `NavigationSplitView` so compact widths collapse to a single column automatically.
struct AdaptiveNavigationShell<Sidebar: View, Detail: View>: View {
    @ViewBuilder var sidebar: () -> Sidebar
    @ViewBuilder var detail: () -> Detail

    var body: some View {
        NavigationSplitView {
            self.sidebar()
        } detail: {
            self.detail()
        }
    }
}

extension View {
    /// Centers loading, empty, and error content in large iPad/Mac windows.
    func featureScreenFrame() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Preferred sidebar width on regular-width iPad and Mac split views.
    func featureSidebarColumnWidth(
        min: CGFloat = 180,
        ideal: CGFloat = 220,
        max: CGFloat = 320
    ) -> some View {
        #if os(macOS)
        self.navigationSplitViewColumnWidth(min: min, ideal: ideal, max: max)
        #else
        self.modifier(FeatureSidebarColumnWidthModifier(min: min, ideal: ideal, max: max))
        #endif
    }
}

#if os(iOS)
private struct FeatureSidebarColumnWidthModifier: ViewModifier {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    let min: CGFloat
    let ideal: CGFloat
    let max: CGFloat

    func body(content: Content) -> some View {
        if self.horizontalSizeClass == .regular {
            content.navigationSplitViewColumnWidth(min: self.min, ideal: self.ideal, max: self.max)
        } else {
            content
        }
    }
}
#endif
