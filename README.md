# CenterScreen

A lightweight macOS menu bar app that lets you instantly move your mouse cursor to the center of any monitor using keyboard shortcuts.

No more dragging your cursor across three screens.

## Download

Go to the [**Releases**](../../releases/latest) page and download `CenterScreen.zip`.

## Installation

> Requires macOS 13 Ventura or later.

1. Unzip `CenterScreen.zip`
2. Move `CenterScreen.app` to your **Applications** folder
3. Open **Terminal** and run:
   ```bash
   xattr -cr /Applications/CenterScreen.app
   ```
   macOS flags apps downloaded from the internet as quarantined. This command removes that flag — it's a one-time step since the app isn't signed with an Apple Developer certificate.
4. Open the app — grant **Accessibility permission** when prompted (System Settings → Privacy & Security → Accessibility)
5. *(Optional)* Add CenterScreen to **System Settings → General → Login Items** to launch it at startup

The app lives entirely in your menu bar (no Dock icon).

## Default shortcuts

| Action | Shortcut |
|---|---|
| Center on current screen | `⌃⌥⌘↓` |
| Move to next screen → | `⌃⌥⌘→` |
| Move to previous screen ← | `⌃⌥⌘←` |
| Jump to screen 1 | `⌃⌥⌘1` |
| Jump to screen 2 | `⌃⌥⌘2` |
| Jump to screen 3 | `⌃⌥⌘3` |
| Jump to screens 4–6 | disabled by default |

## Customising shortcuts

Click the menu bar icon → **Settings…**

Each action has a toggle (enable/disable) and a **Record** button. Click Record, press any modifier + key combo, done. Settings save automatically.

## Building from source

**1. Install dependencies**

You only need the Xcode Command Line Tools — this gives you Swift, `make`, `git`, and everything else required. Run this in Terminal:

```bash
xcode-select --install
```

A dialog will pop up asking you to install. It takes a few minutes. If you already have Xcode or the tools installed, this command will tell you so and you can skip it.

**2. Clone and run**

```bash
git clone https://github.com/YOUR_USERNAME/center-screen.git
cd center-screen

# Run directly (stays open while Terminal is open)
make run

# Or build and install to ~/Applications
make install
```

## Why Accessibility permission?

`CGWarpMouseCursorPosition` moves the cursor without it, but posting the synthetic `mouseMoved` event (which updates hover states on the destination screen) requires Accessibility access. The app requests it once on first launch.
