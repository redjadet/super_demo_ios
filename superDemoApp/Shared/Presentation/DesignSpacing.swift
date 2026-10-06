//
//  DesignSpacing.swift
//  superDemoApp
//

import CoreGraphics

/// Spacing / radius values that mirror `DESIGN.md` YAML (`spacing.*`, `rounded.*`).
/// Prefer these over magic numbers in Presentation views. Not a parallel theme system.
enum DesignSpacing {
    /// YAML `spacing.xs` — 4 pt
    static let xs: CGFloat = 4
    /// YAML `spacing.sm` — 8 pt
    static let sm: CGFloat = 8
    /// YAML `spacing.md` — 16 pt
    static let md: CGFloat = 16
    /// YAML `spacing.lg` — 24 pt
    static let lg: CGFloat = 24
    /// YAML `spacing.row-min` — 44 pt minimum touch target
    static let rowMin: CGFloat = 44

    /// YAML `rounded.sm` — 8 pt
    static let cornerSM: CGFloat = 8
    /// YAML `rounded.md` — 12 pt
    static let cornerMD: CGFloat = 12

    /// Comfortable `TextEditor` floor at default Dynamic Type; views may scale up.
    static let noteEditorMinHeight: CGFloat = 120
}
