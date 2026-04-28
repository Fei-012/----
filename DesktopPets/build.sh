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
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
ICON_PNG="$ROOT_DIR/Icon.png"
ICON_ICNS="$RESOURCES_DIR/AppIcon.icns"

rm -rf "$APP_DIR"
rm -rf "$ICONSET_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$MODULE_CACHE_DIR"

cp "$PROJECT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/Sunny.GIF" "$RESOURCES_DIR/Sunny.GIF"
cp "$ROOT_DIR/Grace.gif" "$RESOURCES_DIR/Grace.gif"
cp "$ROOT_DIR/Gracie.gif" "$RESOURCES_DIR/Gracie.gif"
cp "$ROOT_DIR/Speaking Box.png" "$RESOURCES_DIR/Speaking Box.png"

mkdir -p "$ICONSET_DIR"
sips -z 16 16     "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32     "$ICON_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32     "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64     "$ICON_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256   "$ICON_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512   "$ICON_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$ICON_PNG" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$ICONSET_DIR" -o "$ICON_ICNS"

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
