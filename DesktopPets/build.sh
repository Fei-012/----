#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_DIR="$ROOT_DIR/DesktopPets"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/DesktopPets.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
MODULE_CACHE_DIR="$BUILD_DIR/swift-module-cache"
ARM64_BIN="$BUILD_DIR/DesktopPets-arm64"
X64_BIN="$BUILD_DIR/DesktopPets-x86_64"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$MODULE_CACHE_DIR"

cp "$PROJECT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/IMG_3090.GIF" "$RESOURCES_DIR/IMG_3090.GIF"
cp "$ROOT_DIR/UntitledArtwork1.GIF" "$RESOURCES_DIR/UntitledArtwork1.GIF"

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -target arm64-apple-macos13.0 \
  -o "$ARM64_BIN" \
  "$PROJECT_DIR/App.swift" \
  -framework AppKit

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -target x86_64-apple-macos13.0 \
  -o "$X64_BIN" \
  "$PROJECT_DIR/App.swift" \
  -framework AppKit

lipo -create -output "$MACOS_DIR/DesktopPets" "$ARM64_BIN" "$X64_BIN"

chmod +x "$ARM64_BIN" "$X64_BIN" "$MACOS_DIR/DesktopPets"

# Remove Finder metadata that breaks bundle signing after copying files around.
xattr -cr "$APP_DIR"

# Sign the full app bundle so Gatekeeper sees a coherent app package.
codesign --force --deep --sign - "$APP_DIR"

echo "Built $APP_DIR"
