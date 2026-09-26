//
//  HostBridgeCodec.swift
//  superDemoApp
//
//  JSON encode/decode for host-bridge messages. Foundation-only.
//

import Foundation

nonisolated enum HostBridgeCodec {
    private static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    private static let jsonDecoder = JSONDecoder()

    static func decodeRequest(from data: Data) -> Result<HostBridgeRequest, HostBridgeErrorCode> {
        guard !data.isEmpty else {
            return .failure(.malformedJSON)
        }
        do {
            let wire = try jsonDecoder.decode(RequestWire.self, from: data)
            guard let method = wire.method, !method.isEmpty, let id = wire.id, !id.isEmpty else {
                return .failure(.malformedJSON)
            }
            guard let version = wire.schemaVersion else {
                return .failure(.malformedJSON)
            }
            guard version == HostBridgeContract.version else {
                return .failure(.versionMismatch)
            }
            return .success(
                HostBridgeRequest(schemaVersion: version, method: method, id: id)
            )
        } catch {
            return .failure(.malformedJSON)
        }
    }

    static func encode(_ response: HostBridgeResponse) throws -> Data {
        switch response {
        case let .ok(id, schemaVersion, result):
            let wire = OkWire(
                schemaVersion: schemaVersion,
                id: id,
                ok: true,
                result: result,
                error: nil
            )
            return try self.jsonEncoder.encode(wire)
        case let .error(id, schemaVersion, code, message):
            let wire = ErrWire(
                schemaVersion: schemaVersion,
                id: id,
                ok: false,
                error: ErrorWire(code: code.rawValue, message: message)
            )
            return try self.jsonEncoder.encode(wire)
        }
    }

    // MARK: - Wire DTOs (key `"v"` matches platform-channel shape)

    private struct RequestWire: Decodable {
        var schemaVersion: Int?
        var method: String?
        var id: String?

        enum CodingKeys: String, CodingKey {
            case schemaVersion = "v"
            case method
            case id
        }
    }

    private struct OkWire: Encodable {
        var schemaVersion: Int
        var id: String
        var ok: Bool
        var result: FeedCacheStatusResult
        var error: ErrorWire?

        enum CodingKeys: String, CodingKey {
            case schemaVersion = "v"
            case id
            case ok
            case result
            case error
        }
    }

    private struct ErrWire: Encodable {
        var schemaVersion: Int
        var id: String?
        var ok: Bool
        var error: ErrorWire

        enum CodingKeys: String, CodingKey {
            case schemaVersion = "v"
            case id
            case ok
            case error
        }
    }

    private struct ErrorWire: Encodable {
        var code: String
        var message: String
    }
}
