//
//  AdaptiveNavigationShell.swift
//  superDemoApp
//

import SwiftUI

/// Sidebar/detail navigation that adapts across iPhone, iPad, and Mac.
/// Uses `NavigationSplitView` so compact widths collapse to a single column automatically.
///
/// Prefer `List(selection:)` + `NavigationLink(value:)` in the sidebar and drive the
/// detail from that selection. Destination-only `NavigationLink { View }` links inside
/// a split (especially nested under another stack) often appear to do nothing.
struct AdaptiveNavigationShell<Sidebar: View, Detail: View>: View {
    @Binding private var preferredCompactColumn: NavigationSplitViewColumn
    @ViewBuilder private var sidebar: () -> Sidebar
    @ViewBuilder private var detail: () -> Detail

    init(
        preferredCompactColumn: Binding<NavigationSplitViewColumn> = .constant(.sidebar),
        @ViewBuilder sidebar: @escaping () -> Sidebar,
        @ViewBuilder detail: @escaping () -> Detail
    ) {
        self._preferredCompactColumn = preferredCompactColumn
        self.sidebar = sidebar
        self.detail = detail
    }

    var body: some View {
        NavigationSplitView(preferredCompactColumn: self.$preferredCompactColumn) {
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

    /// iOS-only inline navigation title mode; no-op on other platforms.
    @ViewBuilder
    func iosInlineNavigationBarTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// iOS-only large navigation title mode; no-op on other platforms.
    @ViewBuilder
    func iosLargeNavigationBarTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.large)
        #else
        self
        #endif
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

    /// Liquid Glass for chrome controls (toolbar / empty-state actions). Never use on list rows or cards.
    @ViewBuilder
    func chromeGlassButtonStyle() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self
        }
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
