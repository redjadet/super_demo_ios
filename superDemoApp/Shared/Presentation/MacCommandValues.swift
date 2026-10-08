import SwiftUI

#if os(macOS)
/// Scene-scoped actions keep menu commands tied to the visible feature/editor.
extension FocusedValues {
    @Entry var macSelectedTab: Binding<AppTab>?
    var macNewItem: (() -> Void)? {
        get { self[MacNewItemKey.self] }
        set { self[MacNewItemKey.self] = newValue }
    }

    var macSaveItem: (() -> Void)? {
        get { self[MacSaveItemKey.self] }
        set { self[MacSaveItemKey.self] = newValue }
    }

    var macRefresh: (() -> Void)? {
        get { self[MacRefreshKey.self] }
        set { self[MacRefreshKey.self] = newValue }
    }
}

private struct MacNewItemKey: FocusedValueKey {
    typealias Value = () -> Void
}

private struct MacSaveItemKey: FocusedValueKey {
    typealias Value = () -> Void
}

private struct MacRefreshKey: FocusedValueKey {
    typealias Value = () -> Void
}

enum MacAppearance: String {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
#endif
