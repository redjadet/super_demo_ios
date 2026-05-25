//
//  CompositeProductionReadinessRepositoryTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@MainActor
@Suite("Composite production readiness repository")
struct CompositeProductionReadinessRepositoryTests {
    @Test
    func exercisesLiveAndFallbackRemoteHealth() async throws {
        try await self.prependsLiveRemoteHealthWhenRequestSucceeds()
        try await self.keepsSampleSnapshotWhenRemoteHealthFails()
    }

    private func prependsLiveRemoteHealthWhenRequestSucceeds() async throws {
        let endpoint = try #require(URL(string: "https://example.com/posts"))
        try await StubURLProtocolGate.shared.withSession(stubs: [
            .response(statusCode: 200, data: Data("{}".utf8)),
        ]) { session, _ in
            let repository = Self.makeRepository(endpoint: endpoint, session: session, maxAttempts: 3)
            let snapshot = try await repository.loadSnapshot()

            #expect(snapshot.apiHealth.first?.id == "remote-api")
            #expect(snapshot.apiHealth.first?.status == .healthy)
            #expect(snapshot.apiHealth.first.map { $0.latencyMilliseconds >= 0 } == true)
            #expect(snapshot.apiHealth.count == 4)
        }
    }

    private func keepsSampleSnapshotWhenRemoteHealthFails() async throws {
        let endpoint = try #require(URL(string: "https://example.com/posts"))
        try await StubURLProtocolGate.shared.withSession(stubs: [
            .response(statusCode: 503),
        ]) { session, _ in
            let repository = Self.makeRepository(endpoint: endpoint, session: session, maxAttempts: 1)
            let snapshot = try await repository.loadSnapshot()

            #expect(snapshot.apiHealth.first?.id == "remote-api")
            #expect(snapshot.apiHealth.first?.status == .warning)
            #expect(snapshot.apiHealth.first?.latencyMilliseconds == 0)
            #expect(snapshot.modules.count == 4)
        }
    }

    private static func makeRepository(
        endpoint: URL,
        session: URLSession,
        maxAttempts: Int
    ) -> CompositeProductionReadinessRepository {
        let referenceDate = Date(timeIntervalSince1970: 0)
        return CompositeProductionReadinessRepository(
            sample: SampleProductionReadinessRepository { referenceDate },
            remoteHealth: RemoteAPIHealthRepository(
                client: URLSessionAPIClient(
                    session: session,
                    retryPolicy: RetryPolicy(maxAttempts: maxAttempts),
                    logger: NoopAPILogger(),
                    sleeper: ImmediateRetrySleeper()
                ),
                endpoint: endpoint
            ) { referenceDate },
            remoteEndpoint: endpoint,
            diagnostics: NoopReleaseDiagnostics()
        ) { referenceDate }
    }
}

private struct NoopReleaseDiagnostics: ReleaseDiagnosticsReporting {
    func releaseCheckPassed(_: ReleaseDiagnosticCheck) {}
    func releaseCheckFailed(_: ReleaseDiagnosticCheck, reason _: String) {}
    func deviceOnlyFailure(_: DeviceOnlyFailure) {}
}

private struct NoopAPILogger: APILogging {
    func requestStarted(_: APIRequest, attempt _: Int) {}
    func requestFinished(url _: URL, statusCode _: Int, attempt _: Int) {}
    func requestFailed(url _: URL, error _: APIError, attempt _: Int) {}
}

private struct ImmediateRetrySleeper: RetrySleeping {
    func sleep(nanoseconds _: UInt64) async throws {
        await Task.yield()
    }
}
