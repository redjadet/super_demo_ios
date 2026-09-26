//
//  HostBridgeComposition.swift
//  superDemoApp
//

import Foundation

nonisolated enum HostBridgeComposition {
    /// App-owned facade wired to App Group Feed snapshot honesty.
    static func makeFacade() -> NativePlatformFacade {
        NativePlatformFacade(cacheStatusProvider: SnapshotFeedCacheStatusProvider())
    }
}
