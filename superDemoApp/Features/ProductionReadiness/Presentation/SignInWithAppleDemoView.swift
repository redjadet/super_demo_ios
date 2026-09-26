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

    /// - Parameter demo: Injected for tests/previews. `nil` uses button-driven live SIWA.
    init(demo: (any SignInWithAppleDemoing)? = nil) {
        self._model = State(initialValue: SignInWithAppleDemoModel(demo: demo))
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
                if self.model.usesInjectedDemo {
                    Button("Run injected SIWA demo") {
                        Task { await self.model.signInWithInjectedDemo() }
                    }
                    .disabled(self.model.isBusy)
                    .accessibilityIdentifier("signInWithAppleRun")
                } else {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task { await self.model.handleAuthorization(result) }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .accessibilityIdentifier("signInWithAppleButton")
                }
            }

            switch self.model.state {
            case .idle:
                Section("Status") {
                    Text("Use Sign in with Apple to request a credential.")
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

    private let demo: (any SignInWithAppleDemoing)?

    private(set) var state: State = .idle
    private(set) var isBusy = false

    var usesInjectedDemo: Bool { self.demo != nil }

    init(demo: (any SignInWithAppleDemoing)?) {
        self.demo = demo
    }

    func signInWithInjectedDemo() async {
        guard let demo else { return }
        self.isBusy = true
        self.state = .loading
        defer { self.isBusy = false }
        do {
            let credential = try await demo.signIn()
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

    func handleAuthorization(_ result: Result<ASAuthorization, Error>) async {
        self.isBusy = true
        self.state = .loading
        defer { self.isBusy = false }
        switch result {
        case let .success(authorization):
            do {
                let credential = try SignInWithAppleDemoMapping.credential(from: authorization)
                self.state = .signedIn(credential)
            } catch let SignInWithAppleDemoFailure.failed(reason) {
                self.state = .failed(reason)
            } catch {
                self.state = .failed(error.localizedDescription)
            }
        case let .failure(error):
            switch SignInWithAppleDemoMapping.failure(from: error) {
            case .cancelled:
                self.state = .cancelled
            case let .unavailable(reason):
                self.state = .unavailable(reason)
            case let .failed(reason):
                self.state = .failed(reason)
            }
        }
    }
}

#Preview("SIWA — signed in") {
    NavigationStack {
        SignInWithAppleDemoView(
            demo: InjectedSignInWithAppleDemo(result: .success(
                SignInWithAppleDemoCredential(
                    userID: "demo.user.001",
                    email: "demo@privaterelay.appleid.com",
                    fullName: "Demo Reviewer"
                )
            ))
        )
    }
}

#Preview("SIWA — unavailable") {
    NavigationStack {
        SignInWithAppleDemoView(
            demo: InjectedSignInWithAppleDemo(result: .failure(
                .unavailable(reason: "Preview: Simulator-honest unavailable.")
            ))
        )
    }
}
