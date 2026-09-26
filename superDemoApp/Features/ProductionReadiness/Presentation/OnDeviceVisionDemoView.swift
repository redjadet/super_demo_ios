//
//  OnDeviceVisionDemoView.swift
//  superDemoApp
//
//  Engineering demo: on-device Vision text recognition (JP-P2-C).
//

import SwiftUI

/// Engineering demo: Vision OCR on a synthetic/bundled sample — not Apple Intelligence.
struct OnDeviceVisionDemoView: View {
    @State private var model: OnDeviceVisionDemoModel

    init(demo: (any OnDeviceVisionDemoing)? = nil) {
        let resolved = demo ?? SystemOnDeviceVisionDemo()
        self._model = State(initialValue: OnDeviceVisionDemoModel(demo: resolved))
    }

    var body: some View {
        List {
            Section("Honesty") {
                Text(
                    """
                    On-device Vision text recognition demo only (VNRecognizeTextRequest). \
                    No Core ML model download, no Speech, no Apple Intelligence entitlement \
                    or API claim. Unavailable OS/device states are labeled honestly.
                    """
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Recognize") {
                Button("Recognize text in sample image") {
                    Task { await self.model.run() }
                }
                .disabled(self.model.isBusy)
                .accessibilityIdentifier("visionRecognizeRun")
            }

            switch self.model.state {
            case .idle:
                Section("Status") {
                    Text("Tap Recognize to run Vision on a synthetic sample bitmap.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("visionStatusIdle")
                }
            case .loading:
                Section("Status") {
                    ProgressView("Running Vision…")
                        .accessibilityIdentifier("visionStatusLoading")
                }
            case let .recognized(lines):
                Section("Lines (\(lines.count))") {
                    ForEach(lines) { line in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(line.text)
                                .font(.body)
                            Text("confidence \(line.confidence, format: .number.precision(.fractionLength(2)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityIdentifier("visionLine_\(line.id.uuidString)")
                    }
                }
            case .noText:
                Section("Status") {
                    ContentUnavailableView(
                        "No text recognized",
                        systemImage: "text.viewfinder",
                        description: Text("Vision returned zero candidates for the sample image.")
                    )
                    .accessibilityIdentifier("visionStatusNoText")
                }
            case let .unavailable(message):
                Section("Unavailable") {
                    ContentUnavailableView(
                        "Vision unavailable",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                    .accessibilityIdentifier("visionStatusUnavailable")
                }
            case let .failed(message):
                Section("Failed") {
                    ContentUnavailableView(
                        "Vision failed",
                        systemImage: "xmark.octagon",
                        description: Text(message)
                    )
                    .accessibilityIdentifier("visionStatusFailed")
                }
            }
        }
        .navigationTitle("On-device Vision")
        .iosLargeNavigationBarTitle()
        .accessibilityIdentifier("onDeviceVisionDemoScreen")
    }
}

@MainActor
@Observable
final class OnDeviceVisionDemoModel {
    enum State: Equatable {
        case idle
        case loading
        case recognized([VisionDemoObservation])
        case noText
        case unavailable(String)
        case failed(String)
    }

    private let demo: any OnDeviceVisionDemoing

    private(set) var state: State = .idle
    private(set) var isBusy = false

    init(demo: any OnDeviceVisionDemoing) {
        self.demo = demo
    }

    func run() async {
        self.isBusy = true
        self.state = .loading
        defer { self.isBusy = false }
        do {
            let lines = try await self.demo.recognizeText()
            self.state = .recognized(lines)
        } catch is CancellationError {
            self.state = .idle
        } catch VisionDemoFailure.noText {
            self.state = .noText
        } catch let VisionDemoFailure.unavailable(reason) {
            self.state = .unavailable(reason)
        } catch let VisionDemoFailure.failed(reason) {
            self.state = .failed(reason)
        } catch {
            self.state = .failed(error.localizedDescription)
        }
    }
}

#Preview("Vision — recognized") {
    NavigationStack {
        OnDeviceVisionDemoView(demo: PreviewOnDeviceVisionDemo(mode: .lines))
    }
}

@MainActor
private final class PreviewOnDeviceVisionDemo: OnDeviceVisionDemoing {
    enum Mode {
        case lines
        case unavailable
    }

    private let mode: Mode

    init(mode: Mode) {
        self.mode = mode
    }

    func recognizeText() async throws -> [VisionDemoObservation] {
        await Task.yield()
        switch self.mode {
        case .lines:
            return [
                VisionDemoObservation(text: "superDemo Vision", confidence: 0.99),
            ]
        case .unavailable:
            throw VisionDemoFailure.unavailable(reason: "Preview unavailable")
        }
    }
}
