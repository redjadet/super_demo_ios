//
//  ItemsComposition.swift
//  superDemoApp
//

import SwiftData
import SwiftUI

enum ItemsComposition {
    @MainActor
    static func makeFeatureModel(context: ModelContext) -> ItemsFeatureModel {
        if AppLaunchConfiguration.isReviewerDemoMode {
            do {
                try ReviewerDemoFixtures.seedItemsIfNeeded(in: context)
            } catch {
                assertionFailure("Could not seed reviewer demo Items: \(error)")
            }
        }

        let repository = SwiftDataItemRepository(context: context)
        return ItemsFeatureModel(
            loadItems: LoadItemsUseCase(repository: repository),
            addItem: AddItemUseCase(repository: repository),
            updateItem: UpdateItemUseCase(repository: repository),
            deleteItems: DeleteItemsUseCase(repository: repository)
        )
    }
}

struct ItemsRootView: View {
    @Environment(\.modelContext)
    private var modelContext

    var body: some View {
        ItemsRootContent(context: self.modelContext)
    }
}

private struct ItemsRootContent: View {
    @State private var model: ItemsFeatureModel

    init(context: ModelContext) {
        self._model = State(initialValue: ItemsComposition.makeFeatureModel(context: context))
    }

    var body: some View {
        ItemsView(model: self.model)
    }
}
