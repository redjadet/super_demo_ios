//
//  WatchCompanionDemoView.swift
//  superDemoApp
//
//  Engineering demo (iPhone): documents JP-P2-F watchOS companion + honesty.
//

import SwiftUI

struct WatchCompanionDemoView: View {
    var body: some View {
        List {
            Section {
                Text("watchOS Feed snapshot companion")
                    .font(.headline)
                    .accessibilityIdentifier("watchCompanionDemoTitle")
                Text(
                    "The Watch app reads the same Feed widget App Group snapshot "
                        + "DTO (`feed-widget-snapshot.json`) and honest states "
                        + "(unavailable / absent / corrupt / expired / ok)."
                )
                .foregroundStyle(.secondary)
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
                        + "On Watch Simulator, use Seed demo snapshot when absent."
                )
                .font(.callout)
            } header: {
                Text("Honesty")
            } footer: {
                Text("visionOS companion is still deferred (JP-P2-F watch-only).")
            }
        }
        .navigationTitle("Watch companion")
        .accessibilityIdentifier("watchCompanionDemoScreen")
    }
}

#Preview("Watch companion demo") {
    NavigationStack {
        WatchCompanionDemoView()
    }
}
