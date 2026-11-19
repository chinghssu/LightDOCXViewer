#!/bin/bash
# Compile the macOS app and generate its icon from AppIcon.png.
# Requires Xcode Command Line Tools (swiftc, sips, iconutil).
set -euo pipefail
cd "$(dirname "$0")"

APP="$PWD/Light DOCX Viewer.app"
ICONSET="$PWD/AppIcon.iconset"

# Rebuild the bundle and temporary iconset without stale assets.
rm -rf "$APP" "$ICONSET"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$ICONSET"

# Generate all standard macOS icon sizes. The @2x assets are retina variants.
for SIZE in 16 32 128 256 512; do
    /usr/bin/sips -s format png -z "$SIZE" "$SIZE" AppIcon.png \
        --out "$ICONSET/icon_${SIZE}x${SIZE}.png" >/dev/null
    DOUBLE=$((SIZE * 2))
    /usr/bin/sips -s format png -z "$DOUBLE" "$DOUBLE" AppIcon.png \
        --out "$ICONSET/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
done

# Package icon files into the .icns resource referenced by Info.plist.
/usr/bin/iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

# Compile the Swift application and package its metadata.
/usr/bin/xcrun swiftc -O -framework AppKit -framework Foundation \
    -o "$APP/Contents/MacOS/LightDOCXViewer" LightDOCXViewer.swift
cp Info.plist "$APP/Contents/Info.plist"

echo "Build succeeded: $APP"
open "$APP"
