#if os(macOS)
import AppKit

/// XCTest on multi-display / agent hosts can leave the SwiftUI `Window` at
/// invalid AX geometry (`inf, inf`), so clicks and focused typing miss the
/// detail column. Under `-UITesting`, re-center and key the main window once
/// after launch without reading screen bounds (SwiftLint
/// `no_screen_bounds_layout`).
enum MacUITestingWindowPlacement {
    @MainActor
    static func pinMainWindowIfNeeded() {
        guard AppLaunchConfiguration.isUITesting else { return }

        let candidates = NSApp.windows.filter { window in
            window.isVisible || window.isKeyWindow || window.canBecomeKey
        }
        guard let window = candidates.first(where: { $0.identifier?.rawValue == "main" })
            ?? candidates.first
        else {
            return
        }

        // `center()` places on the containing screen without querying
        // `NSScreen.visibleFrame` / `bounds` in app code.
        window.setContentSize(NSSize(width: 1040, height: 720))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
#endif
