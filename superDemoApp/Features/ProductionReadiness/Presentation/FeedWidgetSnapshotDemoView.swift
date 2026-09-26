//
//  FeedWidgetSnapshotDemoView.swift
//  superDemoApp
//
//  Engineering demo: read App Group Feed widget snapshot state (honest).
//

import SwiftUI

struct FeedWidgetSnapshotDemoView: View {
    @State private var state: FeedWidgetSnapshotState = .absent
    @State private var refreshedAt: Date?

    var body: some View {
        List {
            Section {
                Text(self.statusTitle)
                    .font(.headline)
                    .accessibilityIdentifier("feedWidgetSnapshotStatus")
                Text(self.statusDetail)
                    .foregroundStyle(.secondary)
            } header: {
                Text("App Group snapshot")
            } footer: {
                Text(
                    "Widget process is read-only. Refresh Feed in the main tab to publish. "
                        + "Stale Feed demo uses an in-memory store and does not write this file."
                )
            }

            if case let .ok(snapshot) = self.state {
                Section("Titles") {
                    ForEach(snapshot.titles, id: \.id) { row in
                        Text(row.title)
                    }
                }
            } else if case let .expired(snapshot) = self.state {
                Section("Expired titles (still on disk)") {
                    ForEach(snapshot.titles, id: \.id) { row in
                        Text(row.title)
                    }
                }
            }

            Section {
                Button("Reload snapshot state") {
                    self.reload()
                }
                .accessibilityIdentifier("feedWidgetSnapshotReload")
            }
        }
        .navigationTitle("Feed widget snapshot")
        .accessibilityIdentifier("feedWidgetSnapshotDemoScreen")
        .onAppear { self.reload() }
    }

    private var statusTitle: String {
        switch self.state {
        case .unavailable: "Unavailable"
        case .absent: "Absent"
        case .corrupt: "Corrupt"
        case .expired: "Expired"
        case .ok: "OK"
        }
    }

    private var statusDetail: String {
        let stamp = self.refreshedAt.map { "Checked \($0.formatted(date: .omitted, time: .standard)). " } ?? ""
        switch self.state {
        case .unavailable:
            return stamp + "App Group container missing (unsigned / entitlement)."
        case .absent:
            return stamp + "No \(FeedWidgetAppGroup.fileName) yet."
        case .corrupt:
            return stamp + "JSON decode failed or version mismatch."
        case let .expired(snapshot):
            return stamp + "Past TTL (\(Int(snapshot.cacheTTLSeconds ?? 0))s). Widget shows expired state."
        case let .ok(snapshot):
            let stale = snapshot.isStale ? " stale" : ""
            return stamp + "\(snapshot.titles.count) title(s)\(stale)."
        }
    }

    private func reload() {
        self.state = FeedWidgetSnapshotStore.loadState()
        self.refreshedAt = Date()
    }
}
