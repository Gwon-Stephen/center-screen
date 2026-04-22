import Carbon.HIToolbox
import Foundation

/// Manages system-wide hotkey registration via the Carbon Event Manager.
/// Carbon hotkeys fire even when other applications are in the foreground.
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var registeredRefs: [EventHotKeyRef] = []
    private var actions: [UInt32: () -> Void] = [:]
    private var nextID: UInt32 = 1

    /// Four-character signature that identifies our hotkeys in the Carbon event stream.
    private let appSignature: OSType = fourCharCodeValue("CNTS")

    private init() {
        installEventHandler()
    }

    // MARK: - Carbon event handler

    private func installEventHandler() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        // InstallApplicationEventHandler is a C macro, so call the underlying
        // function directly with GetApplicationEventTarget().
        var handlerRef: EventHandlerRef?
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let event, let userData else { return noErr }
                return Unmanaged<HotkeyManager>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                    .handle(event: event)
            },
            1, &spec, selfPtr, &handlerRef
        )
    }

    private func handle(event: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        guard status == noErr else { return noErr }
        actions[hotKeyID.id]?()
        return noErr
    }

    // MARK: - Registration

    /// Registers a single hotkey. Returns the assigned ID.
    @discardableResult
    func register(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) -> UInt32 {
        let id = nextID
        nextID += 1

        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: appSignature, id: id)
        let status = RegisterEventHotKey(
            keyCode, modifiers, hotKeyID,
            GetApplicationEventTarget(), 0, &ref
        )

        if status == noErr, let ref {
            registeredRefs.append(ref)
            actions[id] = action
        }
        return id
    }

    /// Unregisters all previously registered hotkeys.
    func unregisterAll() {
        registeredRefs.forEach { UnregisterEventHotKey($0) }
        registeredRefs.removeAll()
        actions.removeAll()
        nextID = 1
    }

    /// Reads the current config and registers all enabled hotkeys.
    func registerFromConfig() {
        unregisterAll()
        let cfg = ConfigManager.shared.config

        registerIfEnabled(cfg.centerCurrentScreen) {
            guard let s = ScreenManager.currentScreen() else { return }
            MouseController.moveToCenter(of: s)
        }
        registerIfEnabled(cfg.moveToNextScreen) {
            guard let s = ScreenManager.nextScreen() else { return }
            MouseController.moveToCenter(of: s)
        }
        registerIfEnabled(cfg.moveToPreviousScreen) {
            guard let s = ScreenManager.previousScreen() else { return }
            MouseController.moveToCenter(of: s)
        }

        for (idx, hotkey) in cfg.perScreenHotkeys.enumerated() {
            let screenIdx = idx
            registerIfEnabled(hotkey) {
                guard let s = ScreenManager.screen(at: screenIdx) else { return }
                MouseController.moveToCenter(of: s)
            }
        }
    }

    private func registerIfEnabled(_ hotkey: HotkeyConfig, action: @escaping () -> Void) {
        guard hotkey.isEnabled else { return }
        register(keyCode: hotkey.keyCode, modifiers: hotkey.modifiers, action: action)
    }
}

// MARK: - Helpers

private func fourCharCodeValue(_ s: StaticString) -> OSType {
    let bytes = s.utf8Start
    return OSType(bytes[0]) << 24
         | OSType(bytes[1]) << 16
         | OSType(bytes[2]) << 8
         | OSType(bytes[3])
}
