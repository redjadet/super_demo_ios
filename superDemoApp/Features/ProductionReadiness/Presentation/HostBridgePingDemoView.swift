//
//  HostBridgePingDemoView.swift
//  superDemoApp
//
//  Engineering demo: ping native host-bridge facade (JP-P0-C).
//

import SwiftUI

struct HostBridgePingDemoView: View {
    private let facade: NativePlatformFacade
    @State private var requestJSON: String = """
    {"v":1,"method":"feed.cacheStatus","id":"demo-1"}
    """
    @State private var responseText: String = "Tap Ping to call the native facade."
    @State private var isBusy = false

    init(facade: NativePlatformFacade = HostBridgeComposition.makeFacade()) {
        self.facade = facade
    }

    var body: some View {
        Form {
            Section {
                Text(
                    "Native contract demo (codec + feed.cacheStatus). For the embedded "
                        + "Flutter UI that calls the same facade, open "
                        + "**Flutter add-to-app module**."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Request JSON") {
                TextEditor(text: self.$requestJSON)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 88)
                    .accessibilityIdentifier("hostBridgeRequestEditor")
            }

            Section("Response") {
                Text(self.responseText)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .accessibilityIdentifier("hostBridgeResponseText")
            }

            Section {
                Button {
                    self.ping()
                } label: {
                    if self.isBusy {
                        ProgressView()
                    } else {
                        Text("Ping feed.cacheStatus")
                    }
                }
                .disabled(self.isBusy)
                .accessibilityIdentifier("hostBridgePingButton")
            }
        }
        .navigationTitle("Host bridge")
    }

    @MainActor
    private func ping() {
        self.isBusy = true
        defer { self.isBusy = false }
        guard let data = self.requestJSON.data(using: .utf8) else {
            self.responseText = "Request is not valid UTF-8."
            return
        }
        do {
            let response = try self.facade.handle(data)
            self.responseText = String(data: response, encoding: .utf8) ?? "<binary>"
        } catch is CancellationError {
            self.responseText = #"{"ok":false,"error":{"code":"cancelled"}}"#
        } catch {
            self.responseText = "Encode/handle failed: \(error.localizedDescription)"
        }
    }
}
