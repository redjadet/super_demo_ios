//
//  ItemsView.swift
//  superDemoApp
//

import SwiftUI

struct ItemsView: View {
    @Bindable private var model: ItemsFeatureModel

    @State private var selectedItem: ItemEntity?
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar
    @State private var addFeedbackTick = 0
    @State private var isAdding = false
    #if os(macOS)
    @State private var itemPendingDeletion: ItemEntity?
    #endif

    init(model: ItemsFeatureModel) {
        self.model = model
    }

    private var isLoading: Bool {
        if case .loading = self.model.state {
            return true
        }
        return false
    }

    var body: some View {
        ItemsNavigationShell(
            selectedItem: self.$selectedItem,
            preferredCompactColumn: self.$preferredCompactColumn,
            model: self.model
        ) {
            self.content
                .navigationTitle("Items")
                .iosInlineNavigationBarTitle()
        }
        .toolbar {
            self.itemsToolbar
        }
        #if os(macOS)
        .focusedSceneValue(\.macNewItem, self.isLoading || self.isAdding ? nil : { self.addItem() })
        .focusedSceneValue(\.macRefresh) { self.model.refresh() }
        .onChange(of: self.model.state) { _, state in
            guard let selectedID = self.selectedItem?.id,
                  case let .content(items) = state
            else { return }
            // Entity equality includes edited fields. Keep List selection in sync after save/refresh.
            self.selectedItem = items.first { $0.id == selectedID }
        }
        .confirmationDialog(
            "Delete Item?",
            isPresented: Binding(
                get: { self.itemPendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        self.itemPendingDeletion = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let item = self.itemPendingDeletion {
                    self.deleteItem(item)
                }
            }
            Button("Cancel", role: .cancel) { self.itemPendingDeletion = nil }
        } message: {
            Text("This permanently deletes the selected note.")
        }
        #endif
        .sensoryFeedback(.success, trigger: self.addFeedbackTick)
        .task {
            await self.model.refreshAndWait()
        }
        .onDisappear {
            self.model.cancelRefresh()
        }
    }

    @ToolbarContentBuilder private var itemsToolbar: some ToolbarContent {
        #if os(iOS)
        if case .content = self.model.state {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarSpacer(.fixed)
        }
        #endif
        ToolbarItem {
            Button {
                self.addItem()
            } label: {
                Label("Add Item", systemImage: "plus")
            }
            .chromeGlassButtonStyle()
            .disabled(self.isLoading || self.isAdding)
            .accessibilityIdentifier("addItem")
            .accessibilityHint("Adds a new item to the list")
        }
    }

    @ViewBuilder private var content: some View {
        switch self.model.state {
        case .loading:
            FeatureLoadingPlaceholder(
                accessibilityIdentifier: "itemsLoading",
                accessibilityLabel: "Loading items"
            )
        case let .failed(error):
            ContentUnavailableView {
                Label("Could Not Load Items", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.message)
            } actions: {
                Button("Retry") {
                    self.model.refresh()
                }
                .chromeGlassButtonStyle()
                .accessibilityIdentifier("itemsRetry")
            }
            .featureScreenFrame()
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("itemsFailed")
            .accessibilityLabel("Could not load items")
        case .empty:
            ContentUnavailableView {
                Label("No Items", systemImage: "tray")
            } description: {
                Text("Add a note to get started.")
            } actions: {
                Button("Add Item") {
                    self.addItem()
                }
                .disabled(self.isAdding)
                .chromeGlassButtonStyle()
                .accessibilityIdentifier("addItemEmpty")
            }
            .featureScreenFrame()
            .accessibilityIdentifier("itemsEmpty")
            .accessibilityLabel("No items")
        case let .content(items):
            self.itemsList(items)
        }
    }

    private func itemsList(_ items: [ItemEntity]) -> some View {
        List(selection: self.$selectedItem) {
            ForEach(items) { item in
                NavigationLink(value: item) {
                    VStack(alignment: .leading, spacing: DesignSpacing.xs) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.timestamp, format: .dateTime.month().day().hour().minute())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(self.itemRowAccessibilityLabel(for: item))
                }
                .accessibilityIdentifier("itemRow-\(item.id.uuidString)")
                .tag(item)
                #if os(macOS)
                .contextMenu {
                    Button("Delete Item", role: .destructive) {
                        self.itemPendingDeletion = item
                    }
                }
                #endif
            }
            .onDelete { offsets in
                #if os(macOS)
                if let index = offsets.first, items.indices.contains(index) {
                    self.itemPendingDeletion = items[index]
                }
                #else
                Task {
                    await self.model.deleteItems(at: offsets, in: items)
                    self.clearSelectionIfDeleted(from: items, at: offsets)
                }
                #endif
            }
        }
        #if os(macOS)
        .onDeleteCommand {
            self.itemPendingDeletion = self.selectedItem
        }
        #endif
        .featureSidebarColumnWidth()
        .accessibilityIdentifier("itemsList")
    }

    private func addItem() {
        guard !self.isLoading, !self.isAdding else { return }
        self.isAdding = true
        Task {
            defer { self.isAdding = false }
            #if os(macOS)
            let priorIDs: Set<UUID>
            if case let .content(items) = self.model.state {
                priorIDs = Set(items.map(\.id))
            } else {
                priorIDs = []
            }
            #endif
            await self.model.addItemNow()
            if case .failed = self.model.state {
                return
            }
            self.addFeedbackTick &+= 1
            #if os(macOS)
            if case let .content(items) = self.model.state {
                self.selectedItem = items.first { !priorIDs.contains($0.id) }
            }
            #endif
        }
    }

    #if os(macOS)
    private func deleteItem(_ item: ItemEntity) {
        guard case let .content(items) = self.model.state,
              let index = items.firstIndex(where: { $0.id == item.id })
        else { return }
        Task {
            await self.model.deleteItems(at: IndexSet(integer: index), in: items)
            self.clearSelectionIfDeleted(from: items, at: IndexSet(integer: index))
        }
    }
    #endif

    private func itemRowAccessibilityLabel(for item: ItemEntity) -> String {
        let when = item.timestamp.formatted(.dateTime.month().day().hour().minute())
        return "\(item.title), \(when)"
    }

    private func clearSelectionIfDeleted(from items: [ItemEntity], at offsets: IndexSet) {
        if case .failed = self.model.state {
            return
        }
        guard let selectedItem else { return }
        let deletedIDs = Set(offsets.compactMap { items.indices.contains($0) ? items[$0].id : nil })
        if deletedIDs.contains(selectedItem.id) {
            self.selectedItem = nil
            self.preferredCompactColumn = .sidebar
        }
    }
}

#Preview("Items — iPhone", traits: UniversalPreviewLayouts.iPhonePortrait) {
    ItemsPreviewFactory.view(seedItems: ItemsPreviewFactory.sampleItems)
}

#Preview("Items — iPhone (Dark)", traits: UniversalPreviewLayouts.iPhonePortrait) {
    ItemsPreviewFactory.view(seedItems: ItemsPreviewFactory.sampleItems)
        .previewDarkAppearance()
}

#Preview("Items — iPad", traits: UniversalPreviewLayouts.iPadRegular) {
    ItemsPreviewFactory.view(seedItems: ItemsPreviewFactory.sampleItems)
}

#Preview("Items — Mac", traits: UniversalPreviewLayouts.macWindow) {
    ItemsPreviewFactory.view(seedItems: ItemsPreviewFactory.sampleItems)
}

#Preview("Items — Mac (Dark)", traits: UniversalPreviewLayouts.macWindow) {
    ItemsPreviewFactory.view(seedItems: ItemsPreviewFactory.sampleItems)
        .previewDarkAppearance()
}

#Preview("Items — Empty", traits: UniversalPreviewLayouts.iPhonePortrait) {
    ItemsPreviewFactory.view(seedItems: [])
}

@MainActor
private enum ItemsPreviewFactory {
    static let sampleItems = [
        ItemEntity(id: UUID(), title: String(localized: "Sample note"), note: "", timestamp: Date()),
    ]

    static func view(seedItems: [ItemEntity]) -> some View {
        let repository = PreviewItemRepository(seedItems: seedItems)
        let model = ItemsFeatureModel(
            loadItems: LoadItemsUseCase(repository: repository),
            addItem: AddItemUseCase(repository: repository),
            updateItem: UpdateItemUseCase(repository: repository),
            deleteItems: DeleteItemsUseCase(repository: repository)
        )
        return ItemsView(model: model)
    }
}

@MainActor
private final class PreviewItemRepository: ItemRepository {
    private var items: [ItemEntity]

    init(seedItems: [ItemEntity]) {
        self.items = seedItems
    }

    func fetchItems() throws -> [ItemEntity] {
        self.items
    }

    func addItem(timestamp: Date) throws -> ItemEntity {
        let item = ItemEntity(id: UUID(), title: String(localized: "New note"), note: "", timestamp: timestamp)
        self.items.append(item)
        return item
    }

    func updateItem(_ item: ItemEntity) throws {
        guard let index = self.items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        self.items[index] = item
    }

    func deleteItems(ids: [UUID]) throws {
        self.items.removeAll { ids.contains($0.id) }
    }
}
