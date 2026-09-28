//
//  ItemsNavigationShell.swift
//  superDemoApp
//

import SwiftUI

/// Items feature navigation — selection-driven split (same fix as Feed).
/// Detail identity is keyed by `ItemEntity.id` so `@State` drafts cannot leak
/// across A→B selection changes on iPad/Mac split views.
struct ItemsNavigationShell<Sidebar: View>: View {
    @Binding private var selectedItem: ItemEntity?
    @Binding private var preferredCompactColumn: NavigationSplitViewColumn
    private let model: ItemsFeatureModel
    @ViewBuilder private var sidebar: () -> Sidebar

    /// In-memory drafts keyed by item id so A→B→A restores A's unsaved edits.
    @State private var draftsByItemID: [UUID: ItemEditorDraft] = [:]

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
                ItemDetailView(
                    item: selectedItem,
                    model: self.model,
                    draftStore: ItemDraftStoreBinding(
                        itemID: selectedItem.id,
                        draftsByItemID: self.$draftsByItemID
                    )
                )
                .id(selectedItem.id)
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

struct ItemEditorDraft: Equatable, Sendable {
    var title: String
    var note: String
    var revision: UInt
}

/// Bridges shell-owned draft storage into `ItemDetailView` without leaking
/// cross-item `@State`.
struct ItemDraftStoreBinding {
    let itemID: UUID
    var draftsByItemID: Binding<[UUID: ItemEditorDraft]>

    func load() -> ItemEditorDraft? {
        self.draftsByItemID.wrappedValue[self.itemID]
    }

    func save(_ draft: ItemEditorDraft) {
        self.draftsByItemID.wrappedValue[self.itemID] = draft
    }

    func clear() {
        self.draftsByItemID.wrappedValue[self.itemID] = nil
    }
}
