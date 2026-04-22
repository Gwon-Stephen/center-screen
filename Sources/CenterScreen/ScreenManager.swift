import AppKit

enum ScreenManager {

    /// All connected screens sorted left-to-right by their horizontal position.
    static func sortedScreens() -> [NSScreen] {
        NSScreen.screens.sorted { $0.frame.minX < $1.frame.minX }
    }

    /// The screen that currently contains the mouse cursor.
    static func currentScreen() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouse) }
    }

    /// Index of the current screen in the sorted list.
    private static func currentIndex() -> Int {
        guard let current = currentScreen() else { return 0 }
        return sortedScreens().firstIndex(of: current) ?? 0
    }

    /// The screen immediately to the right of the current one (wraps around).
    static func nextScreen() -> NSScreen? {
        let screens = sortedScreens()
        guard !screens.isEmpty else { return nil }
        let next = (currentIndex() + 1) % screens.count
        return screens[next]
    }

    /// The screen immediately to the left of the current one (wraps around).
    static func previousScreen() -> NSScreen? {
        let screens = sortedScreens()
        guard !screens.isEmpty else { return nil }
        let prev = (currentIndex() - 1 + screens.count) % screens.count
        return screens[prev]
    }

    /// Screen at a zero-based index in the sorted list (returns nil if out of bounds).
    static func screen(at index: Int) -> NSScreen? {
        let screens = sortedScreens()
        guard index >= 0, index < screens.count else { return nil }
        return screens[index]
    }
}
