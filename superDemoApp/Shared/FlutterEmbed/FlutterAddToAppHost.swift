//
//  FlutterAddToAppHost.swift
//  superDemoApp
//
//  Owns the shared FlutterEngine for add-to-app embedding (iOS only).
//

import Foundation

#if canImport(Flutter)
import Flutter
#if canImport(FlutterPluginRegistrant)
import FlutterPluginRegistrant
#endif
#endif

/// Process-wide Flutter engine for the portfolio add-to-app demo.
@MainActor
enum FlutterAddToAppHost {
    /// Whether this binary was linked with Flutter frameworks.
    /// Compile-time constant — safe off the main actor for Swift Testing.
    nonisolated static var isEmbedded: Bool {
        #if canImport(Flutter)
        true
        #else
        false
        #endif
    }

    #if canImport(Flutter)
    private static var engine: FlutterEngine?
    private static var channel: FlutterMethodChannel?

    /// Lazily start the Flutter engine and register the host-bridge channel.
    ///
    /// Resolve `makeFacade()` in the body — default args are nonisolated under
    /// `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`.
    static func sharedEngine(facade: NativePlatformFacade? = nil) -> FlutterEngine {
        if let engine {
            return engine
        }
        let resolved = facade ?? HostBridgeComposition.makeFacade()
        let engine = FlutterEngine(name: "superDemoApp.flutter.host")
        engine.run()
        #if canImport(FlutterPluginRegistrant)
        GeneratedPluginRegistrant.register(with: engine)
        #endif
        self.channel = FlutterHostBridgeChannel.register(
            on: engine.binaryMessenger,
            facade: resolved
        )
        self.engine = engine
        return engine
    }

    /// Fresh `FlutterViewController` bound to the shared engine.
    static func makeViewController(facade: NativePlatformFacade? = nil) -> FlutterViewController {
        FlutterViewController(
            engine: self.sharedEngine(facade: facade),
            nibName: nil,
            bundle: nil
        )
    }
    #endif
}
