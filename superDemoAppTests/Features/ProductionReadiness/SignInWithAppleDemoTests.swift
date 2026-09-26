//
//  SignInWithAppleDemoTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("Sign in with Apple demo")
struct SignInWithAppleDemoTests {
    @MainActor
    @Test
    func signedInMapsCredential() async {
        let spy = SpySignInWithAppleDemo(result: .success(
            SignInWithAppleDemoCredential(userID: "u1", email: "a@b.c", fullName: "Ada")
        ))
        let model = SignInWithAppleDemoModel(demo: spy)
        await model.signIn()
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
        let spy = SpySignInWithAppleDemo(
            result: .failure(.unavailable(reason: "Simulator"))
        )
        let model = SignInWithAppleDemoModel(demo: spy)
        await model.signIn()
        guard case let .unavailable(message) = model.state else {
            Issue.record("Expected unavailable, got \(model.state)")
            return
        }
        #expect(message == "Simulator")
    }

    @MainActor
    @Test
    func cancelledMapsState() async {
        let spy = SpySignInWithAppleDemo(result: .failure(.cancelled))
        let model = SignInWithAppleDemoModel(demo: spy)
        await model.signIn()
        #expect(model.state == .cancelled)
    }
}

@MainActor
private final class SpySignInWithAppleDemo: SignInWithAppleDemoing {
    private let result: Result<SignInWithAppleDemoCredential, SignInWithAppleDemoFailure>

    init(result: Result<SignInWithAppleDemoCredential, SignInWithAppleDemoFailure>) {
        self.result = result
    }

    func signIn() async throws -> SignInWithAppleDemoCredential {
        try self.result.get()
    }
}
