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
                Task {
                    guard !self.isLoading else { return }
                    await self.model.addItemNow()
                    if case .failed = self.model.state {
                        return
                    }
                    self.addFeedbackTick &+= 1
                }
            } label: {
                Label("Add Item", systemImage: "plus")
            }
            .chromeGlassButtonStyle()
            .allowsHitTesting(!self.isLoading)
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
                    Task {
                        await self.model.addItemNow()
                        if case .failed = self.model.state {
                            return
                        }
                        self.addFeedbackTick &+= 1
                    }
                }
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
            }
            .onDelete { offsets in
                Task {
                    await self.model.deleteItems(at: offsets, in: items)
                    self.clearSelectionIfDeleted(from: items, at: offsets)
                }
            }
        }
        .featureSidebarColumnWidth()
        .accessibilityIdentifier("itemsList")
    }

    private func itemRowAccessibilityLabel(for item: ItemEntity) -> String {
        let when = item.timestamp.formatted(.dateTime.month().day().hour().minute())
        return "\(item.title), \(when)"
    }

    private func clearSelectionIfDeleted(from items: [ItemEntity], at offsets: IndexSet) {
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
