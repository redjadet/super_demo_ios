//
//  AppLaunchConfiguration.swift
//  superDemoApp
//

import Foundation

enum AppLaunchConfiguration {
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITesting")
    }

    static var usesFailingFeedFixture: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITestingFeedFailure")
    }
}
