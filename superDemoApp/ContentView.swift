//
//  ContentView.swift
//  superDemoApp
//
//  Created by İlker Sevim on 15.05.2026.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext)
    private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationViewWrapper {
            List {
                ForEach(self.items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: self.deleteItems)
            }
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                #endif
                ToolbarItem {
                    Button(action: self.addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            self.modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                self.modelContext.delete(self.items[index])
            }
        }
    }
}

private struct NavigationViewWrapper<Content: View>: View {
    let content: () -> Content

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            self.content()
        } detail: {
            Text("Select an item")
        }
        #else
        NavigationStack {
            self.content()
        }
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
