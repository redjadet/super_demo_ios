//
//  StubURLProtocol.swift
//  superDemoAppTests
//

import Foundation

enum StubURLSessionFactory {
    static let sessionIDHeader = "X-Stub-Session-ID"

    static func makeSession(stubs: [StubURLProtocol.Stub]) -> (session: URLSession, sessionID: UUID) {
        let sessionID = StubSessionRegistry.shared.install(stubs: stubs)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        configuration.httpAdditionalHeaders = [Self.sessionIDHeader: sessionID.uuidString]
        return (URLSession(configuration: configuration), sessionID)
    }
}

actor StubURLProtocolGate {
    static let shared = StubURLProtocolGate()

    func withSession<T>(
        stubs: [StubURLProtocol.Stub],
        perform operation: (URLSession, UUID) async throws -> T
    ) async rethrows -> T {
        let (session, sessionID) = StubURLSessionFactory.makeSession(stubs: stubs)
        defer {
            StubSessionRegistry.shared.remove(sessionID: sessionID)
        }
        return try await operation(session, sessionID)
    }
}

final class StubSessionRegistry: @unchecked Sendable {
    static let shared = StubSessionRegistry()

    private struct Queue {
        var stubs: [StubURLProtocol.Stub]
        var handledRequests = 0
    }

    private let lock = NSLock()
    private var queues: [UUID: Queue] = [:]

    func install(stubs: [StubURLProtocol.Stub]) -> UUID {
        let sessionID = UUID()
        self.lock.lock()
        self.queues[sessionID] = Queue(stubs: stubs)
        self.lock.unlock()
        return sessionID
    }

    func remove(sessionID: UUID) {
        self.lock.lock()
        self.queues.removeValue(forKey: sessionID)
        self.lock.unlock()
    }

    func nextStub(sessionID: UUID) -> StubURLProtocol.Stub {
        self.lock.lock()
        defer { self.lock.unlock() }
        guard var queue = self.queues[sessionID] else {
            return .response(statusCode: 500)
        }
        let stub = queue.stubs.isEmpty ? .response(statusCode: 500) : queue.stubs.removeFirst()
        queue.handledRequests += 1
        self.queues[sessionID] = queue
        return stub
    }

    func requestCount(sessionID: UUID) -> Int {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.queues[sessionID]?.handledRequests ?? 0
    }
}

final class StubURLProtocol: URLProtocol {
    struct Stub {
        let statusCode: Int?
        let headers: [String: String]
        let data: Data
        let error: Error?

        static func response(
            statusCode: Int,
            headers: [String: String] = [:],
            data: Data = Data()
        ) -> Stub {
            Stub(statusCode: statusCode, headers: headers, data: data, error: nil)
        }

        static func error(_ error: Error) -> Stub {
            Stub(statusCode: nil, headers: [:], data: Data(), error: error)
        }
    }

    override static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let sessionID = Self.sessionID(from: self.request) else {
            self.client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let stub = StubSessionRegistry.shared.nextStub(sessionID: sessionID)

        if let error = stub.error {
            self.client?.urlProtocol(self, didFailWithError: error)
            return
        }

        guard let url = self.request.url,
              let statusCode = stub.statusCode,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: statusCode,
                  httpVersion: "HTTP/1.1",
                  headerFields: stub.headers
              )
        else {
            self.client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        self.client?.urlProtocol(self, didLoad: stub.data)
        self.client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func sessionID(from request: URLRequest) -> UUID? {
        guard let value = request.value(forHTTPHeaderField: StubURLSessionFactory.sessionIDHeader)
        else {
            return nil
        }
        return UUID(uuidString: value)
    }
}
