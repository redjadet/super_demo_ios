//
//  WatchCompanionDemoView.swift
//  superDemoApp
//
//  iPhone demo that describes the watchOS Feed companion and its limits.
//

import SwiftUI

struct WatchCompanionDemoView: View {
    var body: some View {
        List {
            Section {
                Text("watchOS Feed snapshot companion")
                    .font(.headline)
                    .accessibilityIdentifier("watchCompanionDemoTitle")
                    .accessibilityLabel("watchOS Feed snapshot companion")
                Text(
                    "Browse a local Feed with clear freshness states and full headline details. "
                        + "Try sample Feed to explore offline, then use Demo states to show "
                        + "cached, expired, empty, or unavailable content."
                )
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("watchCompanionDemoSummary")
                .accessibilityLabel(
                    "Watch companion shows local Feed headlines and offline sample states."
                )
            } header: {
                Text("Surface")
            }

            Section {
                LabeledContent("Watch bundle") {
                    Text("com.ilkersevim.superDemoApp.watchkitapp")
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
                LabeledContent("App Group") {
                    Text(FeedWidgetAppGroup.identifier)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
                LabeledContent("Shared sources") {
                    Text("FeedWidgetShared/")
                        .font(.caption.monospaced())
                }
            } header: {
                Text("Identifiers")
            }

            Section {
                Text(
                    "iPhone and Watch do not share one App Group disk. "
                        + "Each process has a local container with the same group ID. "
                        + "This demo does not claim WatchConnectivity phone→watch sync. "
                        + "On Watch Simulator, choose Try sample Feed. Samples stay in memory "
                        + "and never replace a saved snapshot. Scroll with the Digital Crown; "
                        + "tap a headline to read it in full."
                )
                .font(.callout)
                .accessibilityIdentifier("watchCompanionDemoHonesty")
                .accessibilityLabel(
                    "Watch App Group is local only. No phone to watch sync is claimed."
                )
            } header: {
                Text("Independent demo")
            } footer: {
                Text("A visionOS companion app is not included in this sample.")
            }
        }
        .navigationTitle("Watch companion")
        .accessibilityIdentifier("watchCompanionDemoScreen")
        .accessibilityLabel("Watch companion Engineering demo")
    }
}

#Preview("Watch companion demo") {
    NavigationStack {
        WatchCompanionDemoView()
    }
}
