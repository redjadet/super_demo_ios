import SwiftUI

#if os(macOS)
struct MacAppCommands: Commands {
    @FocusedBinding(\.macSelectedTab)
    private var selectedTab
    @FocusedValue(\.macNewItem)
    private var newItem
    @FocusedValue(\.macSaveItem)
    private var saveItem
    @FocusedValue(\.macRefresh)
    private var refresh
    @AppStorage("macAppearance")
    private var appearance = MacAppearance.system.rawValue

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Item") { self.newItem?() }
                .keyboardShortcut("n")
                .disabled(self.newItem == nil)
        }
        CommandGroup(replacing: .saveItem) {
            Button("Save Item") { self.saveItem?() }
                .keyboardShortcut("s")
                .disabled(self.saveItem == nil)
        }
        CommandGroup(after: .sidebar) {
            Button("Dashboard") { self.selectedTab = .dashboard }
                .keyboardShortcut("1")
            Button("Items") { self.selectedTab = .items }
                .keyboardShortcut("2")
            Button("Feed") { self.selectedTab = .feed }
                .keyboardShortcut("3")
            Divider()
            Button("Refresh") { self.refresh?() }
                .keyboardShortcut("r")
                .disabled(self.refresh == nil)
            Picker("Appearance", selection: self.$appearance) {
                Text("System").tag(MacAppearance.system.rawValue)
                Text("Light").tag(MacAppearance.light.rawValue)
                Text("Dark").tag(MacAppearance.dark.rawValue)
            }
        }
        SidebarCommands()
        TextEditingCommands()
    }
}
#endif
