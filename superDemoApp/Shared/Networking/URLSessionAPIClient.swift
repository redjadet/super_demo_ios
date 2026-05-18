//
//  URLSessionAPIClient.swift
//  superDemoApp
//

import Foundation

protocol APIClient: Sendable {
    func send(_ request: APIRequest) async throws -> APIResponse
}

struct URLSessionAPIClient: APIClient {
    private let session: URLSession
    private let retryPolicy: RetryPolicy
    private let tokenRefresher: TokenRefreshing
    private let logger: APILogging
    private let sleeper: RetrySleeping

    init(
        session: URLSession = .shared,
        retryPolicy: RetryPolicy = RetryPolicy(),
        tokenRefresher: TokenRefreshing = EmptyTokenRefresher(),
        logger: APILogging = RedactedAPILogger(),
        sleeper: RetrySleeping = TaskRetrySleeper()
    ) {
        self.session = session
        self.retryPolicy = retryPolicy
        self.tokenRefresher = tokenRefresher
        self.logger = logger
        self.sleeper = sleeper
    }

    func send(_ request: APIRequest) async throws -> APIResponse {
        var token = await self.tokenRefresher.currentAccessToken()
        var didRefreshToken = false
        var attempt = 1

        while true {
            try Task.checkCancellation()
            self.logger.requestStarted(request, attempt: attempt)

            do {
                let response = try await self.perform(request, bearerToken: token)
                if response.statusCode == 401 {
                    if didRefreshToken {
                        throw APIError.unauthorizedAfterRefresh
                    }
                    didRefreshToken = true
                    token = try await self.tokenRefresher.refreshAccessToken()
                    continue
                }
                if (200 ... 299).contains(response.statusCode) {
                    self.logger.requestFinished(
                        url: request.url, statusCode: response.statusCode, attempt: attempt
                    )
                    return response
                }

                let error = APIError.httpStatus(response.statusCode)
                let retryAfter = response.headerValue(for: "Retry-After")
                if self.retryPolicy.shouldRetry(error: error, request: request, attempt: attempt) {
                    try await self.waitBeforeRetry(attempt: attempt, retryAfter: retryAfter)
                    attempt += 1
                    continue
                }
                throw error
            } catch is CancellationError {
                throw APIError.cancelled
            } catch let error as APIError {
                self.logger.requestFailed(url: request.url, error: error, attempt: attempt)
                if self.retryPolicy.shouldRetry(error: error, request: request, attempt: attempt) {
                    try await self.waitBeforeRetry(attempt: attempt, retryAfter: nil)
                    attempt += 1
                    continue
                }
                throw error
            } catch let error as URLError {
                let apiError = APIError.transport(error.code)
                self.logger.requestFailed(url: request.url, error: apiError, attempt: attempt)
                if self.retryPolicy.shouldRetry(error: apiError, request: request, attempt: attempt) {
                    try await self.waitBeforeRetry(attempt: attempt, retryAfter: nil)
                    attempt += 1
                    continue
                }
                throw apiError
            } catch {
                throw APIError.invalidResponse
            }
        }
    }

    private func perform(_ request: APIRequest, bearerToken: String?) async throws -> APIResponse {
        let (data, response) = try await self.session.data(
            for: request.urlRequest(bearerToken: bearerToken)
        )
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        let headers = http.allHeaderFields.reduce(into: [String: String]()) { result, item in
            guard let key = item.key as? String, let value = item.value as? String else { return }
            result[key] = value
        }
        return APIResponse(data: data, statusCode: http.statusCode, headers: headers)
    }

    private func waitBeforeRetry(attempt: Int, retryAfter: String?) async throws {
        let delay = self.retryPolicy.delayNanoseconds(attempt: attempt, retryAfter: retryAfter)
        try await self.sleeper.sleep(nanoseconds: delay)
    }
}
