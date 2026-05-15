//
//  ItemsComposition.swift
//  superDemoApp
//

import SwiftData
import SwiftUI

enum ItemsComposition {
    @MainActor
    static func makeFeatureModel(context: ModelContext) -> ItemsFeatureModel {
        let repository = SwiftDataItemRepository(context: context)
        return ItemsFeatureModel(
            loadItems: LoadItemsUseCase(repository: repository),
            addItem: AddItemUseCase(repository: repository),
            deleteItems: DeleteItemsUseCase(repository: repository)
        )
    }
}

struct ItemsRootView: View {
    @Environment(\.modelContext)
    private var modelContext

    var body: some View {
        ItemsView(model: ItemsComposition.makeFeatureModel(context: self.modelContext))
    }
}
