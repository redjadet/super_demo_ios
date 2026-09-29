//
//  FlutterModuleDemoView.swift
//  superDemoApp
//
//  Engineering demo: present embedded Flutter module or honest unavailable state.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(Flutter)
import Flutter
#endif

struct FlutterModuleDemoView: View {
    var body: some View {
        Group {
            #if canImport(Flutter) && os(iOS)
            // Native outcome chrome above the embed: SwiftUI `.accessibilityIdentifier`
            // on `UIViewControllerRepresentable` is not exposed through
            // `FlutterViewController`, so XCTest must see a sibling native id
            // (not the host `flutterAddToAppDemoScreen` alone).
            VStack(spacing: 0) {
                Text("Flutter module embedded")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .accessibilityIdentifier("flutterAddToAppEmbedded")
                    .accessibilityLabel("Embedded Flutter add-to-app module")

                FlutterModuleRepresentable()
                    .ignoresSafeArea(edges: .bottom)
            }
            #else
            FlutterModuleUnavailableView()
            #endif
        }
        .navigationTitle("Flutter add-to-app")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .accessibilityIdentifier("flutterAddToAppDemoScreen")
        .accessibilityLabel("Flutter add-to-app Engineering demo")
    }
}

#if canImport(Flutter) && os(iOS)
private struct FlutterModuleRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> FlutterViewController {
        let controller = FlutterAddToAppHost.makeViewController()
        Self.applyEmbeddedAccessibility(to: controller)
        return controller
    }

    func updateUIViewController(_ uiViewController: FlutterViewController, context _: Context) {
        // Re-apply: Flutter may replace or clear root-view accessibility after run.
        Self.applyEmbeddedAccessibility(to: uiViewController)
    }

    private static func applyEmbeddedAccessibility(to controller: FlutterViewController) {
        controller.view.accessibilityIdentifier = "flutterAddToAppEmbedded"
        controller.view.accessibilityLabel = "Embedded Flutter add-to-app module"
    }
}
#endif

private struct FlutterModuleUnavailableView: View {
    var body: some View {
        Form {
            Section {
                Text(
                    "Flutter frameworks are not linked in this binary. "
                        + "This is expected on Mac builds and on iOS builds without "
                        + "`./tool/prepare_flutter_embed.sh`."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("flutterAddToAppUnavailable")
                .accessibilityLabel("Flutter frameworks are not linked in this binary")
            }

            Section("How to run the real embed") {
                Text(
                    "1. Install Flutter stable on macOS.\n"
                        + "2. From repo root: `./tool/prepare_flutter_embed.sh`.\n"
                        + "3. Build/run the iOS Simulator destination (not Mac).\n"
                        + "4. Open Engineering demos → Flutter add-to-app module."
                )
                .font(.footnote)
            }

            Section("Still available without Flutter SDK") {
                NavigationLink {
                    HostBridgePingDemoView()
                } label: {
                    Label("Native host bridge ping", systemImage: "cable.connector")
                }
                .accessibilityIdentifier("flutterAddToAppHostBridgeLink")
                .accessibilityLabel("Open native host bridge ping demo")
            }

            Section("Honesty") {
                Text(
                    "Portfolio demo only. Hosted CI prepares unsigned Flutter frameworks "
                        + "(`--no-codesign`) on the iPhone lane; Mac platform builds skip Flutter."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("flutterAddToAppUnavailableScreen")
        .accessibilityLabel("Flutter add-to-app unavailable")
    }
}

#Preview {
    NavigationStack {
        FlutterModuleDemoView()
    }
}
