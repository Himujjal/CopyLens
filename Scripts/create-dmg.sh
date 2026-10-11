#!/usr/bin/env bash
# Creates a distributable DMG for CopyLens.
# Requires: hdiutil (macOS built-in), swift build -c release

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="CopyLens"
BUNDLE_ID="com.copylens.app"
CONFIG="${CONFIG:-release}"
VERSION="${VERSION:-0.1.0}"

# Build the app bundle first
./Scripts/bundle.sh

APP_DIR="$ROOT/build/$CONFIG/$APP_NAME.app"
DMG_DIR="$ROOT/build/$CONFIG/dmg"
DMG_PATH="$ROOT/build/$CONFIG/$APP_NAME.dmg"

# Clean previous DMG artifacts
rm -rf "$DMG_DIR"
rm -f "$DMG_PATH"
mkdir -p "$DMG_DIR"

# Copy the app bundle to the DMG staging directory
cp -R "$APP_DIR" "$DMG_DIR/"

# Create a symlink to /Applications for easy install
ln -s /Applications "$DMG_DIR/Applications"

# Optional: add a background image for the DMG window (if you have one)
# cp "$ROOT/Assets/dmg-background.png" "$DMG_DIR/.background.png"

# Create the DMG
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_PATH"

# Clean up staging directory
rm -rf "$DMG_DIR"

echo "Created $DMG_PATH"
echo "Version: $VERSION"
echo ""
echo "To test: open \"$DMG_PATH\""