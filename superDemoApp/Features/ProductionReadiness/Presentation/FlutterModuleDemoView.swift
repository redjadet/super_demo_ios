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
            // Native outcome chrome — SwiftUI id on UIViewControllerRepresentable is not
            // exposed through FlutterViewController. Keep Flutter itself out of the
            // a11y tree so XCTest descendant queries do not hang on the embed.
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
                    .accessibilityHidden(true)
            }
            #else
            FlutterModuleUnavailableView()
            #endif
        }
        .navigationTitle("Flutter add-to-app")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        // Parent id+label alone would collapse children (false-green on host id;
        // embedded / unavailable chrome invisible to XCTest). Contain children.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("flutterAddToAppDemoScreen")
        .accessibilityLabel("Flutter add-to-app Engineering demo")
    }
}

#if canImport(Flutter) && os(iOS)
private struct FlutterModuleRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> FlutterViewController {
        FlutterAddToAppHost.makeViewController()
    }

    func updateUIViewController(_: FlutterViewController, context _: Context) {
        // No-op: engine + MethodChannel are owned by FlutterAddToAppHost.
        // Do not stamp UIKit a11y on FlutterViewController.view — that pulls the
        // Flutter semantics tree into XCTest queries and can hang the suite.
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
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("flutterAddToAppUnavailableScreen")
        .accessibilityLabel("Flutter add-to-app unavailable")
    }
}

#Preview {
    NavigationStack {
        FlutterModuleDemoView()
    }
}
