#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-v0.1.0}"
APP_NAME="Sub2APIStatusBar"
BUNDLE_ID="${BUNDLE_ID:-com.geekywizkid.sub2api-statusbar}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
DIST_DIR="$ROOT_DIR/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"
"$ROOT_DIR/scripts/generate-icon.swift" >/dev/null
swift build -c release --product "$APP_NAME"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp ".build/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"
cp -R "$ROOT_DIR/Resources/." "$RESOURCES_DIR/"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>Sub2API Status Bar</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION#v}</string>
  <key>CFBundleVersion</key>
  <string>${VERSION#v}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.productivity</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSSupportsAutomaticTermination</key>
  <true/>
  <key>NSSupportsSuddenTermination</key>
  <true/>
</dict>
</plist>
PLIST

if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$APP_DIR"
fi

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_DIR" >/dev/null
fi

echo "$APP_DIR"
