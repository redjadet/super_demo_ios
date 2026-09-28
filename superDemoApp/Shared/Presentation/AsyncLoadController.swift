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
        let operation = Task { @MainActor in
            await body()
        }
        self.task = operation
        Task { @MainActor [weak self] in
            await operation.value
            guard let self, self.task == operation else { return }
            self.task = nil
        }
    }

    func runAndWait(_ body: @escaping @MainActor () async -> Void) async {
        self.task?.cancel()
        let operation = Task { @MainActor in
            await body()
        }
        self.task = operation
        await withTaskCancellationHandler {
            await operation.value
        } onCancel: {
            operation.cancel()
        }
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
