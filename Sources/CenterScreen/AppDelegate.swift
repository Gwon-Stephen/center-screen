import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var settingsWindowController: SettingsWindowController?

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildStatusItem()
        HotkeyManager.shared.registerFromConfig()
        checkAccessibilityPermission()
    }

    // MARK: - Menu bar

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "arrow.up.and.down.and.arrow.left.and.right",
                accessibilityDescription: "CenterScreen"
            )
            button.image?.isTemplate = true
            button.toolTip = "CenterScreen"
        }

        refreshMenu()
    }

    /// Rebuilds the menu with the current shortcuts from config.
    /// Called on launch and whenever Settings closes.
    func refreshMenu() {
        statusItem?.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let cfg = ConfigManager.shared.config
        let menu = NSMenu()

        let title = NSMenuItem(title: "CenterScreen", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)

        menu.addItem(.separator())

        menu.addItem(makeItem(
            "Center on Current Screen",
            hint: cfg.centerCurrentScreen,
            action: #selector(centerCurrent)
        ))
        menu.addItem(makeItem(
            "Move to Next Screen →",
            hint: cfg.moveToNextScreen,
            action: #selector(moveNext)
        ))
        menu.addItem(makeItem(
            "Move to Previous Screen ←",
            hint: cfg.moveToPreviousScreen,
            action: #selector(movePrev)
        ))

        menu.addItem(.separator())

        let screensHeader = NSMenuItem(title: "Jump to Screen", action: nil, keyEquivalent: "")
        screensHeader.isEnabled = false
        menu.addItem(screensHeader)

        let screenHotkeys = cfg.perScreenHotkeys
        for (idx, _) in ScreenManager.sortedScreens().enumerated() {
            let hotkey = idx < screenHotkeys.count ? screenHotkeys[idx] : nil
            let item = makeItem("  Screen \(idx + 1)", hint: hotkey, action: #selector(jumpToScreen(_:)))
            item.tag = idx
            menu.addItem(item)
        }

        menu.addItem(.separator())
        menu.addItem(makeItem("Settings…",         action: #selector(openSettings), key: ","))
        menu.addItem(.separator())
        menu.addItem(makeItem("Quit CenterScreen", action: #selector(NSApplication.terminate(_:)), key: "q"))

        return menu
    }

    /// Creates a menu item with an optional shortcut hint shown on the right side.
    private func makeItem(
        _ label: String,
        hint: HotkeyConfig? = nil,
        action: Selector,
        key: String = ""
    ) -> NSMenuItem {
        var displayTitle = label
        if let hint, hint.isEnabled {
            // Pad with spaces so the shortcut aligns to the right
            displayTitle = "\(label)   \(hint.displayString)"
        }
        let item = NSMenuItem(title: displayTitle, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    // MARK: - Menu actions

    @objc private func centerCurrent() {
        guard let screen = ScreenManager.currentScreen() else { return }
        MouseController.moveToCenter(of: screen)
    }

    @objc private func moveNext() {
        guard let screen = ScreenManager.nextScreen() else { return }
        MouseController.moveToCenter(of: screen)
    }

    @objc private func movePrev() {
        guard let screen = ScreenManager.previousScreen() else { return }
        MouseController.moveToCenter(of: screen)
    }

    @objc private func jumpToScreen(_ sender: NSMenuItem) {
        guard let screen = ScreenManager.screen(at: sender.tag) else { return }
        MouseController.moveToCenter(of: screen)
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Accessibility

    private func checkAccessibilityPermission() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let opts = [key: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }
}
