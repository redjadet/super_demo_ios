//
//  OnDeviceVisionDemo.swift
//  superDemoApp
//
//  On-device Vision text recognition demo (JP-P2-C). No Apple Intelligence claim.
//

import Foundation
import Vision

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Display DTO for recognized text lines.
struct VisionDemoObservation: Equatable, Identifiable, Sendable {
    let id: UUID
    let text: String
    let confidence: Float

    init(id: UUID = UUID(), text: String, confidence: Float) {
        self.id = id
        self.text = text
        self.confidence = confidence
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

/// Runs `VNRecognizeTextRequest` on a bundled sample CGImage (or synthetic fallback).
@MainActor
final class SystemOnDeviceVisionDemo: OnDeviceVisionDemoing {
    func recognizeText() async throws -> [VisionDemoObservation] {
        guard let cgImage = Self.sampleCGImage() else {
            throw VisionDemoFailure.unavailable(
                reason: """
                No sample image available for Vision. Bundle a demo asset or \
                run on a target that can render the synthetic sample.
                """
            )
        }
        return try await Task.detached(priority: .userInitiated) {
            try Self.recognizeText(in: cgImage)
        }.value
    }

    nonisolated private static func recognizeText(in cgImage: CGImage) throws -> [VisionDemoObservation] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            throw VisionDemoFailure.failed(reason: error.localizedDescription)
        }
        let observations = (request.results) ?? []
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

    /// Prefer asset `VisionDemoSample` if present; else draw a simple text bitmap.
    private static func sampleCGImage() -> CGImage? {
        #if canImport(UIKit) && !os(watchOS)
        if let image = UIImage(named: "VisionDemoSample")?.cgImage {
            return image
        }
        return Self.renderSyntheticUIKit()
        #elseif canImport(AppKit)
        if let image = NSImage(named: "VisionDemoSample"),
           let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        {
            return cgImage
        }
        return Self.renderSyntheticAppKit()
        #else
        return nil
        #endif
    }

    #if canImport(UIKit) && !os(watchOS)
    private static func renderSyntheticUIKit() -> CGImage? {
        let size = CGSize(width: 480, height: 160)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let text = "superDemo Vision" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 36),
                .foregroundColor: UIColor.black,
            ]
            text.draw(at: CGPoint(x: 24, y: 56), withAttributes: attrs)
        }
        return image.cgImage
    }
    #endif

    #if canImport(AppKit)
    private static func renderSyntheticAppKit() -> CGImage? {
        let size = NSSize(width: 480, height: 160)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.white.setFill()
            rect.fill()
            let text = "superDemo Vision" as NSString
            text.draw(
                at: NSPoint(x: 24, y: 56),
                withAttributes: [
                    .font: NSFont.boldSystemFont(ofSize: 36),
                    .foregroundColor: NSColor.black,
                ]
            )
            return true
        }
        var rect = NSRect(origin: .zero, size: size)
        return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }
    #endif
}
