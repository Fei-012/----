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

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$MODULE_CACHE_DIR"

cp "$PROJECT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/IMG_3090.GIF" "$RESOURCES_DIR/IMG_3090.GIF"
cp "$ROOT_DIR/UntitledArtwork1.GIF" "$RESOURCES_DIR/UntitledArtwork1.GIF"

swiftc \
  -module-cache-path "$MODULE_CACHE_DIR" \
  -o "$MACOS_DIR/DesktopPets" \
  "$PROJECT_DIR/App.swift" \
  -framework AppKit

chmod +x "$MACOS_DIR/DesktopPets"

echo "Built $APP_DIR"
