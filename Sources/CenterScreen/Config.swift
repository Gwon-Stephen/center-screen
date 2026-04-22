import Foundation
import Carbon.HIToolbox

// MARK: - HotkeyConfig

struct HotkeyConfig: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32  // Carbon modifier flags
    var isEnabled: Bool

    init(keyCode: UInt32, modifiers: UInt32, isEnabled: Bool = true) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isEnabled = isEnabled
    }

    /// Human-readable representation, e.g. "⌃⇧⌘C"
    var displayString: String {
        guard isEnabled else { return "Disabled" }
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey)  != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey)   != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey)     != 0 { parts.append("⌘") }
        parts.append(VirtualKeyName.name(for: keyCode))
        return parts.joined()
    }

    /// ⌃⇧⌘ — safe default modifier combo that rarely conflicts with system shortcuts
    static let defaultMods: UInt32 = UInt32(cmdKey) | UInt32(shiftKey) | UInt32(controlKey)
}

// MARK: - AppConfig

struct AppConfig: Codable {
    var centerCurrentScreen:  HotkeyConfig
    var moveToNextScreen:     HotkeyConfig
    var moveToPreviousScreen: HotkeyConfig
    var moveToScreen1:        HotkeyConfig
    var moveToScreen2:        HotkeyConfig
    var moveToScreen3:        HotkeyConfig
    var moveToScreen4:        HotkeyConfig
    var moveToScreen5:        HotkeyConfig
    var moveToScreen6:        HotkeyConfig

    /// Ordered array used by HotkeyManager (index 0 = screen 1)
    var perScreenHotkeys: [HotkeyConfig] {
        [moveToScreen1, moveToScreen2, moveToScreen3,
         moveToScreen4, moveToScreen5, moveToScreen6]
    }

    static var `default`: AppConfig {
        let m = HotkeyConfig.defaultMods
        return AppConfig(
            centerCurrentScreen:  HotkeyConfig(keyCode: 8,   modifiers: m),              // ⌃⇧⌘C
            moveToNextScreen:     HotkeyConfig(keyCode: 124, modifiers: m),              // ⌃⇧⌘→
            moveToPreviousScreen: HotkeyConfig(keyCode: 123, modifiers: m),              // ⌃⇧⌘←
            moveToScreen1:        HotkeyConfig(keyCode: 18,  modifiers: m),              // ⌃⇧⌘1
            moveToScreen2:        HotkeyConfig(keyCode: 19,  modifiers: m),              // ⌃⇧⌘2
            moveToScreen3:        HotkeyConfig(keyCode: 20,  modifiers: m),              // ⌃⇧⌘3
            moveToScreen4:        HotkeyConfig(keyCode: 21,  modifiers: m, isEnabled: false),
            moveToScreen5:        HotkeyConfig(keyCode: 23,  modifiers: m, isEnabled: false),
            moveToScreen6:        HotkeyConfig(keyCode: 22,  modifiers: m, isEnabled: false)
        )
    }
}

// MARK: - ConfigManager

final class ConfigManager: ObservableObject {
    static let shared = ConfigManager()

    @Published var config: AppConfig {
        didSet { scheduleSave() }
    }

    private let configURL: URL
    private var saveWorkItem: DispatchWorkItem?

    private init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = support.appendingPathComponent("CenterScreen", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        configURL = folder.appendingPathComponent("config.json")

        if let data = try? Data(contentsOf: configURL),
           let decoded = try? JSONDecoder().decode(AppConfig.self, from: data) {
            config = decoded
        } else {
            config = .default
        }
    }

    private func scheduleSave() {
        saveWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.save() }
        saveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: item)
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(config) {
            try? data.write(to: configURL)
        }
    }

    func reset() {
        config = .default
    }
}

// MARK: - Virtual key code → display name

enum VirtualKeyName {
    // swiftlint:disable cyclomatic_complexity
    static func name(for code: UInt32) -> String {
        switch code {
        case 0:   return "A"
        case 1:   return "S"
        case 2:   return "D"
        case 3:   return "F"
        case 4:   return "H"
        case 5:   return "G"
        case 6:   return "Z"
        case 7:   return "X"
        case 8:   return "C"
        case 9:   return "V"
        case 11:  return "B"
        case 12:  return "Q"
        case 13:  return "W"
        case 14:  return "E"
        case 15:  return "R"
        case 16:  return "Y"
        case 17:  return "T"
        case 18:  return "1"
        case 19:  return "2"
        case 20:  return "3"
        case 21:  return "4"
        case 22:  return "6"
        case 23:  return "5"
        case 24:  return "="
        case 25:  return "9"
        case 26:  return "7"
        case 27:  return "-"
        case 28:  return "8"
        case 29:  return "0"
        case 30:  return "]"
        case 31:  return "O"
        case 32:  return "U"
        case 33:  return "["
        case 34:  return "I"
        case 35:  return "P"
        case 36:  return "↩"
        case 37:  return "L"
        case 38:  return "J"
        case 39:  return "'"
        case 40:  return "K"
        case 41:  return ";"
        case 42:  return "\\"
        case 43:  return ","
        case 44:  return "/"
        case 45:  return "N"
        case 46:  return "M"
        case 47:  return "."
        case 48:  return "⇥"
        case 49:  return "Space"
        case 50:  return "`"
        case 51:  return "⌫"
        case 53:  return "⎋"
        case 96:  return "F5"
        case 97:  return "F6"
        case 98:  return "F7"
        case 99:  return "F3"
        case 100: return "F8"
        case 101: return "F9"
        case 103: return "F11"
        case 109: return "F10"
        case 111: return "F12"
        case 118: return "F4"
        case 120: return "F2"
        case 122: return "F1"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default:  return "Key(\(code))"
        }
    }
}
