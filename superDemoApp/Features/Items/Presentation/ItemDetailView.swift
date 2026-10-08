//
//  ItemDetailView.swift
//  superDemoApp
//

import SwiftUI

struct ItemDetailView: View {
    private let item: ItemEntity
    @Bindable private var model: ItemsFeatureModel
    private let draftStore: ItemDraftStoreBinding?

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @State private var title: String
    @State private var note: String
    @State private var savedTitle: String
    @State private var savedNote: String
    @State private var draftRevision: UInt = 0
    @State private var saveGeneration: UInt = 0
    @State private var isSaving = false
    @State private var saveFeedbackTick = 0
    #if os(macOS)
    @FocusState private var titleIsFocused: Bool
    #endif

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

    private var itemWasDeleted: Bool {
        switch self.model.state {
        case .empty: true
        case let .content(items): !items.contains { $0.id == self.item.id }
        case .loading, .failed: false
        }
    }

    private var noteEditorMinHeight: CGFloat {
        let base = DesignSpacing.noteEditorMinHeight
        if self.dynamicTypeSize.isAccessibilitySize {
            return base * 1.5
        }
        if self.dynamicTypeSize >= .xxLarge {
            return base * 1.25
        }
        return base
    }

    var body: some View {
        Form {
            // Field labels carry the role; skip redundant section titles (functional minimalism).
            Section {
                TextField("Title", text: self.$title)
                    .accessibilityIdentifier("itemDetailTitle")
                    #if os(macOS)
                    .focused(self.$titleIsFocused)
                    #endif
            }
            Section {
                TextEditor(text: self.$note)
                    .frame(minHeight: self.noteEditorMinHeight)
                    .accessibilityLabel("Note")
                    .accessibilityIdentifier("itemDetailNote")
            } header: {
                #if os(macOS)
                Text("Note")
                #endif
            }
            if self.isDirty {
                Section {
                    Text("Unsaved changes")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("itemDetailUnsaved")
                }
            }
        }
        .navigationTitle("Item")
        #if os(macOS)
        .formStyle(.grouped)
        .defaultFocus(self.$titleIsFocused, true)
        .onAppear { self.titleIsFocused = true }
        .focusedSceneValue(\.macSaveItem, self.isDirty && !self.isSaving ? {
            Task { await self.saveChanges() }
        } : nil)
        #endif
        .iosInlineNavigationBarTitle()
        .accessibilityIdentifier("itemDetail")
        .sensoryFeedback(.success, trigger: self.saveFeedbackTick)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task { await self.saveChanges() }
                } label: {
                    if self.isSaving {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Save")
                    }
                }
                .disabled(self.isSaving || !self.isDirty)
                .accessibilityIdentifier("itemDetailSave")
                .accessibilityLabel(self.isSaving ? "Saving" : "Save")
                .accessibilityHint(self.isDirty ? "Saves title and note changes" : "No changes to save")
            }
        }
        .onChange(of: self.title) { _, _ in
            self.bumpDraftRevisionAndPersist()
        }
        .onChange(of: self.note) { _, _ in
            self.bumpDraftRevisionAndPersist()
        }
        .onDisappear {
            // A confirmed deletion must not autosave a draft back into a removed record.
            if self.itemWasDeleted {
                self.draftStore?.clear()
                return
            }
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
            self.saveFeedbackTick &+= 1
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
