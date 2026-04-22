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
            // SF Symbol that suggests cursor/crosshair positioning
            button.image = NSImage(
                systemSymbolName: "arrow.up.and.down.and.arrow.left.and.right",
                accessibilityDescription: "CenterScreen"
            )
            button.image?.isTemplate = true  // adapts to light/dark menu bar
            button.toolTip = "CenterScreen"
        }

        statusItem?.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let title = NSMenuItem(title: "CenterScreen", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)

        menu.addItem(.separator())

        menu.addItem(makeItem("Center on Current Screen",    action: #selector(centerCurrent)))
        menu.addItem(makeItem("Move to Next Screen →",       action: #selector(moveNext)))
        menu.addItem(makeItem("Move to Previous Screen ←",  action: #selector(movePrev)))

        menu.addItem(.separator())

        // Dynamically list connected screens
        let screensHeader = NSMenuItem(title: "Jump to Screen", action: nil, keyEquivalent: "")
        screensHeader.isEnabled = false
        menu.addItem(screensHeader)

        for (idx, _) in ScreenManager.sortedScreens().enumerated() {
            let item = makeItem("  Screen \(idx + 1)", action: #selector(jumpToScreen(_:)))
            item.tag = idx
            menu.addItem(item)
        }

        menu.addItem(.separator())
        menu.addItem(makeItem("Settings…",           action: #selector(openSettings),  key: ","))
        menu.addItem(.separator())
        menu.addItem(makeItem("Quit CenterScreen",   action: #selector(NSApplication.terminate(_:)), key: "q"))

        return menu
    }

    private func makeItem(_ title: String, action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
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
        // CGWarpMouseCursorPosition works without accessibility, but the
        // synthetic mouseMoved event we post for hover-state updates needs it.
        // Show the system prompt once so the user can grant permission.
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let opts = [key: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }
}
