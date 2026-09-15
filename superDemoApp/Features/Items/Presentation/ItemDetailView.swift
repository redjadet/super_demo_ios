//
//  ItemDetailView.swift
//  superDemoApp
//

import SwiftUI

struct ItemDetailView: View {
    private let item: ItemEntity
    @Bindable private var model: ItemsFeatureModel

    @State private var title: String
    @State private var note: String
    @State private var savedTitle: String
    @State private var savedNote: String

    init(item: ItemEntity, model: ItemsFeatureModel) {
        self.item = item
        self.model = model
        self._title = State(initialValue: item.title)
        self._note = State(initialValue: item.note)
        self._savedTitle = State(initialValue: item.title)
        self._savedNote = State(initialValue: item.note)
    }

    var body: some View {
        Form {
            Section("Title") {
                TextField("Title", text: self.$title)
            }
            Section("Note") {
                TextEditor(text: self.$note)
                    .frame(minHeight: 120)
            }
        }
        .navigationTitle("Item")
        .iosInlineNavigationBarTitle()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await self.saveChanges() }
                }
            }
        }
        .onDisappear {
            Task { await self.saveChanges() }
        }
    }

    private func saveChanges() async {
        guard self.title != self.savedTitle || self.note != self.savedNote else {
            return
        }

        var updated = self.item
        updated.title = self.title
        updated.note = self.note
        await self.model.updateItemNow(updated)
        self.savedTitle = self.title
        self.savedNote = self.note
    }
}
