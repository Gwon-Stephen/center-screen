#!/usr/bin/env bash
# Converts any PNG into a macOS .icns file and saves it to Resources/AppIcon.icns
# Usage: bash scripts/make_icon.sh path/to/image.png

set -euo pipefail

INPUT="${1:-}"
if [ -z "$INPUT" ]; then
    echo "Usage: bash scripts/make_icon.sh <input.png>"
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "Error: file not found: $INPUT"
    exit 1
fi

ICONSET=$(mktemp -d)/AppIcon.iconset
mkdir -p "$ICONSET"

echo "Resizing to all required sizes..."

# --setProperty format png tells sips to output PNG explicitly (avoids the
# "output file suffix should be tiff" warning that appears without it).
# iconutil expects this exact set of filenames.
sips -z 16   16   "$INPUT" -s format png --out "$ICONSET/icon_16x16.png"       > /dev/null
sips -z 32   32   "$INPUT" -s format png --out "$ICONSET/icon_16x16@2x.png"    > /dev/null
sips -z 32   32   "$INPUT" -s format png --out "$ICONSET/icon_32x32.png"       > /dev/null
sips -z 64   64   "$INPUT" -s format png --out "$ICONSET/icon_32x32@2x.png"    > /dev/null
sips -z 128  128  "$INPUT" -s format png --out "$ICONSET/icon_128x128.png"     > /dev/null
sips -z 256  256  "$INPUT" -s format png --out "$ICONSET/icon_128x128@2x.png"  > /dev/null
sips -z 256  256  "$INPUT" -s format png --out "$ICONSET/icon_256x256.png"     > /dev/null
sips -z 512  512  "$INPUT" -s format png --out "$ICONSET/icon_256x256@2x.png"  > /dev/null
sips -z 512  512  "$INPUT" -s format png --out "$ICONSET/icon_512x512.png"     > /dev/null
sips -z 1024 1024 "$INPUT" -s format png --out "$ICONSET/icon_512x512@2x.png"  > /dev/null

mkdir -p Resources
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns

echo "Done → Resources/AppIcon.icns"
