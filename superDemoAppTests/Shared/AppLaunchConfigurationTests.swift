//
//  AppLaunchConfigurationTests.swift
//  superDemoAppTests
//

import Testing
@testable import superDemoApp

@Suite("App launch configuration")
struct AppLaunchConfigurationTests {
    @Test
    func reviewerDemoModeUsesExplicitLaunchArgument() {
        #expect(AppLaunchConfiguration.isReviewerDemoMode(
            arguments: ["-ReviewerDemoMode"],
            environment: [:]
        ))
    }

    @Test
    func reviewerDemoModeUsesExplicitEnvironmentValue() {
        #expect(AppLaunchConfiguration.isReviewerDemoMode(
            arguments: [],
            environment: ["SUPERDEMO_REVIEWER_DEMO_MODE": "1"]
        ))
    }

    @Test
    func reviewerDemoModeStaysOffForNormalLaunches() {
        #expect(!AppLaunchConfiguration.isReviewerDemoMode(
            arguments: [],
            environment: [:]
        ))
    }
}
