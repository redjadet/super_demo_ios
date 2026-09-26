//
//  ShareInboxDemoView.swift
//  superDemoApp
//
//  Engineering demo: read Share App Group inbox (JP-P2-A).
//

import SwiftUI

/// Engineering demo: list Share extension inbox entries or honest empty/unavailable.
struct ShareInboxDemoView: View {
    @State private var loadState: ShareInboxLoadState = .absent

    var body: some View {
        List {
            Section("Honesty") {
                Text(
                    """
                    Share extension writes URL/text into the App Group inbox \
                    (\(ShareInboxAppGroup.fileName)). It does not open the \
                    main SwiftData Items store. Import into Items is a separate \
                    in-app step (not automatic). Unsigned Simulator may show \
                    unavailable until the App Group is provisioned.
                    """
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Actions") {
                Button("Reload inbox") {
                    self.reload()
                }
                .accessibilityIdentifier("shareInboxReload")

                Button("Seed demo entry (main app write)") {
                    self.seedDemoEntry()
                }
                .accessibilityIdentifier("shareInboxSeed")

                Button("Clear inbox", role: .destructive) {
                    self.clearInbox()
                }
                .accessibilityIdentifier("shareInboxClear")
            }

            switch self.loadState {
            case .unavailable:
                Section("Status") {
                    ContentUnavailableView(
                        "App Group unavailable",
                        systemImage: "rectangle.dashed",
                        description: Text(
                            "No App Group container. Typical on unsigned Simulator or missing entitlement."
                        )
                    )
                    .accessibilityIdentifier("shareInboxUnavailable")
                }
            case .absent:
                Section("Status") {
                    ContentUnavailableView(
                        "Inbox empty",
                        systemImage: "tray",
                        description: Text(
                            "Share a URL or text into “Share to Items”, or seed a demo entry here."
                        )
                    )
                    .accessibilityIdentifier("shareInboxAbsent")
                }
            case .corrupt:
                Section("Status") {
                    ContentUnavailableView(
                        "Inbox corrupt",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Could not decode share-inbox.json (schema or JSON).")
                    )
                    .accessibilityIdentifier("shareInboxCorrupt")
                }
            case let .ok(payload):
                Section("Entries (\(payload.entries.count))") {
                    ForEach(payload.entries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.displaySummary)
                                .font(.body)
                            Text(entry.receivedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityIdentifier("shareInboxEntry_\(entry.id.uuidString)")
                    }
                }
            }
        }
        .navigationTitle("Share inbox")
        .iosLargeNavigationBarTitle()
        .accessibilityIdentifier("shareInboxDemoScreen")
        .onAppear { self.reload() }
    }

    private func reload() {
        self.loadState = ShareInboxStore.loadState()
    }

    private func seedDemoEntry() {
        let entry = ShareInboxEntry(
            text: "Demo note from Engineering demos",
            urlString: "https://superdemo.app/items"
        )
        try? ShareInboxStore.append(entry)
        self.reload()
    }

    private func clearInbox() {
        do {
            try ShareInboxStore.clear()
        } catch {
            // Reload will surface unavailable/corrupt honestly.
        }
        self.reload()
    }
}

#Preview("Share inbox — absent") {
    NavigationStack {
        ShareInboxDemoView()
    }
}
