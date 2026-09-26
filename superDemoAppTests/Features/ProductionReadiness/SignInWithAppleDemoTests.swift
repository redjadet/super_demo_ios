//
//  SignInWithAppleDemoTests.swift
//  superDemoAppTests
//

import AuthenticationServices
import Foundation
import Testing
@testable import superDemoApp

@Suite("Sign in with Apple demo")
struct SignInWithAppleDemoTests {
    @MainActor
    @Test
    func signedInMapsCredential() async {
        let spy = InjectedSignInWithAppleDemo(result: .success(
            SignInWithAppleDemoCredential(userID: "u1", email: "a@b.c", fullName: "Ada")
        ))
        let model = SignInWithAppleDemoModel(demo: spy)
        await model.signInWithInjectedDemo()
        guard case let .signedIn(credential) = model.state else {
            Issue.record("Expected signedIn, got \(model.state)")
            return
        }
        #expect(credential.userID == "u1")
        #expect(credential.email == "a@b.c")
        #expect(credential.fullName == "Ada")
    }

    @MainActor
    @Test
    func unavailableMapsHonestState() async {
        let spy = InjectedSignInWithAppleDemo(
            result: .failure(.unavailable(reason: "Simulator"))
        )
        let model = SignInWithAppleDemoModel(demo: spy)
        await model.signInWithInjectedDemo()
        guard case let .unavailable(message) = model.state else {
            Issue.record("Expected unavailable, got \(model.state)")
            return
        }
        #expect(message == "Simulator")
    }

    @MainActor
    @Test
    func cancelledMapsState() async {
        let spy = InjectedSignInWithAppleDemo(result: .failure(.cancelled))
        let model = SignInWithAppleDemoModel(demo: spy)
        await model.signInWithInjectedDemo()
        #expect(model.state == .cancelled)
    }

    @Test
    func mapsCancelError() {
        let error = NSError(
            domain: ASAuthorizationError.errorDomain,
            code: ASAuthorizationError.canceled.rawValue
        )
        #expect(SignInWithAppleDemoMapping.failure(from: error) == .cancelled)
    }
}
