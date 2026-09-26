//
//  FeedWidget.swift
//  superDemoAppWidget
//
//  Read-only Home Screen widget over the App Group Feed snapshot.
//

import SwiftUI
import WidgetKit

struct FeedWidget: Widget {
    let kind: String = FeedWidgetAppGroup.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: self.kind, provider: FeedWidgetTimelineProvider()) { entry in
            FeedWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Feed cache")
        .description("Last cached Feed titles from the App Group snapshot.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct FeedWidgetEntry: TimelineEntry {
    let date: Date
    let state: FeedWidgetSnapshotState
}

struct FeedWidgetTimelineProvider: TimelineProvider {
    func placeholder(in _: Context) -> FeedWidgetEntry {
        FeedWidgetEntry(
            date: Date(),
            state: .ok(
                FeedWidgetSnapshot(
                    writtenAt: Date(),
                    cacheTTLSeconds: 15 * 60,
                    isStale: false,
                    titles: [
                        .init(id: 1, title: "Sample Feed title"),
                    ]
                )
            )
        )
    }

    func getSnapshot(in _: Context, completion: (FeedWidgetEntry) -> Void) {
        completion(self.makeEntry())
    }

    func getTimeline(in _: Context, completion: (Timeline<FeedWidgetEntry>) -> Void) {
        let entry = self.makeEntry()
        let next = Self.nextReloadDate(for: entry)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    /// Prefer snapshot TTL expiry over a blind 15m tick so `.expired` appears on time.
    private static func nextReloadDate(for entry: FeedWidgetEntry) -> Date {
        let fallback = entry.date.addingTimeInterval(15 * 60)
        switch entry.state {
        case let .ok(snapshot), let .expired(snapshot):
            guard let ttl = snapshot.cacheTTLSeconds else { return fallback }
            let expiry = snapshot.writtenAt.addingTimeInterval(ttl)
            // At least 60s out so WidgetKit does not spam; never later than fallback.
            let earliest = entry.date.addingTimeInterval(60)
            return min(fallback, max(earliest, expiry))
        case .unavailable, .absent, .corrupt:
            return fallback
        }
    }

    private func makeEntry() -> FeedWidgetEntry {
        let now = Date()
        return FeedWidgetEntry(date: now, state: FeedWidgetSnapshotStore.loadState(now: now))
    }
}

struct FeedWidgetEntryView: View {
    let entry: FeedWidgetEntry

    var body: some View {
        switch self.entry.state {
        case .unavailable:
            self.messageView(
                title: "Feed unavailable",
                detail: "App Group not available on this install."
            )
        case .absent:
            self.messageView(
                title: "No Feed snapshot",
                detail: "Open the app and refresh Feed to publish."
            )
        case .corrupt:
            self.messageView(
                title: "Snapshot unreadable",
                detail: "Cached widget data is corrupt or version-mismatched."
            )
        case let .expired(snapshot):
            self.titlesView(
                snapshot: snapshot,
                badge: "Expired cache",
                badgeSystemImage: "clock.badge.exclamationmark"
            )
        case let .ok(snapshot):
            self.titlesView(
                snapshot: snapshot,
                badge: snapshot.isStale ? "Stale cache" : nil,
                badgeSystemImage: snapshot.isStale ? "externaldrive.badge.exclamationmark" : nil
            )
        }
    }

    private func titlesView(
        snapshot: FeedWidgetSnapshot,
        badge: String?,
        badgeSystemImage: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let badge, let badgeSystemImage {
                Label(badge, systemImage: badgeSystemImage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if snapshot.titles.isEmpty {
                Text("Feed cache empty")
                    .font(.headline)
            } else {
                ForEach(snapshot.titles.prefix(3), id: \.id) { row in
                    Text(row.title)
                        .font(.subheadline)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func messageView(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview("Feed widget — ok", as: .systemSmall) {
    FeedWidget()
} timeline: {
    FeedWidgetEntry(
        date: .now,
        state: .ok(
            FeedWidgetSnapshot(
                writtenAt: .now,
                cacheTTLSeconds: 15 * 60,
                isStale: false,
                titles: [
                    .init(id: 1, title: "Hello from cache"),
                    .init(id: 2, title: "Second post"),
                ]
            )
        )
    )
}

#Preview("Feed widget — absent", as: .systemSmall) {
    FeedWidget()
} timeline: {
    FeedWidgetEntry(date: .now, state: .absent)
}
