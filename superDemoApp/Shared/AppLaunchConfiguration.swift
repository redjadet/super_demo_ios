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
