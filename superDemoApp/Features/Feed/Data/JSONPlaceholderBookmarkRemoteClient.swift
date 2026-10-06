//
//  JSONPlaceholderBookmarkRemoteClient.swift
//  superDemoApp
//

import Foundation

/// Maps bookmark set/clear onto JSONPlaceholder `/posts` write endpoints.
///
/// Honesty: JSONPlaceholder does **not** expose bookmarks. Set → `POST /posts`
/// with a titled payload; clear → `DELETE /posts/{id}`. Responses succeed but
/// are not durably stored server-side. Idempotency-Key is sent on every POST
/// so client retries stay safe against the SPM retry policy.
struct JSONPlaceholderBookmarkRemoteClient: BookmarkRemoteClient {
    private let client: APIClient
    private let postsURL: URL

    init(
        client: APIClient,
        postsURL: URL? = nil
    ) {
        self.client = client
        if let postsURL {
            self.postsURL = postsURL
        } else {
            self.postsURL = Self.defaultPostsURL
        }
    }

    private static var defaultPostsURL: URL {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
            preconditionFailure("Invalid JSONPlaceholder posts URL")
        }
        return url
    }

    func setBookmark(postID: Int, idempotencyKey: String) async throws -> Int? {
        let body = try JSONEncoder().encode(
            BookmarkCreateDTO(
                title: "bookmark:\(postID)",
                body: "superDemoApp offline outbox bookmark",
                userId: 1
            )
        )
        let request = APIRequest(
            url: self.postsURL,
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: body,
            idempotencyKey: idempotencyKey
        )
        do {
            let response = try await self.client.send(request)
            let dto = try JSONDecoder().decode(BookmarkCreateResponseDTO.self, from: response.data)
            return dto.id
        } catch let error as APIError {
            throw self.mapAPIError(error)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw BookmarkRemoteError.decodingFailed
        }
    }

    func clearBookmark(
        postID: Int,
        remoteBookmarkID: Int?,
        idempotencyKey: String
    ) async throws {
        let targetID = remoteBookmarkID ?? postID
        let url = self.postsURL.appending(path: "\(targetID)")
        let request = APIRequest(
            url: url,
            method: .delete,
            idempotencyKey: idempotencyKey
        )
        do {
            _ = try await self.client.send(request)
        } catch let error as APIError {
            throw self.mapAPIError(error)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw BookmarkRemoteError.transport
        }
    }

    private func mapAPIError(_ error: APIError) -> Error {
        switch error {
        case .cancelled:
            CancellationError()
        case let .httpStatus(code) where code == 409 || code == 412:
            BookmarkRemoteError.conflict
        case let .httpStatus(code):
            BookmarkRemoteError.httpStatus(code)
        case .transport:
            BookmarkRemoteError.transport
        case .invalidResponse, .decodingFailed, .unauthorizedAfterRefresh:
            BookmarkRemoteError.decodingFailed
        }
    }
}

private struct BookmarkCreateDTO: Encodable {
    let title: String
    let body: String
    let userId: Int
}

private struct BookmarkCreateResponseDTO: Decodable {
    let id: Int
}
