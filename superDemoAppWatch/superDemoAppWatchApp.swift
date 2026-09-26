//
//  superDemoAppWatchApp.swift
//  superDemoAppWatch
//
//  Thin watchOS companion (JP-P2-F). Reads the same Feed App Group snapshot
//  DTO as the Home Screen widget — watch-local container only.
//

import SwiftUI

@main
struct SuperDemoAppWatchApp: App {
    var body: some Scene {
        WindowGroup {
            FeedWatchSnapshotView()
        }
    }
}
