//
//  ConnectivityMonitoring.swift
//  superDemoApp
//

import Foundation
import Network

/// Reachability for the outbox sync engine. Declared `nonisolated` so the
/// sync actor can read it under `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor`.
nonisolated protocol ConnectivityMonitoring: Sendable {
    func start(onChange: @escaping @Sendable (Bool) -> Void)
    func stop()
    var isConnected: Bool { get }
}

/// NWPathMonitor-backed connectivity. Starts on a background queue.
final class NWPathConnectivityMonitor: ConnectivityMonitoring, @unchecked Sendable {
    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private let lock = NSLock()
    private var _isConnected = true
    private var onChange: (@Sendable (Bool) -> Void)?

    init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
        self.queue = DispatchQueue(label: "com.ilkersevim.superDemoApp.connectivity")
    }

    nonisolated var isConnected: Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self._isConnected
    }

    nonisolated func start(onChange: @escaping @Sendable (Bool) -> Void) {
        self.lock.lock()
        self.onChange = onChange
        self.lock.unlock()

        self.monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            self.lock.lock()
            let previous = self._isConnected
            self._isConnected = connected
            let handler = self.onChange
            self.lock.unlock()
            if connected != previous {
                handler?(connected)
            } else if connected {
                // First callback — notify so a cold start can flush.
                handler?(connected)
            }
        }
        self.monitor.start(queue: self.queue)
    }

    nonisolated func stop() {
        self.monitor.cancel()
        self.lock.lock()
        self.onChange = nil
        self.lock.unlock()
    }
}

/// Deterministic connectivity for tests / UITesting offline demos.
final class ManualConnectivityMonitor: ConnectivityMonitoring, @unchecked Sendable {
    private let lock = NSLock()
    private var _isConnected: Bool
    private var onChange: (@Sendable (Bool) -> Void)?

    init(isConnected: Bool = true) {
        self._isConnected = isConnected
    }

    nonisolated var isConnected: Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self._isConnected
    }

    nonisolated func start(onChange: @escaping @Sendable (Bool) -> Void) {
        self.lock.lock()
        self.onChange = onChange
        let connected = self._isConnected
        self.lock.unlock()
        onChange(connected)
    }

    nonisolated func stop() {
        self.lock.lock()
        self.onChange = nil
        self.lock.unlock()
    }

    nonisolated func setConnected(_ connected: Bool) {
        self.lock.lock()
        let previous = self._isConnected
        self._isConnected = connected
        let handler = self.onChange
        self.lock.unlock()
        if connected != previous {
            handler?(connected)
        }
    }
}
