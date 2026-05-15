//
//  ItemsView.swift
//  superDemoApp
//

import SwiftUI

struct ItemsView: View {
    @Bindable private var model: ItemsFeatureModel

    init(model: ItemsFeatureModel) {
        self.model = model
    }

    var body: some View {
        ItemsNavigationShell {
            self.content
        }
        .toolbar {
            self.itemsToolbar
        }
        .task {
            await self.model.refresh()
        }
    }

    @ToolbarContentBuilder private var itemsToolbar: some ToolbarContent {
        #if os(iOS)
        if case .content = self.model.state {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        #endif
        ToolbarItem {
            Button {
                Task { await self.model.addItemNow() }
            } label: {
                Label("Add Item", systemImage: "plus")
            }
            .accessibilityIdentifier("addItem")
        }
    }

    @ViewBuilder private var content: some View {
        switch self.model.state {
        case .loading:
            ProgressView()
                .featureScreenFrame()
        case let .failed(error):
            ContentUnavailableView {
                Label("Could Not Load Items", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.message)
            } actions: {
                Button("Retry") {
                    Task { await self.model.refresh() }
                }
            }
            .featureScreenFrame()
        case .empty:
            ContentUnavailableView {
                Label("No Items", systemImage: "tray")
            } actions: {
                Button("Add Item") {
                    Task { await self.model.addItemNow() }
                }
                .accessibilityIdentifier("addItem")
            }
            .featureScreenFrame()
        case let .content(items):
            self.itemsList(items)
        }
    }

    private func itemsList(_ items: [ItemEntity]) -> some View {
        List {
            ForEach(items) { item in
                NavigationLink {
                    Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                } label: {
                    Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                }
            }
            .onDelete { offsets in
                Task { await self.model.deleteItems(at: offsets, in: items) }
            }
        }
        .featureSidebarColumnWidth()
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
        ItemEntity(id: UUID(), timestamp: Date()),
    ]

    static func view(seedItems: [ItemEntity]) -> some View {
        let repository = PreviewItemRepository(seedItems: seedItems)
        let model = ItemsFeatureModel(
            loadItems: LoadItemsUseCase(repository: repository),
            addItem: AddItemUseCase(repository: repository),
            deleteItems: DeleteItemsUseCase(repository: repository)
        )
        return ItemsView(model: model)
            .task { await model.refresh() }
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
        let item = ItemEntity(id: UUID(), timestamp: timestamp)
        self.items.append(item)
        return item
    }

    func deleteItems(ids: [UUID]) throws {
        self.items.removeAll { ids.contains($0.id) }
    }
}
