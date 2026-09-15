//
//  AsyncLoadController.swift
//  superDemoApp
//

import Foundation

@MainActor
final class AsyncLoadController {
    private var task: Task<Void, Never>?

    func run(_ body: @escaping @MainActor () async -> Void) {
        self.task?.cancel()
        self.task = Task { await body() }
    }

    func runAndWait(_ body: @escaping @MainActor () async -> Void) async {
        self.task?.cancel()
        let operation = Task { await body() }
        self.task = operation
        await operation.value
        if self.task == operation {
            self.task = nil
        }
    }

    func cancel() {
        self.task?.cancel()
        self.task = nil
    }

    var isRunning: Bool {
        self.task != nil
    }
}
