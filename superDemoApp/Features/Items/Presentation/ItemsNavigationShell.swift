//
//  ItemsNavigationShell.swift
//  superDemoApp
//

import SwiftUI

/// Items feature navigation — selection-driven split (same fix as Feed).
struct ItemsNavigationShell<Sidebar: View>: View {
    @Binding private var selectedItem: ItemEntity?
    @Binding private var preferredCompactColumn: NavigationSplitViewColumn
    private let model: ItemsFeatureModel
    @ViewBuilder private var sidebar: () -> Sidebar

    init(
        selectedItem: Binding<ItemEntity?>,
        preferredCompactColumn: Binding<NavigationSplitViewColumn>,
        model: ItemsFeatureModel,
        @ViewBuilder sidebar: @escaping () -> Sidebar
    ) {
        self._selectedItem = selectedItem
        self._preferredCompactColumn = preferredCompactColumn
        self.model = model
        self.sidebar = sidebar
    }

    var body: some View {
        AdaptiveNavigationShell(preferredCompactColumn: self.$preferredCompactColumn) {
            self.sidebar()
        } detail: {
            if let selectedItem {
                ItemDetailView(item: selectedItem, model: self.model)
            } else {
                Text("Select an item")
                    .foregroundStyle(.secondary)
                    .featureScreenFrame()
            }
        }
        .onChange(of: self.selectedItem) { _, newValue in
            if newValue != nil {
                self.preferredCompactColumn = .detail
            }
        }
    }
}
