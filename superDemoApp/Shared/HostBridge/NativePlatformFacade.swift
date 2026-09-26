//
//  NativePlatformFacade.swift
//  superDemoApp
//
//  Host-facing native facade. Decode → dispatch → encode. No Presentation types.
//

import Foundation

/// Native side of a Flutter-shaped platform channel. Dart invokes this via
/// MethodChannel when the Flutter module is embedded (JP-P2-D); the codec +
/// facade remain the reviewable native contract (JP-P0-C).
nonisolated struct NativePlatformFacade: Sendable {
    private let cacheStatusProvider: any FeedCacheStatusProviding
    private let now: @Sendable () -> Date

    init(
        cacheStatusProvider: any FeedCacheStatusProviding = SnapshotFeedCacheStatusProvider(),
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.cacheStatusProvider = cacheStatusProvider
        self.now = now
    }

    /// Handle one host request blob. Throws `CancellationError` when the current
    /// task is cancelled; encode failures are unexpected and also thrown.
    func handle(_ data: Data) throws -> Data {
        try Task.checkCancellation()

        switch HostBridgeCodec.decodeRequest(from: data) {
        case let .failure(code):
            let response = HostBridgeResponse.error(
                id: nil,
                schemaVersion: HostBridgeContract.version,
                code: code,
                message: Self.message(for: code)
            )
            return try HostBridgeCodec.encode(response)

        case let .success(request):
            try Task.checkCancellation()
            let response = self.dispatch(request)
            return try HostBridgeCodec.encode(response)
        }
    }

    private func dispatch(_ request: HostBridgeRequest) -> HostBridgeResponse {
        switch request.method {
        case HostBridgeContract.feedCacheStatusMethod:
            let result = self.cacheStatusProvider.cacheStatus(now: self.now())
            return .ok(
                id: request.id,
                schemaVersion: HostBridgeContract.version,
                result: result
            )
        default:
            return .error(
                id: request.id,
                schemaVersion: HostBridgeContract.version,
                code: .unsupportedMethod,
                message: "Unsupported method: \(request.method)"
            )
        }
    }

    private static func message(for code: HostBridgeErrorCode) -> String {
        switch code {
        case .malformedJSON:
            "Request JSON is malformed or missing required fields."
        case .unsupportedMethod:
            "Method is not supported by this native facade."
        case .versionMismatch:
            "Host bridge contract version mismatch."
        case .cancelled:
            "Request was cancelled."
        case .unavailable:
            "Native capability unavailable."
        }
    }
}
