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

    @Test
    func keychainTokenDemoUsesLaunchArgument() {
        #expect(AppLaunchConfiguration.usesKeychainTokenDemo(
            arguments: ["-KeychainTokenDemo"],
            environment: [:]
        ))
    }

    @Test
    func keychainTokenDemoUsesEnvironmentValue() {
        #expect(AppLaunchConfiguration.usesKeychainTokenDemo(
            arguments: [],
            environment: ["SUPERDEMO_KEYCHAIN_TOKEN_DEMO": "1"]
        ))
    }

    @Test
    func keychainTokenDemoStaysOffForNormalLaunches() {
        #expect(!AppLaunchConfiguration.usesKeychainTokenDemo(
            arguments: [],
            environment: [:]
        ))
    }

    @Test
    func staleFeedFixtureUsesLaunchArgument() {
        #expect(AppLaunchConfiguration.usesStaleFeedFixture(
            arguments: ["-StaleFeedDemo"],
            environment: [:]
        ))
    }

    @Test
    func staleFeedFixtureUsesEnvironmentValue() {
        #expect(AppLaunchConfiguration.usesStaleFeedFixture(
            arguments: [],
            environment: ["SUPERDEMO_STALE_FEED_DEMO": "1"]
        ))
    }

    @Test
    func staleFeedFixtureStaysOffForNormalLaunches() {
        #expect(!AppLaunchConfiguration.usesStaleFeedFixture(
            arguments: [],
            environment: [:]
        ))
    }
}
