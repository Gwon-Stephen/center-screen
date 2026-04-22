import AppKit
import CoreGraphics

enum MouseController {

    /// Moves the mouse cursor to the center of the given screen.
    static func moveToCenter(of screen: NSScreen) {
        let cgTarget = convertToCGCoordinates(screen.frame.center)
        CGWarpMouseCursorPosition(cgTarget)

        // Post a synthetic mouseMoved event so the OS updates hover states.
        // This requires Accessibility permission; it's a best-effort call.
        if let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: cgTarget,
            mouseButton: .left
        ) {
            event.post(tap: .cghidEventTap)
        }
    }

    // MARK: - Coordinate conversion

    /// NSScreen uses a coordinate system with the origin at the bottom-left of the
    /// primary display (Y increases upward).  CoreGraphics uses an origin at the
    /// top-left of the primary display (Y increases downward).
    private static func convertToCGCoordinates(_ nsPoint: CGPoint) -> CGPoint {
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        return CGPoint(x: nsPoint.x, y: primaryHeight - nsPoint.y)
    }
}

// MARK: - CGRect convenience

extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
