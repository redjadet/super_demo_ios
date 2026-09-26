//
//  FeedWatchSnapshotView.swift
//  superDemoAppWatch
//
//  Read-only Feed widget snapshot UI on watchOS. Same DTO / states as iOS
//  widget; App Group container is watch-local (not phone↔watch sync).
//

import SwiftUI

struct FeedWatchSnapshotView: View {
    @State private var state: FeedWidgetSnapshotState = .absent
    @State private var seededNote: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(self.statusTitle)
                        .font(.headline)
                        .accessibilityIdentifier("watchFeedSnapshotStatus")
                    Text(self.statusDetail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Feed snapshot")
                } footer: {
                    Text(
                        "Same App Group ID + JSON as the iPhone widget. "
                            + "Watch container is local — not live phone sync."
                    )
                }

                if case let .ok(snapshot) = self.state {
                    Section("Titles") {
                        ForEach(snapshot.titles.prefix(5), id: \.id) { row in
                            Text(row.title)
                                .lineLimit(2)
                        }
                    }
                } else if case let .expired(snapshot) = self.state {
                    Section("Expired titles") {
                        ForEach(snapshot.titles.prefix(5), id: \.id) { row in
                            Text(row.title)
                                .lineLimit(2)
                        }
                    }
                }

                Section {
                    Button("Reload") {
                        self.reload()
                    }
                    .accessibilityIdentifier("watchFeedSnapshotReload")

                    Button("Seed demo snapshot") {
                        self.seedDemo()
                    }
                    .accessibilityIdentifier("watchFeedSnapshotSeed")
                } footer: {
                    if let seededNote {
                        Text(seededNote)
                            .font(.caption2)
                    } else {
                        Text(
                            "Seed writes a sample snapshot into the watch App Group "
                                + "for Simulator review when the phone file is absent."
                        )
                    }
                }
            }
            .navigationTitle("superDemo")
            .onAppear { self.reload() }
        }
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
        switch self.state {
        case .unavailable:
            return "App Group missing (unsigned / entitlement)."
        case .absent:
            return "No \(FeedWidgetAppGroup.fileName) on this watch yet."
        case .corrupt:
            return "JSON decode failed or version mismatch."
        case let .expired(snapshot):
            return "Past TTL (\(Int(snapshot.cacheTTLSeconds ?? 0))s)."
        case let .ok(snapshot):
            let stale = snapshot.isStale ? " · stale" : ""
            return "\(snapshot.titles.count) title(s)\(stale)."
        }
    }

    private func reload() {
        self.state = FeedWidgetSnapshotStore.loadState()
        self.seededNote = nil
    }

    private func seedDemo() {
        let snapshot = FeedWidgetSnapshot(
            writtenAt: Date(),
            cacheTTLSeconds: 15 * 60,
            isStale: false,
            titles: [
                .init(id: 1, title: "Watch demo: Feed snapshot"),
                .init(id: 2, title: "Same DTO as Home Screen widget"),
                .init(id: 3, title: "Local App Group — not phone sync"),
            ]
        )
        do {
            try FeedWidgetSnapshotStore.write(snapshot)
            self.state = FeedWidgetSnapshotStore.loadState()
            self.seededNote = "Seeded watch-local demo snapshot."
        } catch {
            self.state = FeedWidgetSnapshotStore.loadState()
            self.seededNote = "Seed failed (App Group unavailable)."
        }
    }
}

#Preview("Absent") {
    FeedWatchSnapshotView()
}
