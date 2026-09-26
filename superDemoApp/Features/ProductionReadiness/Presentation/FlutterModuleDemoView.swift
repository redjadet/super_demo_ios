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
            FlutterModuleRepresentable()
                .ignoresSafeArea(edges: .bottom)
                .accessibilityIdentifier("flutterAddToAppEmbedded")
            #else
            FlutterModuleUnavailableView()
            #endif
        }
        .navigationTitle("Flutter add-to-app")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .accessibilityIdentifier("flutterAddToAppDemoScreen")
    }
}

#if canImport(Flutter) && os(iOS)
private struct FlutterModuleRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> FlutterViewController {
        FlutterAddToAppHost.makeViewController()
    }

    func updateUIViewController(_: FlutterViewController, context _: Context) {
        // No-op: engine + MethodChannel are owned by FlutterAddToAppHost.
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
    }
}

#Preview {
    NavigationStack {
        FlutterModuleDemoView()
    }
}
