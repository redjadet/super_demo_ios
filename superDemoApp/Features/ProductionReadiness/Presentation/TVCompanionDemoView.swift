//
//  TVCompanionDemoView.swift
//  superDemoApp
//
//  iPhone demo that describes the tvOS Feed companion and its limits.
//

import SwiftUI

struct TVCompanionDemoView: View {
    var body: some View {
        List {
            Section {
                Text("tvOS Feed snapshot companion")
                    .font(.headline)
                    .accessibilityIdentifier("tvCompanionDemoTitle")
                    .accessibilityLabel("tvOS Feed snapshot companion")
                Text(
                    "The Apple TV app reads the same Feed widget App Group snapshot "
                        + "DTO (`feed-widget-snapshot.json`) and honest states "
                        + "(unavailable / absent / corrupt / expired / ok)."
                )
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("tvCompanionDemoSummary")
                .accessibilityLabel(
                    "tvOS companion reads the Feed widget App Group snapshot with honest states."
                )
            } header: {
                Text("Surface")
            }

            Section {
                LabeledContent("tvOS bundle") {
                    Text("com.ilkersevim.superDemoApp.tvos")
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
                LabeledContent("Scheme") {
                    Text("superDemoAppTV")
                        .font(.caption.monospaced())
                }
            } header: {
                Text("Identifiers")
            }

            Section {
                Text(
                    "iPhone and Apple TV do not share one App Group disk. "
                        + "Each process has a local container with the same group ID. "
                        + "This demo does not claim phone→TV sync. "
                        + "On tvOS Simulator, use Seed demo snapshot when absent. "
                        + "The watchOS companion uses the same DTO and honesty contract."
                )
                .font(.callout)
                .accessibilityIdentifier("tvCompanionDemoHonesty")
                .accessibilityLabel(
                    "tvOS App Group is local only. No phone to TV sync is claimed."
                )
            } header: {
                Text("Honesty")
            } footer: {
                Text("A visionOS companion app is not included in this sample.")
            }
        }
        .navigationTitle("TV companion")
        .accessibilityIdentifier("tvCompanionDemoScreen")
        .accessibilityLabel("tvOS companion Engineering demo")
    }
}

#Preview("TV companion demo") {
    NavigationStack {
        TVCompanionDemoView()
    }
}

#Preview("TV companion demo dark") {
    NavigationStack {
        TVCompanionDemoView()
    }
    .preferredColorScheme(.dark)
}
