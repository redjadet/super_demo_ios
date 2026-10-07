//
//  FeedTVSnapshotView.swift
//  superDemoAppTV
//
//  Read-only Feed widget snapshot UI on tvOS. Same DTO / states as iOS
//  widget and watchOS companion; App Group container is tv-local (not
//  phone↔TV sync).
//

import SwiftUI

struct FeedTVSnapshotView: View {
    @State private var state: FeedWidgetSnapshotState = .absent
    @State private var seededNote: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(self.statusTitle)
                        .font(.title2)
                        .accessibilityIdentifier("tvFeedSnapshotStatus")
                    Text(self.statusDetail)
                        .font(.body)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Feed snapshot")
                } footer: {
                    Text(
                        "Same App Group ID + JSON as the iPhone widget and watch "
                            + "companion. TV container is local — not live phone sync."
                    )
                }

                if case let .ok(snapshot) = self.state {
                    Section("Titles") {
                        ForEach(snapshot.titles.prefix(8), id: \.id) { row in
                            Text(row.title)
                                .lineLimit(2)
                        }
                    }
                } else if case let .expired(snapshot) = self.state {
                    Section("Expired titles") {
                        ForEach(snapshot.titles.prefix(8), id: \.id) { row in
                            Text(row.title)
                                .lineLimit(2)
                        }
                    }
                }

                Section {
                    Button("Reload") {
                        self.reload()
                    }
                    .accessibilityIdentifier("tvFeedSnapshotReload")

                    Button("Seed demo snapshot") {
                        self.seedDemo()
                    }
                    .accessibilityIdentifier("tvFeedSnapshotSeed")
                } footer: {
                    if let seededNote {
                        Text(seededNote)
                            .font(.caption)
                    } else {
                        Text(
                            "Seed writes a sample snapshot into the tvOS App Group "
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
            return "No \(FeedWidgetAppGroup.fileName) on this Apple TV yet."
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
        let snapshot = FeedCompanionDemoSnapshot.tvSeed()
        do {
            try FeedWidgetSnapshotStore.write(snapshot)
            self.state = FeedWidgetSnapshotStore.loadState()
            self.seededNote = "Seeded tv-local demo snapshot."
        } catch {
            self.state = FeedWidgetSnapshotStore.loadState()
            self.seededNote = "Seed failed (App Group unavailable)."
        }
    }
}

#Preview("Absent") {
    FeedTVSnapshotView()
}

#Preview("Absent dark") {
    FeedTVSnapshotView()
        .preferredColorScheme(.dark)
}
