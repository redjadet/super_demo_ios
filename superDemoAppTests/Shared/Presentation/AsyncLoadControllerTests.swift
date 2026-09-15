//
//  AsyncLoadControllerTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("Async load controller")
@MainActor
struct AsyncLoadControllerTests {
    @Test
    func cancelStopsInFlightOperation() async {
        let controller = AsyncLoadController()
        var didComplete = false

        controller.run {
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
            } catch {
                return
            }
            didComplete = true
        }

        await Task.yield()
        #expect(controller.isRunning)
        controller.cancel()
        #expect(!controller.isRunning)

        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(!didComplete)
    }

    @Test
    func runAndWaitCompletesOperation() async {
        let controller = AsyncLoadController()
        var didComplete = false

        await controller.runAndWait {
            await Task.yield()
            didComplete = true
        }

        #expect(didComplete)
        #expect(!controller.isRunning)
    }

    @Test
    func runCancelsPriorOperation() async {
        let controller = AsyncLoadController()
        var firstCompleted = false
        var secondCompleted = false

        controller.run {
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
            } catch {
                return
            }
            firstCompleted = true
        }

        await Task.yield()
        controller.run {
            await Task.yield()
            secondCompleted = true
        }

        try? await Task.sleep(nanoseconds: 600_000_000)
        #expect(!firstCompleted)
        #expect(secondCompleted)
    }
}
