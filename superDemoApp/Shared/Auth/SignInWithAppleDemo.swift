//
//  SignInWithAppleDemo.swift
//  superDemoApp
//
//  Sign in with Apple demo surface (JP-P2-B). Separate from Keychain token refresher.
//

import AuthenticationServices
import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

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

/// System coordinator via `ASAuthorizationController`.
/// Simulator without Apple ID / capability maps to honest `unavailable`.
@MainActor
final class SystemSignInWithAppleDemo: NSObject, SignInWithAppleDemoing {
    private var continuation: CheckedContinuation<SignInWithAppleDemoCredential, Error>?

    func signIn() async throws -> SignInWithAppleDemoCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

extension SystemSignInWithAppleDemo: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            self.continuation?.resume(
                throwing: SignInWithAppleDemoFailure.failed(reason: "Unexpected credential type.")
            )
            self.continuation = nil
            return
        }
        let fullName: String? = {
            guard let components = credential.fullName else { return nil }
            let formatter = PersonNameComponentsFormatter()
            let formatted = formatter.string(from: components)
            return formatted.isEmpty ? nil : formatted
        }()
        let demo = SignInWithAppleDemoCredential(
            userID: credential.user,
            email: credential.email,
            fullName: fullName
        )
        self.continuation?.resume(returning: demo)
        self.continuation = nil
    }

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let nsError = error as NSError
        if nsError.domain == ASAuthorizationError.errorDomain,
           nsError.code == ASAuthorizationError.canceled.rawValue
        {
            self.continuation?.resume(throwing: SignInWithAppleDemoFailure.cancelled)
        } else if nsError.domain == ASAuthorizationError.errorDomain,
                  nsError.code == ASAuthorizationError.unknown.rawValue
        {
            self.continuation?.resume(
                throwing: SignInWithAppleDemoFailure.unavailable(
                    reason: """
                    Sign in with Apple unavailable in this environment \
                    (common on Simulator without an Apple ID / capability). \
                    Not production auth.
                    """
                )
            )
        } else {
            self.continuation?.resume(
                throwing: SignInWithAppleDemoFailure.failed(reason: error.localizedDescription)
            )
        }
        self.continuation = nil
    }
}

extension SystemSignInWithAppleDemo: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        #if canImport(UIKit) && !os(watchOS)
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow) {
            return window
        }
        if let window = scenes.flatMap(\.windows).first {
            return window
        }
        return ASPresentationAnchor()
        #elseif canImport(AppKit)
        if let window = NSApplication.shared.keyWindow {
            return window
        }
        return ASPresentationAnchor()
        #else
        return ASPresentationAnchor()
        #endif
    }
}
