import AppKit
import SwiftUI
import Carbon.HIToolbox

// MARK: - Window controller

final class SettingsWindowController: NSWindowController, NSWindowDelegate {

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "CenterScreen Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: SettingsView())

        self.init(window: window)
        window.delegate = self
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
        // Suspend global hotkeys while the settings window is open so the
        // hotkey recorder can capture key combos without them firing.
        HotkeyManager.shared.unregisterAll()
    }

    func windowWillClose(_ notification: Notification) {
        // Persist and re-activate hotkeys when the user closes settings.
        ConfigManager.shared.save()
        HotkeyManager.shared.registerFromConfig()
    }
}

// MARK: - SettingsView (SwiftUI)

struct SettingsView: View {
    @ObservedObject private var cfg = ConfigManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────────────
            VStack(spacing: 6) {
                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.accentColor)

                Text("CenterScreen")
                    .font(.title2).fontWeight(.semibold)

                Text("Use keyboard shortcuts to instantly move your cursor to any monitor.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            // ── Hotkey table ─────────────────────────────────────────────
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionLabel("Navigation")
                    HotkeyRow(label: "Center on Current Screen", hotkey: $cfg.config.centerCurrentScreen)
                    HotkeyRow(label: "Move to Next Screen →",    hotkey: $cfg.config.moveToNextScreen)
                    HotkeyRow(label: "Move to Previous Screen ←",hotkey: $cfg.config.moveToPreviousScreen)

                    SectionLabel("Jump to Specific Screen")
                    HotkeyRow(label: "Screen 1", hotkey: $cfg.config.moveToScreen1)
                    HotkeyRow(label: "Screen 2", hotkey: $cfg.config.moveToScreen2)
                    HotkeyRow(label: "Screen 3", hotkey: $cfg.config.moveToScreen3)
                    HotkeyRow(label: "Screen 4", hotkey: $cfg.config.moveToScreen4)
                    HotkeyRow(label: "Screen 5", hotkey: $cfg.config.moveToScreen5)
                    HotkeyRow(label: "Screen 6", hotkey: $cfg.config.moveToScreen6)
                }
                .padding(.bottom, 12)
            }

            Divider()

            // ── Footer ───────────────────────────────────────────────────
            HStack {
                Button("Reset to Defaults") { cfg.reset() }
                    .foregroundColor(.red)
                Spacer()
                Text("Changes save automatically")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .frame(width: 500)
    }
}

// MARK: - Sub-views

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }
}

private struct HotkeyRow: View {
    let label: String
    @Binding var hotkey: HotkeyConfig

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $hotkey.isEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)

            Text(label)
                .frame(minWidth: 180, alignment: .leading)

            Spacer()

            HotkeyRecorderView(hotkey: $hotkey)
                .frame(width: 160, height: 26)
                .opacity(hotkey.isEnabled ? 1 : 0.4)
                .allowsHitTesting(hotkey.isEnabled)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 5)
    }
}

// MARK: - HotkeyRecorderView (NSViewRepresentable bridge)

struct HotkeyRecorderView: NSViewRepresentable {
    @Binding var hotkey: HotkeyConfig

    func makeNSView(context: Context) -> HotkeyRecorderControl {
        let control = HotkeyRecorderControl()
        control.hotkey = hotkey
        control.onRecorded = { newHotkey in hotkey = newHotkey }
        return control
    }

    func updateNSView(_ control: HotkeyRecorderControl, context: Context) {
        guard !control.isRecording else { return }
        control.hotkey = hotkey
        control.refresh()
    }
}

// MARK: - HotkeyRecorderControl (NSView)

final class HotkeyRecorderControl: NSView {

    var hotkey: HotkeyConfig = .init(keyCode: 8, modifiers: HotkeyConfig.defaultMods)
    var onRecorded: ((HotkeyConfig) -> Void)?
    private(set) var isRecording = false

    private let label = NSTextField(labelWithString: "")
    private let button = NSButton()
    private var monitor: Any?

    override init(frame: NSRect) {
        super.init(frame: frame)
        buildSubviews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildSubviews() {
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        label.alignment = .center
        label.lineBreakMode = .byTruncatingMiddle
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        button.title = "Record"
        button.bezelStyle = .rounded
        button.controlSize = .small
        button.target = self
        button.action = #selector(toggleRecording)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let stack = NSStackView(views: [label, button])
        stack.orientation = .horizontal
        stack.spacing = 6
        stack.alignment = .centerY
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        refresh()
    }

    func refresh() {
        label.stringValue = hotkey.displayString
    }

    @objc private func toggleRecording() {
        isRecording ? cancelRecording() : startRecording()
    }

    private func startRecording() {
        isRecording = true
        button.title = "Cancel"
        label.stringValue = "Press shortcut…"

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isRecording else { return event }

            // Escape → cancel without saving
            if event.keyCode == 53 {
                self.cancelRecording()
                return nil
            }

            let keyCode = UInt32(event.keyCode)
            var mods: UInt32 = 0
            if event.modifierFlags.contains(.command) { mods |= UInt32(cmdKey) }
            if event.modifierFlags.contains(.shift)   { mods |= UInt32(shiftKey) }
            if event.modifierFlags.contains(.option)  { mods |= UInt32(optionKey) }
            if event.modifierFlags.contains(.control) { mods |= UInt32(controlKey) }

            // Require at least one modifier key alongside the main key
            guard mods != 0 else { return nil }

            let recorded = HotkeyConfig(keyCode: keyCode, modifiers: mods,
                                        isEnabled: self.hotkey.isEnabled)
            self.hotkey = recorded
            self.onRecorded?(recorded)
            self.finishRecording()
            return nil
        }
    }

    private func finishRecording() {
        isRecording = false
        button.title = "Record"
        removeMonitor()
        refresh()
    }

    private func cancelRecording() {
        isRecording = false
        button.title = "Record"
        removeMonitor()
        refresh()
    }

    private func removeMonitor() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }
}
