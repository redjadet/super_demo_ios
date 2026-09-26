//
//  SignInWithAppleDemo.swift
//  superDemoApp
//
//  Sign in with Apple demo surface (JP-P2-B). Separate from Keychain token refresher.
//

import AuthenticationServices
import Foundation

/// Display DTO — no ASAuthorization types leak into the demo view model.
struct SignInWithAppleDemoCredential: Equatable, Sendable {
    let userID: String
    let email: String?
    let fullName: String?
}

enum SignInWithAppleDemoFailure: Error, Equatable, Sendable {
    case cancelled
    case unavailable(reason: String)
    case failed(reason: String)
}

@MainActor
protocol SignInWithAppleDemoing: AnyObject {
    func signIn() async throws -> SignInWithAppleDemoCredential
}

/// Maps `ASAuthorization` / Apple ID errors into demo DTOs (no UIApplication access).
enum SignInWithAppleDemoMapping {
    static func credential(from authorization: ASAuthorization) throws -> SignInWithAppleDemoCredential {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw SignInWithAppleDemoFailure.failed(reason: "Unexpected credential type.")
        }
        let fullName: String? = {
            guard let components = credential.fullName else { return nil }
            let formatter = PersonNameComponentsFormatter()
            let formatted = formatter.string(from: components)
            return formatted.isEmpty ? nil : formatted
        }()
        return SignInWithAppleDemoCredential(
            userID: credential.user,
            email: credential.email,
            fullName: fullName
        )
    }

    static func failure(from error: Error) -> SignInWithAppleDemoFailure {
        let nsError = error as NSError
        // Nested single-line `if`s keep SwiftFormat + SwiftLint opening_brace happy
        // without multiline statement braces or >120 char lines.
        if nsError.domain == ASAuthorizationError.errorDomain {
            if nsError.code == ASAuthorizationError.canceled.rawValue {
                return .cancelled
            }
            if nsError.code == ASAuthorizationError.unknown.rawValue {
                return .unavailable(
                    reason: """
                    Sign in with Apple unavailable in this environment \
                    (common on Simulator without an Apple ID / capability). \
                    Not production auth.
                    """
                )
            }
        }
        return .failed(reason: error.localizedDescription)
    }
}

/// Demo driver that completes via an injected authorization result (tests / previews).
/// Live SIWA uses `SignInWithAppleButton` in the Engineering demo view (no shared
/// UIApplication presentation anchor — universal-app lint).
@MainActor
final class InjectedSignInWithAppleDemo: SignInWithAppleDemoing {
    private let result: Result<SignInWithAppleDemoCredential, SignInWithAppleDemoFailure>

    init(result: Result<SignInWithAppleDemoCredential, SignInWithAppleDemoFailure>) {
        self.result = result
    }

    func signIn() async throws -> SignInWithAppleDemoCredential {
        // Yield so the protocol stays async for live/injected symmetry.
        await Task.yield()
        return try self.result.get()
    }
}
