# CenterScreen

A lightweight macOS menu bar app that lets you instantly move your mouse cursor to the center of any monitor using keyboard shortcuts.

No more dragging your cursor across three screens.

## Download

Go to the [**Releases**](../../releases/latest) page and download `CenterScreen.zip`.

## Installation

> Requires macOS 13 Ventura or later.

1. Unzip `CenterScreen.zip`
2. Move `CenterScreen.app` to your **Applications** folder
3. **Right-click → Open** the first time (the app is unsigned, so Gatekeeper will block a normal double-click)
4. Grant **Accessibility permission** when prompted — System Settings → Privacy & Security → Accessibility
5. *(Optional)* Add CenterScreen to **System Settings → General → Login Items** to launch it at startup

The app lives entirely in your menu bar (no Dock icon).

## Default shortcuts

| Action | Shortcut |
|---|---|
| Center on current screen | `⌃⇧⌘C` |
| Move to next screen → | `⌃⇧⌘→` |
| Move to previous screen ← | `⌃⇧⌘←` |
| Jump to screen 1 | `⌃⇧⌘1` |
| Jump to screen 2 | `⌃⇧⌘2` |
| Jump to screen 3 | `⌃⇧⌘3` |
| Jump to screens 4–6 | disabled by default |

## Customising shortcuts

Click the menu bar icon → **Settings…**

Each action has a toggle (enable/disable) and a **Record** button. Click Record, press any modifier + key combo, done. Settings save automatically.

## Building from source

Requires Swift (comes with Xcode or the Command Line Tools).

```bash
git clone https://github.com/YOUR_USERNAME/center-screen.git
cd center-screen

# Run directly
make run

# Build and install to ~/Applications
make install
```

## Why Accessibility permission?

`CGWarpMouseCursorPosition` moves the cursor without it, but posting the synthetic `mouseMoved` event (which updates hover states on the destination screen) requires Accessibility access. The app requests it once on first launch.
