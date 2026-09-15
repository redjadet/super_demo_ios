//
//  AppPerformanceSignposts.swift
//  superDemoApp
//

import os

/// Shared OSSignposter handles for Instruments `os_signpost` timelines.
enum AppPerformanceSignposts {
    nonisolated static let subsystem = "com.ilkersevim.superDemoApp"

    nonisolated static let feed = OSSignposter(subsystem: subsystem, category: "Feed")
    nonisolated static let uiKitShowcase = OSSignposter(subsystem: subsystem, category: "UIKitShowcase")
}
