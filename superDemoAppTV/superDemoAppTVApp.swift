//
//  superDemoAppTVApp.swift
//  superDemoAppTV
//
//  Thin tvOS companion. Reads the same Feed App Group snapshot DTO as the
//  Home Screen widget and watchOS companion — tv-local container only.
//

import SwiftUI

@main
struct SuperDemoAppTVApp: App {
    var body: some Scene {
        WindowGroup {
            FeedTVSnapshotView()
        }
    }
}
