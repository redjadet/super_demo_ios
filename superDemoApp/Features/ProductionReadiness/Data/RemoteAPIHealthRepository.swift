//
//  RemoteAPIHealthRepository.swift
//  superDemoApp
//

import Foundation

struct RemoteAPIHealthRepository {
    private let client: APIClient
    private let endpoint: URL
    private let now: @Sendable () -> Date

    init(
        client: APIClient,
        endpoint: URL,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.client = client
        self.endpoint = endpoint
        self.now = now
    }

    func loadHealthCheck() async throws -> APIHealthCheck {
        let start = ContinuousClock.now
        let response = try await self.client.send(APIRequest(url: self.endpoint))
        let latency = start.duration(to: ContinuousClock.now).wholeMilliseconds
        return APIHealthCheck(
            id: "remote-api",
            name: "Remote API",
            endpoint: self.endpoint.path(),
            status: response.statusCode < 300 ? .healthy : .warning,
            latencyMilliseconds: latency,
            lastChecked: self.now()
        )
    }
}

private extension Duration {
    var wholeMilliseconds: Int {
        let (seconds, attoseconds) = self.components
        return Int(seconds * 1000) + Int(attoseconds / 1_000_000_000_000_000)
    }
}
