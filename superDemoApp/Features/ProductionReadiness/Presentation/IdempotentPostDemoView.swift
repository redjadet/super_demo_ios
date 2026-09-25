//
//  IdempotentPostDemoView.swift
//  superDemoApp
//

import SwiftUI

@MainActor
@Observable
final class IdempotentPostDemoModel {
    private let submit: SubmitIdempotentPostDemoUseCase
    private let fixedKey: String

    private(set) var isSubmitting = false
    private(set) var lastOutcome: IdempotentPostDemoOutcome?
    private(set) var attemptCount = 0

    init(
        submit: SubmitIdempotentPostDemoUseCase,
        idempotencyKey: String = "dashboard-demo-post-1"
    ) {
        self.submit = submit
        self.fixedKey = idempotencyKey
    }

    func send() {
        guard self.isSubmitting == false else { return }
        self.isSubmitting = true
        defer { self.isSubmitting = false }
        self.attemptCount += 1
        self.lastOutcome = self.submit(idempotencyKey: self.fixedKey)
    }
}

struct IdempotentPostDemoView: View {
    @Bindable private var model: IdempotentPostDemoModel

    init(model: IdempotentPostDemoModel) {
        self.model = model
    }

    var body: some View {
        List {
            Section {
                Text(
                    """
                    Posts with an Idempotency-Key so retries are safe. Duplicate-safe responses \
                    here are simulated by an injected Data transport — not a live server.
                    """
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Action") {
                Button {
                    self.model.send()
                } label: {
                    if self.model.isSubmitting {
                        ProgressView()
                    } else {
                        Text("Send sample POST")
                    }
                }
                .disabled(self.model.isSubmitting)
                .accessibilityIdentifier("idempotentPostSendButton")

                LabeledContent("Attempts this session", value: "\(self.model.attemptCount)")
            }

            if let outcome = self.model.lastOutcome {
                Section("Result") {
                    Text(self.title(for: outcome))
                        .font(.headline)
                        .accessibilityIdentifier("idempotentPostOutcomeTitle")
                    Text(self.detail(for: outcome))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("idempotentPostOutcomeDetail")
                }
            }
        }
        .navigationTitle("Idempotent POST")
        .iosLargeNavigationBarTitle()
        .accessibilityIdentifier("idempotentPostDemoScreen")
    }

    private func title(for outcome: IdempotentPostDemoOutcome) -> String {
        switch outcome {
        case .accepted:
            "Accepted"
        case .duplicateSafeSimulated:
            "Simulated duplicate-safe"
        case .failed:
            "Failed"
        }
    }

    private func detail(for outcome: IdempotentPostDemoOutcome) -> String {
        switch outcome {
        case let .accepted(message), let .duplicateSafeSimulated(message), let .failed(message):
            message
        }
    }
}

#Preview("Idempotent POST demo") {
    NavigationStack {
        IdempotentPostDemoView(
            model: IdempotentPostDemoModel(
                submit: SubmitIdempotentPostDemoUseCase(transport: SimulatedIdempotentPostTransport())
            )
        )
    }
}
