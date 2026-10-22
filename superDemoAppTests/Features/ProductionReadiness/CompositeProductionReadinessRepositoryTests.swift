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
        try await self.rethrowsCancellationInsteadOfRemoteWarning()
        try await self.rethrowsAPIErrorCancelledAsCancellationError()
    }

    @Test
    func loadsSampleAndRemoteInParallel() async throws {
        let endpoint = try #require(URL(string: "https://example.com/posts"))
        let barrier = ArrivalBarrier(partyCount: 2)
        let sample = BarrierSampleRepository(barrier: barrier)
        let remote = BarrierRemoteHealth(barrier: barrier)

        let repository = CompositeProductionReadinessRepository(
            sample: sample,
            remoteHealth: remote,
            remoteEndpoint: endpoint,
            diagnostics: NoopReleaseDiagnostics()
        ) { Date(timeIntervalSince1970: 0) }

        let snapshot = try await repository.loadSnapshot()

        #expect(barrier.arrivalCount == 2)
        #expect(snapshot.apiHealth.first?.id == "remote-api")
        #expect(snapshot.apiHealth.first?.isLiveProbe == true)
        #expect(snapshot.modules.count == 1)
    }

    @Test
    func cancellingParentCancelsSampleAndRemoteChildren() async throws {
        let endpoint = try #require(URL(string: "https://example.com/posts"))
        let sample = HangingLoadProbe()
        let remote = HangingRemoteHealthProbe()

        let repository = CompositeProductionReadinessRepository(
            sample: sample,
            remoteHealth: remote,
            remoteEndpoint: endpoint,
            diagnostics: NoopReleaseDiagnostics()
        ) { Date(timeIntervalSince1970: 0) }

        let load = Task {
            try await repository.loadSnapshot()
        }

        await sample.waitUntilStarted()
        await remote.waitUntilStarted()
        load.cancel()

        let result = await load.result
        #expect(throws: CancellationError.self) {
            _ = try result.get()
        }
        #expect(sample.didObserveCancellation)
        #expect(remote.didObserveCancellation)
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
            #expect(snapshot.apiHealth.first?.isLiveProbe == true)
            #expect(snapshot.apiHealth.first.map { $0.latencyMilliseconds >= 0 } == true)
            #expect(snapshot.apiHealth.count == 4)
            #expect(snapshot.apiHealth.dropFirst().allSatisfy { !$0.isLiveProbe })
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
            #expect(snapshot.apiHealth.first?.isLiveProbe == true)
            #expect(snapshot.apiHealth.first?.latencyMilliseconds == 0)
            #expect(snapshot.modules.count == 4)
        }
    }

    private func rethrowsCancellationInsteadOfRemoteWarning() async throws {
        let endpoint = try #require(URL(string: "https://example.com/posts"))
        let diagnostics = RecordingReleaseDiagnostics()
        let repository = CompositeProductionReadinessRepository(
            sample: SampleProductionReadinessRepository { Date(timeIntervalSince1970: 0) },
            remoteHealth: ThrowingRemoteAPIHealth(kind: .cancellation),
            remoteEndpoint: endpoint,
            diagnostics: diagnostics
        ) { Date(timeIntervalSince1970: 0) }

        await #expect(throws: CancellationError.self) {
            _ = try await repository.loadSnapshot()
        }
        #expect(diagnostics.failedReasons.isEmpty)
    }

    private func rethrowsAPIErrorCancelledAsCancellationError() async throws {
        let endpoint = try #require(URL(string: "https://example.com/posts"))
        let diagnostics = RecordingReleaseDiagnostics()
        let repository = CompositeProductionReadinessRepository(
            sample: SampleProductionReadinessRepository { Date(timeIntervalSince1970: 0) },
            remoteHealth: ThrowingRemoteAPIHealth(kind: .apiCancelled),
            remoteEndpoint: endpoint,
            diagnostics: diagnostics
        ) { Date(timeIntervalSince1970: 0) }

        await #expect(throws: CancellationError.self) {
            _ = try await repository.loadSnapshot()
        }
        #expect(diagnostics.failedReasons.isEmpty)
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

// MARK: - Parallel + cancel probes

/// Both children must call `arrive()` before either proceeds — proves overlap.
/// NSLock stays in sync helpers (Swift 6: unavailable from async contexts).
private final class ArrivalBarrier: @unchecked Sendable {
    private let lock = NSLock()
    private let partyCount: Int
    private var arrivals = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    var arrivalCount: Int {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.arrivals
    }

    init(partyCount: Int) {
        self.partyCount = partyCount
    }

    func arrive() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.enqueue(continuation)
        }
    }

    /// Sync so `NSLock` stays out of async contexts (Swift 6).
    private func enqueue(_ continuation: CheckedContinuation<Void, Never>) {
        self.lock.lock()
        self.arrivals += 1
        if self.arrivals >= self.partyCount {
            let pending = self.waiters
            self.waiters = []
            self.lock.unlock()
            continuation.resume()
            for waiter in pending {
                waiter.resume()
            }
        } else {
            self.waiters.append(continuation)
            self.lock.unlock()
        }
    }
}

private struct BarrierSampleRepository: ProductionReadinessRepository {
    let barrier: ArrivalBarrier

    func loadSnapshot() async throws -> ProductionReadinessSnapshot {
        await self.barrier.arrive()
        return ProductionReadinessSnapshot(
            modules: [
                FeatureModule(
                    id: "architecture",
                    name: "Architecture",
                    layerBoundary: "Presentation -> Domain <- Data",
                    owner: "Mobile Platform",
                    status: .healthy,
                    summary: "Barrier sample"
                ),
            ],
            apiHealth: [],
            checklist: [],
            risks: []
        )
    }
}

private struct BarrierRemoteHealth: RemoteAPIHealthLoading {
    let barrier: ArrivalBarrier

    func loadHealthCheck() async throws -> APIHealthCheck {
        await self.barrier.arrive()
        return APIHealthCheck(
            id: "remote-api",
            name: "Remote API",
            endpoint: "/posts",
            status: .healthy,
            latencyMilliseconds: 1,
            lastChecked: Date(timeIntervalSince1970: 0),
            isLiveProbe: true
        )
    }
}

private final class HangingLoadProbe: ProductionReadinessRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var startedContinuation: CheckedContinuation<Void, Never>?
    private var hasStarted = false
    private var _didObserveCancellation = false

    var didObserveCancellation: Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self._didObserveCancellation
    }

    func waitUntilStarted() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.parkUntilStarted(continuation)
        }
    }

    func loadSnapshot() async throws -> ProductionReadinessSnapshot {
        self.signalStarted()
        do {
            try await Task.sleep(nanoseconds: 60_000_000_000)
        } catch is CancellationError {
            self.markCancelled()
            throw CancellationError()
        }
        return ProductionReadinessSnapshot(
            modules: [],
            apiHealth: [],
            checklist: [],
            risks: []
        )
    }

    /// Sync so `NSLock` stays out of async contexts (Swift 6).
    private func parkUntilStarted(_ continuation: CheckedContinuation<Void, Never>) {
        self.lock.lock()
        if self.hasStarted {
            self.lock.unlock()
            continuation.resume()
        } else {
            self.startedContinuation = continuation
            self.lock.unlock()
        }
    }

    /// Sync so `NSLock` stays out of async contexts (Swift 6).
    private func signalStarted() {
        self.lock.lock()
        self.hasStarted = true
        let continuation = self.startedContinuation
        self.startedContinuation = nil
        self.lock.unlock()
        continuation?.resume()
    }

    /// Sync so `NSLock` stays out of async contexts (Swift 6).
    private func markCancelled() {
        self.lock.lock()
        self._didObserveCancellation = true
        self.lock.unlock()
    }
}

private final class HangingRemoteHealthProbe: RemoteAPIHealthLoading, @unchecked Sendable {
    private let lock = NSLock()
    private var startedContinuation: CheckedContinuation<Void, Never>?
    private var hasStarted = false
    private var _didObserveCancellation = false

    var didObserveCancellation: Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self._didObserveCancellation
    }

    func waitUntilStarted() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.parkUntilStarted(continuation)
        }
    }

    func loadHealthCheck() async throws -> APIHealthCheck {
        self.signalStarted()
        do {
            try await Task.sleep(nanoseconds: 60_000_000_000)
        } catch is CancellationError {
            self.markCancelled()
            throw CancellationError()
        }
        return APIHealthCheck(
            id: "remote-api",
            name: "Remote API",
            endpoint: "/posts",
            status: .healthy,
            latencyMilliseconds: 1,
            lastChecked: Date(timeIntervalSince1970: 0),
            isLiveProbe: true
        )
    }

    /// Sync so `NSLock` stays out of async contexts (Swift 6).
    private func parkUntilStarted(_ continuation: CheckedContinuation<Void, Never>) {
        self.lock.lock()
        if self.hasStarted {
            self.lock.unlock()
            continuation.resume()
        } else {
            self.startedContinuation = continuation
            self.lock.unlock()
        }
    }

    /// Sync so `NSLock` stays out of async contexts (Swift 6).
    private func signalStarted() {
        self.lock.lock()
        self.hasStarted = true
        let continuation = self.startedContinuation
        self.startedContinuation = nil
        self.lock.unlock()
        continuation?.resume()
    }

    /// Sync so `NSLock` stays out of async contexts (Swift 6).
    private func markCancelled() {
        self.lock.lock()
        self._didObserveCancellation = true
        self.lock.unlock()
    }
}

private struct ThrowingRemoteAPIHealth: RemoteAPIHealthLoading {
    enum Kind: Sendable {
        case cancellation
        case apiCancelled
    }

    let kind: Kind

    func loadHealthCheck() async throws -> APIHealthCheck {
        await Task.yield()
        switch self.kind {
        case .cancellation:
            throw CancellationError()
        case .apiCancelled:
            throw APIError.cancelled
        }
    }
}

private final class RecordingReleaseDiagnostics: ReleaseDiagnosticsReporting, @unchecked Sendable {
    private(set) var failedReasons: [String] = []

    func releaseCheckPassed(_: ReleaseDiagnosticCheck) { /* no-op */ }

    func releaseCheckFailed(_: ReleaseDiagnosticCheck, reason: String) {
        self.failedReasons.append(reason)
    }

    func deviceOnlyFailure(_: DeviceOnlyFailure) { /* no-op */ }
}

private struct NoopReleaseDiagnostics: ReleaseDiagnosticsReporting {
    func releaseCheckPassed(_: ReleaseDiagnosticCheck) { /* no-op */ }
    func releaseCheckFailed(_: ReleaseDiagnosticCheck, reason _: String) { /* no-op */ }
    func deviceOnlyFailure(_: DeviceOnlyFailure) { /* no-op */ }
}

private struct NoopAPILogger: APILogging {
    func requestStarted(_: APIRequest, attempt _: Int) { /* no-op */ }
    func requestFinished(url _: URL, statusCode _: Int, attempt _: Int) { /* no-op */ }
    func requestFailed(url _: URL, error _: APIError, attempt _: Int) { /* no-op */ }
}

private struct ImmediateRetrySleeper: RetrySleeping {
    func sleep(nanoseconds _: UInt64) async throws {
        await Task.yield()
    }
}
