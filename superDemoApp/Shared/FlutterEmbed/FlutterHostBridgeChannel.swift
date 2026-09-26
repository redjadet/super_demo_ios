//
//  FlutterHostBridgeChannel.swift
//  superDemoApp
//
//  MethodChannel ↔ NativePlatformFacade (JP-P0-C).
//

import Foundation

#if canImport(Flutter)
import Flutter
#endif

nonisolated enum FlutterHostBridgeChannel {
    /// Must match Dart `kHostBridgeChannel`.
    static let channelName = "com.ilkersevim.superDemoApp/host_bridge"
    /// Must match Dart `kInvokeHostBridge`.
    static let invokeMethod = "invoke"

    #if canImport(Flutter)
    /// Register the host-bridge MethodChannel on a Flutter engine binary messenger.
    ///
    /// Resolve `makeFacade()` in the body — default args are nonisolated under
    /// `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`.
    @MainActor
    static func register(
        on messenger: FlutterBinaryMessenger,
        facade: NativePlatformFacade? = nil
    ) -> FlutterMethodChannel {
        let resolved = facade ?? HostBridgeComposition.makeFacade()
        let channel = FlutterMethodChannel(
            name: Self.channelName,
            binaryMessenger: messenger
        )
        channel.setMethodCallHandler { call, result in
            guard call.method == Self.invokeMethod else {
                result(FlutterMethodNotImplemented)
                return
            }
            guard let payload = call.arguments as? String,
                  let data = payload.data(using: .utf8)
            else {
                result(
                    FlutterError(
                        code: HostBridgeErrorCode.malformedJSON.rawValue,
                        message: "Expected UTF-8 JSON string argument.",
                        details: nil
                    )
                )
                return
            }
            do {
                let responseData = try resolved.handle(data)
                let response = String(data: responseData, encoding: .utf8) ?? ""
                result(response)
            } catch is CancellationError {
                result(
                    FlutterError(
                        code: HostBridgeErrorCode.cancelled.rawValue,
                        message: "Request was cancelled.",
                        details: nil
                    )
                )
            } catch {
                result(
                    FlutterError(
                        code: HostBridgeErrorCode.unavailable.rawValue,
                        message: error.localizedDescription,
                        details: nil
                    )
                )
            }
        }
        return channel
    }
    #endif
}
