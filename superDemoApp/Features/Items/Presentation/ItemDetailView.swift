//
//  ItemDetailView.swift
//  superDemoApp
//

import SwiftUI

struct ItemDetailView: View {
    private let item: ItemEntity
    @Bindable private var model: ItemsFeatureModel
    private let draftStore: ItemDraftStoreBinding?

    @State private var title: String
    @State private var note: String
    @State private var savedTitle: String
    @State private var savedNote: String
    @State private var draftRevision: UInt = 0
    @State private var saveGeneration: UInt = 0
    @State private var isSaving = false

    init(
        item: ItemEntity,
        model: ItemsFeatureModel,
        draftStore: ItemDraftStoreBinding? = nil
    ) {
        self.item = item
        self.model = model
        self.draftStore = draftStore
        let draft = draftStore?.load()
        let initialTitle = draft?.title ?? item.title
        let initialNote = draft?.note ?? item.note
        self._title = State(initialValue: initialTitle)
        self._note = State(initialValue: initialNote)
        self._savedTitle = State(initialValue: item.title)
        self._savedNote = State(initialValue: item.note)
        self._draftRevision = State(initialValue: draft?.revision ?? 0)
    }

    private var isDirty: Bool {
        self.title != self.savedTitle || self.note != self.savedNote
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
        .accessibilityIdentifier("itemDetail")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await self.saveChanges() }
                }
                .disabled(self.isSaving || !self.isDirty)
            }
        }
        .onChange(of: self.title) { _, _ in
            self.bumpDraftRevisionAndPersist()
        }
        .onChange(of: self.note) { _, _ in
            self.bumpDraftRevisionAndPersist()
        }
        .onDisappear {
            self.persistDraftSnapshot()
            Task { await self.saveChanges() }
        }
    }

    @discardableResult
    func saveChanges() async -> Bool {
        guard self.isDirty else { return true }
        guard !self.isSaving else { return false }

        self.isSaving = true
        defer { self.isSaving = false }

        self.saveGeneration &+= 1
        let generation = self.saveGeneration
        let revisionAtStart = self.draftRevision

        var updated = self.item
        updated.title = self.title
        updated.note = self.note

        let succeeded = await self.model.updateItemNow(updated)
        guard generation == self.saveGeneration else { return false }

        if succeeded {
            // Only clear dirty if the user did not edit during the in-flight save.
            if revisionAtStart == self.draftRevision {
                self.savedTitle = self.title
                self.savedNote = self.note
                self.draftStore?.clear()
            } else {
                self.savedTitle = updated.title
                self.savedNote = updated.note
                self.persistDraftSnapshot()
            }
            return true
        }

        // Failed persistence — keep dirty fields and draft under this item id.
        self.persistDraftSnapshot()
        return false
    }

    private func bumpDraftRevisionAndPersist() {
        self.draftRevision &+= 1
        self.persistDraftSnapshot()
    }

    private func persistDraftSnapshot() {
        guard self.isDirty else {
            self.draftStore?.clear()
            return
        }
        self.draftStore?.save(
            ItemEditorDraft(title: self.title, note: self.note, revision: self.draftRevision)
        )
    }
}
