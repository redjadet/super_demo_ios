//
//  AppPerformanceSignposts.swift
//  superDemoApp
//

import os

/// Shared OSSignposter handles for Instruments `os_signpost` timelines.
enum AppPerformanceSignposts {
    static let subsystem = "com.ilkersevim.superDemoApp"

    static let feed = OSSignposter(subsystem: Self.subsystem, category: "Feed")
    static let uiKitShowcase = OSSignposter(subsystem: Self.subsystem, category: "UIKitShowcase")
}
