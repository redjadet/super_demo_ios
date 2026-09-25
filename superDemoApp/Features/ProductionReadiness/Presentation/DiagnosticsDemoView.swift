//
//  DiagnosticsDemoView.swift
//  superDemoApp
//

import SwiftUI

/// Engineering-demo surface for OSLog diagnostics and crash-monitor swap point.
struct DiagnosticsDemoView: View {
    var body: some View {
        List {
            Section("What is wired") {
                LabeledContent("Non-fatal recorder", value: "OSLogCrashMonitor")
                LabeledContent("Release checks", value: "ReleaseDiagnostics")
                LabeledContent("Subsystem", value: "com.ilkersevim.superDemoApp")
            }

            Section("OSLog categories") {
                Text("release-checks — pass/fail release gates")
                Text("device-only-failures — device-scoped failures")
                Text("crash-monitor — non-fatal mirror of the above")
                Text("networking — RedactedAPILogger (host/status/attempt)")
            }

            Section("OSLog vs crash reports") {
                Text(
                    """
                    OSLog non-fatal events are Console diagnostics only. They are not vendor \
                    crash reports. Swap CrashMonitoring for Crashlytics/Sentry (or equivalent) \
                    before expecting Organizer or a crash dashboard — see docs/incident-playbook.md.
                    """
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Approved fields") {
                Text(
                    """
                    Pass stable check names, area labels, hosts, status codes — never tokens, \
                    passwords, or Authorization headers. DiagnosticRedaction is a backstop.
                    """
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Diagnostics")
        .iosLargeNavigationBarTitle()
        .accessibilityIdentifier("diagnosticsDemoScreen")
    }
}

#Preview("Diagnostics demo") {
    NavigationStack {
        DiagnosticsDemoView()
    }
}
