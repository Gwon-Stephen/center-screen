import AppKit
import SwiftUI
import Carbon.HIToolbox

// MARK: - Window controller

final class SettingsWindowController: NSWindowController, NSWindowDelegate {

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 560),
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
        // Suspend global hotkeys while settings are open so the recorder
        // can capture key combos without them firing globally.
        HotkeyManager.shared.unregisterAll()
    }

    func windowWillClose(_ notification: Notification) {
        ConfigManager.shared.save()
        HotkeyManager.shared.registerFromConfig()
    }
}

// MARK: - SettingsView

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
                    HotkeyRow(label: "Center on Current Screen",  hotkey: $cfg.config.centerCurrentScreen)
                    HotkeyRow(label: "Move to Next Screen →",     hotkey: $cfg.config.moveToNextScreen)
                    HotkeyRow(label: "Move to Previous Screen ←", hotkey: $cfg.config.moveToPreviousScreen)

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
        .frame(width: 520, height: 560)
    }
}

// MARK: - SectionLabel

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

// MARK: - HotkeyRow

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

            HotkeyField(hotkey: $hotkey)
                .opacity(hotkey.isEnabled ? 1 : 0.4)
                .allowsHitTesting(hotkey.isEnabled)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
    }
}

// MARK: - HotkeyField (pure SwiftUI — no NSViewRepresentable)

/// Shows the current shortcut and a Record button.
/// Clicking Record starts a local key-down monitor; the next modifier+key
/// combo is captured and saved.  Escape cancels without changing anything.
private struct HotkeyField: View {
    @Binding var hotkey: HotkeyConfig

    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 8) {
            // Shortcut badge
            Text(isRecording ? "Press shortcut…" : hotkey.displayString)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(isRecording ? .accentColor : .primary)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(
                            isRecording ? Color.accentColor : Color(nsColor: .separatorColor),
                            lineWidth: 1
                        )
                )

            // Record / Cancel button
            Button(isRecording ? "Cancel" : "Record") {
                isRecording ? stopRecording() : startRecording()
            }
            .controlSize(.small)
        }
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Escape cancels without saving
            if event.keyCode == 53 {
                stopRecording()
                return nil
            }

            var mods: UInt32 = 0
            if event.modifierFlags.contains(.command) { mods |= UInt32(cmdKey) }
            if event.modifierFlags.contains(.shift)   { mods |= UInt32(shiftKey) }
            if event.modifierFlags.contains(.option)  { mods |= UInt32(optionKey) }
            if event.modifierFlags.contains(.control) { mods |= UInt32(controlKey) }

            // Ignore bare modifier taps — require at least one regular key
            guard mods != 0 else { return nil }

            hotkey = HotkeyConfig(
                keyCode: UInt32(event.keyCode),
                modifiers: mods,
                isEnabled: hotkey.isEnabled
            )
            stopRecording()
            return nil  // consume the event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }
}
