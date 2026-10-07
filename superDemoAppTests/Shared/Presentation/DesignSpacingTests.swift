//
//  DesignSpacingTests.swift
//  superDemoAppTests
//

import CoreGraphics
import Testing
@testable import superDemoApp

@Suite("Design spacing tokens")
struct DesignSpacingTests {
    @Test
    func tokensMatchDesignMarkdownAnchors() {
        #expect(DesignSpacing.xs == 4)
        #expect(DesignSpacing.sm == 8)
        #expect(DesignSpacing.md == 16)
        #expect(DesignSpacing.lg == 24)
        #expect(DesignSpacing.rowMin == 44)
        #expect(DesignSpacing.cornerSM == 8)
        #expect(DesignSpacing.cornerMD == 12)
        #expect(DesignSpacing.noteEditorMinHeight == 120)
    }

    @Test
    func spacingScaleIsStrictlyIncreasing() {
        #expect(DesignSpacing.xs < DesignSpacing.sm)
        #expect(DesignSpacing.sm < DesignSpacing.md)
        #expect(DesignSpacing.md < DesignSpacing.lg)
        #expect(DesignSpacing.cornerSM < DesignSpacing.cornerMD)
    }
}
