//
//  FeedRefreshLiveActivity.swift
//  superDemoAppWidget
//
//  Lock screen + Dynamic Island UI for Feed refresh Live Activity (JP-P1-A).
//

import ActivityKit
import SwiftUI
import WidgetKit

struct FeedRefreshLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FeedRefreshActivityAttributes.self) { context in
            FeedRefreshLiveActivityLockScreenView(state: context.state)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Feed", systemImage: "list.bullet.rectangle")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.phaseLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.detail)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: context.state.systemImageName)
            } compactTrailing: {
                Text(context.state.compactTrailing)
                    .font(.caption2)
            } minimal: {
                Image(systemName: context.state.systemImageName)
            }
        }
    }
}

private struct FeedRefreshLiveActivityLockScreenView: View {
    let state: FeedRefreshActivityAttributes.ContentState

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: self.state.systemImageName)
                .font(.title2)
                .foregroundStyle(self.state.accentColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Feed refresh")
                    .font(.headline)
                Text(self.state.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(self.state.phaseLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private extension FeedRefreshActivityAttributes.ContentState {
    var phaseLabel: String {
        switch self.phase {
        case .refreshing: "Refreshing"
        case .completed: "Done"
        case .failed: "Failed"
        case .cancelled: "Cancelled"
        }
    }

    var compactTrailing: String {
        switch self.phase {
        case .refreshing:
            return "…"
        case .completed:
            if let postCount {
                return "\(postCount)"
            }
            return "OK"
        case .failed:
            return "!"
        case .cancelled:
            return "×"
        }
    }

    var systemImageName: String {
        switch self.phase {
        case .refreshing: "arrow.clockwise"
        case .completed: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        case .cancelled: "xmark.circle.fill"
        }
    }

    var accentColor: Color {
        switch self.phase {
        case .refreshing: .accentColor
        case .completed: .green
        case .failed: .orange
        case .cancelled: .secondary
        }
    }
}
