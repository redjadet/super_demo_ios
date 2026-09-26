//
//  SignInWithAppleDemoView.swift
//  superDemoApp
//
//  Engineering demo: Sign in with Apple (JP-P2-B). Labeled demo — not production auth.
//

import AuthenticationServices
import SwiftUI

/// Engineering demo: SIWA credential flow or honest Simulator/unavailable state.
struct SignInWithAppleDemoView: View {
    @State private var model: SignInWithAppleDemoModel

    init(demo: (any SignInWithAppleDemoing)? = nil) {
        let resolved = demo ?? SystemSignInWithAppleDemo()
        self._model = State(initialValue: SignInWithAppleDemoModel(demo: resolved))
    }

    var body: some View {
        List {
            Section("Honesty") {
                Text(
                    """
                    Sign in with Apple demo only. Separate from the Keychain \
                    token refresher. Never claims production OAuth / App Store \
                    account linking. Simulator often returns unavailable without \
                    an Apple ID — that is an honest limitation, not a fake success.
                    """
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Section("Sign in") {
                Button("Run Sign in with Apple request") {
                    Task { await self.model.signIn() }
                }
                .disabled(self.model.isBusy)
                .accessibilityIdentifier("signInWithAppleRun")
            }

            switch self.model.state {
            case .idle:
                Section("Status") {
                    Text("Tap Run to request an Apple ID credential via AuthenticationServices.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("siwaStatusIdle")
                }
            case .loading:
                Section("Status") {
                    ProgressView("Requesting credential…")
                        .accessibilityIdentifier("siwaStatusLoading")
                }
            case let .signedIn(credential):
                Section("Credential (demo)") {
                    LabeledContent("User ID", value: credential.userID)
                    LabeledContent("Email", value: credential.email ?? "(not provided)")
                    LabeledContent("Name", value: credential.fullName ?? "(not provided)")
                }
                .accessibilityIdentifier("siwaStatusSignedIn")
            case .cancelled:
                Section("Status") {
                    Text("User cancelled Sign in with Apple.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("siwaStatusCancelled")
                }
            case let .unavailable(message):
                Section("Unavailable") {
                    ContentUnavailableView(
                        "Sign in with Apple unavailable",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text(message)
                    )
                    .accessibilityIdentifier("siwaStatusUnavailable")
                }
            case let .failed(message):
                Section("Failed") {
                    ContentUnavailableView(
                        "Sign in failed",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                    .accessibilityIdentifier("siwaStatusFailed")
                }
            }
        }
        .navigationTitle("Sign in with Apple")
        .iosLargeNavigationBarTitle()
        .accessibilityIdentifier("signInWithAppleDemoScreen")
    }
}

@MainActor
@Observable
final class SignInWithAppleDemoModel {
    enum State: Equatable {
        case idle
        case loading
        case signedIn(SignInWithAppleDemoCredential)
        case cancelled
        case unavailable(String)
        case failed(String)
    }

    private let demo: any SignInWithAppleDemoing

    private(set) var state: State = .idle
    private(set) var isBusy = false

    init(demo: any SignInWithAppleDemoing) {
        self.demo = demo
    }

    func signIn() async {
        self.isBusy = true
        self.state = .loading
        defer { self.isBusy = false }
        do {
            let credential = try await self.demo.signIn()
            self.state = .signedIn(credential)
        } catch is CancellationError {
            self.state = .idle
        } catch SignInWithAppleDemoFailure.cancelled {
            self.state = .cancelled
        } catch let SignInWithAppleDemoFailure.unavailable(reason) {
            self.state = .unavailable(reason)
        } catch let SignInWithAppleDemoFailure.failed(reason) {
            self.state = .failed(reason)
        } catch {
            self.state = .failed(error.localizedDescription)
        }
    }
}

#Preview("SIWA — signed in") {
    NavigationStack {
        SignInWithAppleDemoView(demo: PreviewSignInWithAppleDemo(mode: .success))
    }
}

#Preview("SIWA — unavailable") {
    NavigationStack {
        SignInWithAppleDemoView(demo: PreviewSignInWithAppleDemo(mode: .unavailable))
    }
}

@MainActor
private final class PreviewSignInWithAppleDemo: SignInWithAppleDemoing {
    enum Mode {
        case success
        case unavailable
    }

    private let mode: Mode

    init(mode: Mode) {
        self.mode = mode
    }

    func signIn() async throws -> SignInWithAppleDemoCredential {
        await Task.yield()
        switch self.mode {
        case .success:
            return SignInWithAppleDemoCredential(
                userID: "demo.user.001",
                email: "demo@privaterelay.appleid.com",
                fullName: "Demo Reviewer"
            )
        case .unavailable:
            throw SignInWithAppleDemoFailure.unavailable(
                reason: "Preview: Simulator-honest unavailable."
            )
        }
    }
}
