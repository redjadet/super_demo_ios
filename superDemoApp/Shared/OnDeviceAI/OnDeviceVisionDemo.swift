//
//  OnDeviceVisionDemo.swift
//  superDemoApp
//
//  On-device Vision text recognition demo. No Apple Intelligence claim.
//

import CoreGraphics
import CoreText
import Foundation
import Vision

/// Display DTO for recognized text lines.
struct VisionDemoObservation: Equatable, Identifiable, Sendable {
    let text: String
    let confidence: Float
    let id: UUID

    nonisolated init(text: String, confidence: Float, id: UUID = UUID()) {
        self.text = text
        self.confidence = confidence
        self.id = id
    }
}

enum VisionDemoFailure: Error, Equatable, Sendable {
    case unavailable(reason: String)
    case noText
    case failed(reason: String)
}

@MainActor
protocol OnDeviceVisionDemoing: AnyObject {
    func recognizeText() async throws -> [VisionDemoObservation]
}

/// Runs `VNRecognizeTextRequest` on a CoreGraphics-rendered sample (no asset catalog).
/// Sync Vision/OCR work hops to `OnDeviceVisionOCRExecutor` so Recognize does not hitch UI.
@MainActor
final class SystemOnDeviceVisionDemo: OnDeviceVisionDemoing {
    private let executor = OnDeviceVisionOCRExecutor()

    func recognizeText() async throws -> [VisionDemoObservation] {
        await Task.yield()
        try Task.checkCancellation()
        return try await self.executor.recognizeSampleText()
    }
}

/// Background executor for sync Vision/CoreGraphics work (structured actor hop;
/// not an unstructured detached task).
private actor OnDeviceVisionOCRExecutor {
    func recognizeSampleText() throws -> [VisionDemoObservation] {
        try Task.checkCancellation()
        guard let cgImage = OnDeviceVisionDemoEngine.sampleCGImage() else {
            throw VisionDemoFailure.unavailable(
                reason: """
                Could not render the Vision demo sample bitmap on this target.
                """
            )
        }
        try Task.checkCancellation()
        return try OnDeviceVisionDemoEngine.recognizeText(in: cgImage)
    }
}

/// Sync Vision/CoreGraphics helpers stay off the default MainActor isolation so
/// the OCR actor can call them synchronously without `#ActorIsolatedCall`.
private enum OnDeviceVisionDemoEngine {
    nonisolated static func recognizeText(in cgImage: CGImage) throws -> [VisionDemoObservation] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            throw VisionDemoFailure.failed(reason: error.localizedDescription)
        }
        let observations = request.results ?? []
        var lines: [VisionDemoObservation] = []
        for observation in observations {
            guard let top = observation.topCandidates(1).first else { continue }
            lines.append(
                VisionDemoObservation(text: top.string, confidence: top.confidence)
            )
        }
        if lines.isEmpty {
            throw VisionDemoFailure.noText
        }
        return lines
    }

    /// Synthetic bitmap via CoreGraphics + CoreText (avoids UIColor/NSString lint).
    nonisolated static func sampleCGImage() -> CGImage? {
        let height = 160
        let width = 480
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.setFillColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let textColor = CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        let text = "superDemo Vision" as CFString
        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 36, nil)
        let attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: textColor,
        ]
        let attrString = CFAttributedStringCreate(
            nil,
            text,
            attributes as CFDictionary
        )
        guard let attrString else { return nil }
        let line = CTLineCreateWithAttributedString(attrString)
        context.textPosition = CGPoint(x: 24, y: 60)
        CTLineDraw(line, context)
        return context.makeImage()
    }
}
