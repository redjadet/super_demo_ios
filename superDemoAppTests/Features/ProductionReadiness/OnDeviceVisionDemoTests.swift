//
//  OnDeviceVisionDemoTests.swift
//  superDemoAppTests
//

import Foundation
import Testing
@testable import superDemoApp

@Suite("On-device Vision demo")
struct OnDeviceVisionDemoTests {
    @MainActor
    @Test
    func recognizedMapsLines() async {
        let spy = SpyOnDeviceVisionDemo(result: .success([
            VisionDemoObservation(text: "Hello", confidence: 0.9),
        ]))
        let model = OnDeviceVisionDemoModel(demo: spy)
        await model.run()
        guard case let .recognized(lines) = model.state else {
            Issue.record("Expected recognized, got \(model.state)")
            return
        }
        #expect(lines.count == 1)
        #expect(lines[0].text == "Hello")
    }

    @MainActor
    @Test
    func unavailableMapsState() async {
        let spy = SpyOnDeviceVisionDemo(
            result: .failure(.unavailable(reason: "no image"))
        )
        let model = OnDeviceVisionDemoModel(demo: spy)
        await model.run()
        guard case let .unavailable(message) = model.state else {
            Issue.record("Expected unavailable, got \(model.state)")
            return
        }
        #expect(message == "no image")
    }

    @MainActor
    @Test
    func noTextMapsState() async {
        let spy = SpyOnDeviceVisionDemo(result: .failure(.noText))
        let model = OnDeviceVisionDemoModel(demo: spy)
        await model.run()
        #expect(model.state == .noText)
    }
}

@MainActor
private final class SpyOnDeviceVisionDemo: OnDeviceVisionDemoing {
    private let result: Result<[VisionDemoObservation], VisionDemoFailure>

    init(result: Result<[VisionDemoObservation], VisionDemoFailure>) {
        self.result = result
    }

    func recognizeText() async throws -> [VisionDemoObservation] {
        try self.result.get()
    }
}
