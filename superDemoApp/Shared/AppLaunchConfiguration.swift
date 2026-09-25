//
//  AppLaunchConfiguration.swift
//  superDemoApp
//

import Foundation

enum AppLaunchConfiguration {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITesting")
    }

    static var isReviewerDemoMode: Bool {
        self.isReviewerDemoMode(
            arguments: ProcessInfo.processInfo.arguments,
            environment: ProcessInfo.processInfo.environment
        )
    }

    static var usesSeededSampleState: Bool {
        self.isUITesting || self.isReviewerDemoMode
    }

    static var usesFailingFeedFixture: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITestingFeedFailure")
    }

    /// Deterministic Feed stale-cache demo: seed SwiftData cache + failing remote.
    /// Launch with `-StaleFeedDemo` or `SUPERDEMO_STALE_FEED_DEMO=1`.
    static var usesStaleFeedFixture: Bool {
        self.usesStaleFeedFixture(
            arguments: ProcessInfo.processInfo.arguments,
            environment: ProcessInfo.processInfo.environment
        )
    }

    /// Opt-in Keychain-backed demo token refresher for portfolio auth wiring.
    /// Launch with `-KeychainTokenDemo` or `SUPERDEMO_KEYCHAIN_TOKEN_DEMO=1`.
    static var usesKeychainTokenDemo: Bool {
        self.usesKeychainTokenDemo(
            arguments: ProcessInfo.processInfo.arguments,
            environment: ProcessInfo.processInfo.environment
        )
    }

    static func usesStaleFeedFixture(
        arguments: [String],
        environment: [String: String]
    ) -> Bool {
        if arguments.contains("-StaleFeedDemo") {
            return true
        }
        return environment["SUPERDEMO_STALE_FEED_DEMO"] == "1"
    }

    static func usesKeychainTokenDemo(
        arguments: [String],
        environment: [String: String]
    ) -> Bool {
        if arguments.contains("-KeychainTokenDemo") {
            return true
        }
        return environment["SUPERDEMO_KEYCHAIN_TOKEN_DEMO"] == "1"
    }

    static func isReviewerDemoMode(
        arguments: [String],
        environment: [String: String]
    ) -> Bool {
        if arguments.contains("-ReviewerDemoMode") {
            return true
        }

        if environment["SUPERDEMO_REVIEWER_DEMO_MODE"] == "1" {
            return true
        }

        return self.includesReviewerDemoBuildFlag
    }

    private static var includesReviewerDemoBuildFlag: Bool {
        #if REVIEWER_DEMO
        true
        #else
        false
        #endif
    }
}
