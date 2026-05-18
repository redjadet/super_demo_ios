//
//  LegacyRiskCodeFormatterTests.swift
//  superDemoAppTests
//

import Testing
@testable import superDemoApp

@Suite("Legacy Objective-C bridge")
struct LegacyRiskCodeFormatterTests {
    @Test
    func sanitizesRiskCodesThroughLimitedSwiftWrapper() {
        let formatter = LegacyRiskCodeFormatter()

        #expect(formatter.code(title: "Push Notifications!", owner: "ios") == "IOS-PUSH-NOTIFICATIONS")
    }
}
