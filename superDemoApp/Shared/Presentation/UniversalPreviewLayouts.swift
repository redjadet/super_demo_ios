//
//  UniversalPreviewLayouts.swift
//  superDemoApp
//

import SwiftUI

/// Fixed canvas sizes for `#Preview` across iPhone, iPad, and Mac targets.
///
/// For dark appearance, apply `.previewDarkAppearance()` on the preview root (`.dark` trait
/// is not available on all SDKs).
enum UniversalPreviewLayouts {
    /// iPhone 15 Pro–class portrait canvas.
    static let iPhonePortrait = PreviewTrait.fixedLayout(width: 393, height: 852)

    /// iPad regular-width split view (landscape-friendly).
    static let iPadRegular = PreviewTrait.fixedLayout(width: 1024, height: 768)

    /// Mac window–class canvas.
    static let macWindow = PreviewTrait.fixedLayout(width: 1280, height: 800)
}

extension View {
    /// Forces dark appearance in `#Preview` when `.dark` preview traits are unavailable.
    func previewDarkAppearance() -> some View {
        self.preferredColorScheme(.dark)
    }
}
