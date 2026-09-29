//
//  RemoteAPIHealthLoading.swift
//  superDemoApp
//
//  Injection seam for Dashboard remote health (tests can throw cancel).
//

import Foundation

protocol RemoteAPIHealthLoading: Sendable {
    func loadHealthCheck() async throws -> APIHealthCheck
}

extension RemoteAPIHealthRepository: RemoteAPIHealthLoading {}
